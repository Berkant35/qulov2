import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/quiz_audio_player.dart';
import 'package:qulo_v2/features/quiz/models/quiz_media_image_status.dart';
import 'package:qulo_v2/features/quiz/models/quiz_voice_status.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_question_media.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Soru sesi + görselinin yaşam döngüsü ve "hazır" sinyali.
///
/// - Ses kart açılınca BİR KEZ kendiliğinden çalar (iOS sessiz moda uyar); oynatıcı satırındaki
///   düğme çalarken duraklatır, duraklatılmışken sürdürür, bitince baştan çalar. Her dokunuş
///   kullanıcı isteğidir (iOS sessiz modda da duyulur). Duraklatma "hazır" sayılmaz.
/// - [QuizQuestionMedia.onReady] ses bitince / görsel yüklenince — ikisi varsa ikisi de hazır
///   olunca — tek kez çağrılır. Yükleme hatası da "hazır"dır: sayaç boşuna tutulmaz.
/// - Oynatıcı karta özeldir: kart kapanınca (soru değişti / ekrandan çıkıldı) durur ve
///   bırakılır; uygulama arka plana geçince susar (video-player-guard yaşam döngüsü).
mixin QuizQuestionMediaMixin on ConsumerState<QuizQuestionMedia> {
  QuizAudioPlayer? _player;
  StreamSubscription<void>? _completedSub;
  StreamSubscription<bool>? _playingSub;
  AppLifecycleListener? _lifecycle;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  bool _voiceReady = true;
  bool _imageReady = true;
  bool _readySent = false;
  bool _voiceCompleted = false;
  bool _ended = false;
  bool _voiceLoadFailed = false;
  int _replays = 0;

  /// Oynatıcı satırının durumu.
  final voiceStatus = ValueNotifier(QuizVoiceStatus.loading);

  /// Çalma konumu (ilerleme çizgisi); ses yoksa boş akış.
  Stream<Duration> voicePosition = const Stream.empty();

  /// Soru görseli (görsel yoksa null).
  ImageProvider? imageProvider;
  QuizMediaImageStatus imageStatus = QuizMediaImageStatus.loading;

  /// Ses süresi (kalan süre etiketi); bilinmiyorsa null.
  Duration? get voiceTotal {
    final ms = widget.voiceDurationMs;
    return ms == null || ms <= 0 ? null : Duration(milliseconds: ms);
  }

  void initMedia() {
    final voiceUrl = widget.voiceUrl;
    if (voiceUrl != null) _initVoice(voiceUrl);
    final imageUrl = widget.imageUrl;
    if (imageUrl != null) _initImage(imageUrl);
    _notifyIfReady();
  }

  /// Düğme: çalıyorsa duraklat, duraklatılmışsa sürdür, bittiyse baştan çal.
  void toggleVoice() {
    switch (voiceStatus.value) {
      case QuizVoiceStatus.playing:
        unawaited(_player?.pause());
      case QuizVoiceStatus.paused:
        unawaited(_player?.resume());
      case QuizVoiceStatus.completed:
        _replayVoice();
      case QuizVoiceStatus.loading || QuizVoiceStatus.failed:
        break;
    }
  }

  void _replayVoice() {
    final url = widget.voiceUrl;
    if (url == null) return;
    _replays++;
    _ended = false;
    // just_audio bitişte `playing`'i true bırakır: yeni olay gelmeyebilir, durumu hemen güncelle.
    voiceStatus.value = QuizVoiceStatus.playing;
    // Kullanıcı dokundu: iOS sessiz modda da duyulmalı (kendiliğinden çalma sessize uyar).
    unawaited(_play(url, userInitiated: true));
  }

  void disposeMedia() {
    _logVoicePlayed();
    _lifecycle?.dispose();
    unawaited(_completedSub?.cancel());
    unawaited(_playingSub?.cancel());
    voiceStatus.dispose();
    final listener = _imageListener;
    if (listener != null) _imageStream?.removeListener(listener);
    // Durdurma + bırakma + oturum geri yükleme tek yerde (`QuizAudioPlayer.dispose`).
    final player = _player;
    if (player != null) unawaited(player.dispose());
  }

  void _initVoice(String url) {
    _voiceReady = false;
    final player = ref.read(quizAudioPlayerFactoryProvider)();
    _player = player;
    voicePosition = player.positionStream;
    _playingSub = player.playingStream.listen((playing) {
      if (_ended) return;
      voiceStatus.value = playing ? QuizVoiceStatus.playing : QuizVoiceStatus.paused;
    });
    _completedSub = player.completedStream.listen((_) {
      _voiceCompleted = true;
      _ended = true;
      voiceStatus.value = QuizVoiceStatus.completed;
      _markVoiceReady();
    });
    _lifecycle = AppLifecycleListener(onHide: () => unawaited(player.stop()));
    unawaited(_play(url));
  }

  void _initImage(String url) {
    _imageReady = false;
    final provider = ref.read(quizMediaImageProviderFactoryProvider)(url);
    imageProvider = provider;
    final listener = ImageStreamListener(
      (_, _) => _onImageSettled(QuizMediaImageStatus.loaded),
      onError: (_, _) => _onImageSettled(QuizMediaImageStatus.failed),
    );
    _imageListener = listener;
    _imageStream = provider.resolve(ImageConfiguration.empty)..addListener(listener);
  }

  Future<void> _play(String url, {bool userInitiated = false}) async {
    try {
      await _player?.playFromStart(url, userInitiated: userInitiated);
    } catch (_) {
      // Yüklenemeyen ses beklenmez: soru metinle çözülür.
      if (mounted) voiceStatus.value = QuizVoiceStatus.failed;
      if (!_voiceLoadFailed) {
        _voiceLoadFailed = true;
        _logLoadFailed(AnalyticsEvents.mediaTypeVoice);
      }
      _markVoiceReady();
    }
  }

  void _markVoiceReady() {
    if (_voiceReady) return;
    _voiceReady = true;
    _notifyIfReady();
  }

  void _onImageSettled(QuizMediaImageStatus status) {
    if (!mounted) return;
    if (status == QuizMediaImageStatus.failed) _logLoadFailed(AnalyticsEvents.mediaTypeImage);
    setState(() => imageStatus = status);
    if (_imageReady) return;
    _imageReady = true;
    _notifyIfReady();
  }

  void _notifyIfReady() {
    if (_readySent || !_voiceReady || !_imageReady || !mounted) return;
    _readySent = true;
    widget.onReady();
  }

  /// Kart kapanırken BİR kez, son değerlerle (yüklenemeyen ses "oynatıldı" sayılmaz).
  void _logVoicePlayed() {
    if (_player == null || _voiceLoadFailed) return;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizVoicePlayed,
      params: {
        AnalyticsEvents.paramCompleted: _voiceCompleted,
        AnalyticsEvents.paramReplays: _replays,
      },
    );
  }

  void _logLoadFailed(String type) => AnalyticsManager.instance.logEvent(
        AnalyticsEvents.quizMediaLoadFailed,
        params: {AnalyticsEvents.paramType: type},
      );
}
