import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/audio_recorder_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/chat/widgets/voice_recorder_overlay.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Ses kaydi overlay'i kayit surerken kapanirsa (sohbetten geri cikis, bildirime
/// dokunma) mikrofon birakilmali. Eskiden tekil kaydedici "kayitta" kaliyordu:
/// sonraki kayit hic baslamiyor, gonderilen ses ESKI (uzun) dosya oluyordu.
class _FakeRecorder implements AudioRecorderManager {
  Completer<void>? startGate;
  bool _recording = false;
  int cancelCalls = 0;
  int stopCalls = 0;

  @override
  bool get isRecording => _recording;

  @override
  Future<String> getRecordingPath() async => '/tmp/voice_test.m4a';

  @override
  Future<void> startRecording(String filePath) async {
    if (_recording) return;
    await startGate?.future;
    _recording = true;
  }

  @override
  Future<String?> stopRecording() async {
    stopCalls++;
    if (!_recording) return null;
    _recording = false;
    return '/tmp/voice_test.m4a';
  }

  @override
  Future<void> cancelRecording() async {
    cancelCalls++;
    _recording = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeRecorder.${invocation.memberName}');
}

class _Harness {
  _Harness({this.maxDurationSeconds});

  /// null = sohbet cagrisi (parametre verilmez, varsayilan 60 sn).
  final int? maxDurationSeconds;
  final recorder = _FakeRecorder();
  final completed = <String>[];
  final completedSeconds = <int>[];
  late final container = ProviderContainer(overrides: [
    audioRecorderManagerProvider.overrideWithValue(recorder),
  ]);

  Widget app({required bool showOverlay}) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showOverlay && maxDurationSeconds == null)
                  VoiceRecorderOverlay(
                    onRecordComplete: _onComplete,
                    onCancel: () {},
                  )
                else if (showOverlay)
                  VoiceRecorderOverlay(
                    maxDurationSeconds: maxDurationSeconds!,
                    onRecordComplete: _onComplete,
                    onCancel: () {},
                  ),
              ],
            ),
          ),
        ),
      );

  void _onComplete(String path, int seconds) {
    completed.add(path);
    completedSeconds.add(seconds);
  }
}

Future<_Harness> _pump(
  WidgetTester tester, {
  Completer<void>? startGate,
  int? maxDurationSeconds,
}) async {
  final h = _Harness(maxDurationSeconds: maxDurationSeconds)..recorder.startGate = startGate;
  addTearDown(h.container.dispose);
  await tester.pumpWidget(h.app(showOverlay: true));
  await tester.pump();
  return h;
}

void main() {
  testWidgets('kayit surerken overlay kapanirsa mikrofon birakilir', (tester) async {
    final h = await _pump(tester);
    expect(h.recorder.isRecording, isTrue);

    await tester.pumpWidget(h.app(showOverlay: false));

    expect(h.recorder.isRecording, isFalse);
    expect(h.recorder.cancelCalls, 1);
  });

  testWidgets('baslatma surerken kapanirsa kayit baslar baslamaz iptal edilir', (tester) async {
    final gate = Completer<void>();
    final h = await _pump(tester, startGate: gate);

    await tester.pumpWidget(h.app(showOverlay: false));
    gate.complete();
    await tester.pump();

    expect(h.recorder.isRecording, isFalse);
  });

  testWidgets('baslatma surerken cop kutusuna basilirsa kayit ve sayac baslamaz (overlay hala acik)',
      (tester) async {
    final gate = Completer<void>();
    final h = await _pump(tester, startGate: gate);

    // Harness'in onCancel'i overlay'i kaldirmiyor: State hala mounted.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    gate.complete();
    await tester.pump(const Duration(seconds: 2));

    expect(h.recorder.isRecording, isFalse);
    expect(find.text('0:00'), findsOneWidget, reason: 'sayac baslamadi');

    await tester.pumpWidget(h.app(showOverlay: false));
  });

  testWidgets('gonder: dosya teslim edilir, sonraki kapanis gonderilen kaydi iptal etmez', (tester) async {
    final h = await _pump(tester);

    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pumpWidget(h.app(showOverlay: false));

    expect(h.completed, ['/tmp/voice_test.m4a']);
    expect(h.recorder.stopCalls, 1);
    expect(h.recorder.cancelCalls, 0, reason: 'iptal dosyayi siler — gonderilen ses kaybolurdu');
  });

  testWidgets('sohbet (varsayilan): 59. sn kayitta, 60. sn otomatik tamamlanir', (tester) async {
    final h = await _pump(tester);

    await tester.pump(const Duration(seconds: 59));
    expect(h.completed, isEmpty, reason: 'sohbet sesi 60 sn sinirinda kalmali');
    expect(h.recorder.isRecording, isTrue);

    await tester.pump(const Duration(seconds: 1));
    expect(h.completedSeconds, [60]);
    expect(h.recorder.isRecording, isFalse);

    await tester.pumpWidget(h.app(showOverlay: false));
  });

  testWidgets('soru sesi (maxDurationSeconds: 15): 15. sn completeRecording', (tester) async {
    final h = await _pump(tester, maxDurationSeconds: 15);

    await tester.pump(const Duration(seconds: 14));
    expect(h.completed, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(h.completed, ['/tmp/voice_test.m4a']);
    expect(h.completedSeconds, [15]);
    expect(h.recorder.stopCalls, 1);

    await tester.pumpWidget(h.app(showOverlay: false));
    expect(h.recorder.cancelCalls, 0, reason: 'tamamlanan kayit iptal edilmez');
  });
}
