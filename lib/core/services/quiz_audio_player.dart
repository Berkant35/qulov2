import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Quiz kartındaki soru sesi (2.0.19). Sohbetin tekil `AudioPlayerManager`'ından BAĞIMSIZ,
/// soru başına ayrı `just_audio` örneği: kart kapanınca (soru değişti / ekrandan çıkıldı)
/// [dispose] ile durur ve bırakılır — sohbette çalan sese dokunmaz.
///
/// iOS ses oturumu [QuizAudioSessionGuard] ile: kendiliğinden çalma `ambient` (sessiz mod tuşu
/// açıksa iOS susturur); kullanıcının "Tekrar dinle" dokunuşu `playback` (sessiz modda da çalar —
/// açık bir istek). Android: oturuma dokunulmaz, ses yalnız çalar.
class QuizAudioPlayer {
  QuizAudioPlayer({AudioPlayer? player, QuizAudioSessionGuard? session})
      : _player = player ?? AudioPlayer(),
        _session = session ?? QuizAudioSessionGuard.shared;

  final AudioPlayer _player;
  final QuizAudioSessionGuard _session;
  String? _loadedUrl;
  bool _holdsSession = false;

  /// Çalıyor mu (tekrar dinle düğmesinin görünümü).
  Stream<bool> get playingStream => _player.playingStream;

  /// Çalma konumu (ilerleme çubuğu).
  Stream<Duration> get positionStream => _player.positionStream;

  /// Bir çalma sonuna geldi.
  Stream<void> get completedStream => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  /// [url]'yi baştan çalar. Yükleme hatası fırlatır (çağıran sesi "hazır" sayar).
  /// [userInitiated]: kullanıcı dokundu (tekrar dinle) → iOS'ta sessiz modda da duyulsun.
  Future<void> playFromStart(String url, {bool userInitiated = false}) async {
    if (!_holdsSession) {
      _holdsSession = true;
      await _session.acquire();
    }
    if (userInitiated) await _session.usePlayback();
    if (_loadedUrl != url) {
      await _player.setUrl(url);
      _loadedUrl = url;
    }
    await _player.seek(Duration.zero);
    // `play()` çalma bitene/durana dek tamamlanmaz; beklenmez. Çalma hatası "bitti" olayı
    // üretmez — sayaç tutması kendi süresinde biter.
    unawaited(_player.play().catchError((Object _) {}));
  }

  /// Çalmayı duraklatır (konum korunur). Hata fırlatmaz.
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {
      // Oynatıcı bozuksa zaten çalmıyor.
    }
  }

  /// Duraklatılan sesi kaldığı yerden sürdürür. Kullanıcı dokunuşudur: iOS'ta sessiz modda da
  /// duyulsun diye `playback` oturumu.
  Future<void> resume() async {
    await _session.usePlayback();
    unawaited(_player.play().catchError((Object _) {}));
  }

  /// Susturur (arka plana geçiş, kapanış). Hata fırlatmaz: kapanış yolunda yapılacak bir şey yok.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Oynatıcı zaten bozuksa susmuş sayılır.
    }
  }

  /// Durdur → bırak → (son oynatıcıysa) ses oturumunu geri yükle. Durdurma/bırakma hata verse
  /// de oturum MUTLAKA geri yüklenir (yoksa iOS oturum boyu `ambient` kalır, sohbet sesi
  /// sessiz modda susar). Hata fırlatmaz.
  Future<void> dispose() async {
    try {
      await stop();
      await _player.dispose();
    } catch (_) {
      // Bırakılamayan oynatıcı için yapılacak bir şey yok.
    } finally {
      if (_holdsSession) {
        _holdsSession = false;
        await _session.release();
      }
    }
  }
}

/// Quiz sesinin iOS oturum kategorisi: her tutucu (yeni soru kartı) `ambient` yapar — kendiliğinden
/// çalma sessiz mod tuşuna uyar; [usePlayback] (kullanıcının tekrar dinle dokunuşu) `playback`'e
/// geçirir. SON oynatıcı bırakılınca önceki yapılandırmaya (yoksa just_audio'nun varsayılanı
/// `music`) döner — sohbet sesli mesajları eskisi gibi çalar. Sayaçlıdır: soru geçişinde yeni kart
/// eskisi bırakılmadan kurulur. Hata fırlatmaz (oturum kurulamazsa ses yine çalar).
class QuizAudioSessionGuard {
  QuizAudioSessionGuard({
    required this.enabled,
    required Future<AudioSessionConfiguration?> Function() readConfiguration,
    required Future<void> Function(AudioSessionConfiguration) configure,
  })  : _readConfiguration = readConfiguration,
        _configure = configure;

  /// Gerçek platform: yalnız iOS'ta etkin.
  factory QuizAudioSessionGuard.platform() => QuizAudioSessionGuard(
        enabled: Platform.isIOS,
        readConfiguration: () async => (await AudioSession.instance).configuration,
        configure: (config) async => (await AudioSession.instance).configure(config),
      );

  static final shared = QuizAudioSessionGuard.platform();

  static const ambient = AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.ambient,
  );

  /// Kullanıcı isteğiyle çalma: sessiz mod tuşunu yok sayar.
  static const playback = AudioSessionConfiguration.music();

  /// Önceden yapılandırma yoksa just_audio'nun `setActive` varsayılanı.
  static const fallback = AudioSessionConfiguration.music();

  final bool enabled;
  final Future<AudioSessionConfiguration?> Function() _readConfiguration;
  final Future<void> Function(AudioSessionConfiguration) _configure;
  int _holders = 0;
  AudioSessionConfiguration? _restoreTo;

  /// Şu an uygulanmış quiz yapılandırması (aynısı yeniden kurulmaz); bırakılınca null.
  AudioSessionConfiguration? _applied;

  int get holders => _holders;

  /// Yeni kart: kendiliğinden çalma `ambient`. Önceki kart `playback`'e geçtiyse de geri alır.
  Future<void> acquire() async {
    if (!enabled) return;
    final first = _holders++ == 0;
    try {
      if (first) _restoreTo = await _readConfiguration();
      await _apply(ambient);
    } catch (_) {
      // Kategori kurulamadı: ses varsayılan kategoride çalar.
    }
  }

  /// Kullanıcının dokunuşu: oturum tutuluyken `playback`. Bırakılınca yine geri yüklenir.
  Future<void> usePlayback() async {
    if (!enabled || _holders == 0) return;
    try {
      await _apply(playback);
    } catch (_) {
      // Kurulamadı: ses mevcut kategoride çalar.
    }
  }

  Future<void> _apply(AudioSessionConfiguration config) async {
    if (identical(_applied, config)) return;
    await _configure(config);
    _applied = config;
  }

  Future<void> release() async {
    if (!enabled || _holders == 0) return;
    if (--_holders > 0) return;
    final restoreTo = _restoreTo ?? fallback;
    _restoreTo = null;
    _applied = null;
    try {
      await _configure(restoreTo);
    } catch (_) {
      // Geri yüklenemedi: kapanış yolunda yapılacak başka bir şey yok.
    }
  }
}
