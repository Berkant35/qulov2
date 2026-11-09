import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/audio_recorder_manager.dart';
import 'package:qulo_v2/features/chat/widgets/voice_recorder_overlay.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Sesli mesaj kaydinin yasam dongusu: baslat, sayac, gonder/iptal ve overlay
/// kapaninca mikrofonu birakma.
mixin VoiceRecorderOverlayMixin on ConsumerState<VoiceRecorderOverlay> {
  static const int maxDurationSeconds = 60;

  /// Yukari kaydirma bu esigi gecince birakinca kayit iptal edilir.
  static const double _cancelDragDelta = -5;

  late final AudioRecorderManager _recorder;
  Timer? _timer;
  int seconds = 0;
  bool hasStarted = false;
  bool isCancelling = false;

  /// Kayit kullanici eylemiyle (gonder / iptal) kapaniyor — dispose ayrica
  /// iptal etmez (gonderilen dosya silinmesin).
  bool _finishing = false;

  void initRecorder() {
    _recorder = ref.read(audioRecorderManagerProvider);
    _startRecording();
  }

  void disposeRecorder() {
    _timer?.cancel();
    // Kayit surerken overlay kapanirsa (sohbetten geri cikis, bildirime dokunma)
    // mikrofon acik kaliyordu: tekil kaydedici "kayitta" kaldigi icin sonraki
    // kayit hic baslamiyor, gonderilen ses ESKI (uzun) dosya oluyordu.
    if (!_finishing) unawaited(_recorder.cancelRecording());
  }

  String get elapsedLabel {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    try {
      final path = await _recorder.getRecordingPath();
      // Kapandi ya da cop kutusuna basildi: hic baslatma.
      if (!mounted || _finishing) return;
      await _recorder.startRecording(path);
      if (!mounted || _finishing) {
        // Baslatma surerken kapandi / iptal edildi: o anki iptal kayit baslamadan
        // kostu (no-op) — simdi kapat, sayac baslamasin.
        await _recorder.cancelRecording();
        return;
      }

      setState(() => hasStarted = true);

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (e) {
      if (mounted) widget.onCancel();
    }
  }

  void _tick() {
    if (!mounted) {
      _timer?.cancel();
      return;
    }
    setState(() => seconds++);
    if (seconds >= maxDurationSeconds) completeRecording();
  }

  Future<void> completeRecording() async {
    _finishing = true;
    _timer?.cancel();

    final path = await _recorder.stopRecording();
    if (path != null && mounted) {
      widget.onRecordComplete(path, seconds);
    }
  }

  Future<void> cancelRecording() async {
    _finishing = true;
    _timer?.cancel();
    await _recorder.cancelRecording();

    if (mounted) widget.onCancel();
  }

  void onDragUpdate(DragUpdateDetails details) {
    setState(() => isCancelling = details.delta.dy < _cancelDragDelta);
  }

  void onDragEnd(DragEndDetails _) {
    if (isCancelling) cancelRecording();
  }
}
