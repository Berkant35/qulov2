import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/audio_player_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/questions/widgets/question_voice_preview.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Tekil oynatıcı: önizleme kapanınca (kaldır, yeni kayıt, ekrandan çık)
/// YALNIZ kendi çaldığı ses durur; başka yerde çalan sese dokunulmaz.
class _FakePlayer implements AudioPlayerManager {
  _FakePlayer(this.currentUrl);

  @override
  String? currentUrl;
  int stopCalls = 0;

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Future<void> stop() async => stopCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakePlayer.${invocation.memberName}');
}

void main() {
  Widget app(_FakePlayer player, Widget? child) => ProviderScope(
        overrides: [audioPlayerManagerProvider.overrideWithValue(player)],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Scaffold(body: child ?? const SizedBox()),
        ),
      );

  /// Yerelleştirme yüklemesi asenkron: ilk karede ağaç boş, bir kare ilerlet.
  Future<void> show(WidgetTester tester, _FakePlayer player, Widget? child) async {
    await tester.pumpWidget(app(player, child));
    await tester.pump();
  }

  QuestionVoicePreview preview(String source) =>
      QuestionVoicePreview(source: source, durationSeconds: 5, onRemove: () {});

  testWidgets('kendi sesi çalarken kapanırsa oynatıcı durur', (tester) async {
    final player = _FakePlayer('file:///tmp/a.m4a');
    await show(tester, player, preview('file:///tmp/a.m4a'));

    await show(tester, player, null);

    expect(player.stopCalls, 1);
  });

  testWidgets('başka ses çalıyorsa kapanış ona dokunmaz', (tester) async {
    final player = _FakePlayer('https://chat.test/other.m4a');
    await show(tester, player, preview('file:///tmp/a.m4a'));

    await show(tester, player, null);

    expect(player.stopCalls, 0);
  });

  testWidgets('yeni kayıtla kaynak değişince eski ses durur', (tester) async {
    final player = _FakePlayer('file:///tmp/a.m4a');
    await show(tester, player, preview('file:///tmp/a.m4a'));

    await show(tester, player, preview('file:///tmp/b.m4a'));

    expect(player.stopCalls, 1);
  });
}
