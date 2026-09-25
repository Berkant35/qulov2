import 'dart:async' show unawaited;
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Singleton video manager — Hardware Manager Pattern.
///
/// Arka plan video oynatımı için controller lifecycle yönetimi sağlar.
/// Controller'lar referans sayılır: aynı asset'i alan her widget `acquire`
/// eder, `release` ile bırakır; dispose yalnızca son bırakanda yapılır. Yeni
/// sayfa eskisi kapanmadan kurulduğunda (landing→login→geri→login) eskisinin
/// release'i yenisinin videosunu öldürmesin — Crashlytics "No active player
/// with ID". Dispose öncesi pause ZORUNLU. Max 1 aktif video kuralı.
class VideoManager with WidgetsBindingObserver {
  VideoManager._();
  static final VideoManager instance = VideoManager._();

  /// Asset path → controller cache.
  final Map<String, VideoPlayerController> _controllers = {};

  /// Init zinciri; init bitmeden aynı asset'i alan ikinci çağrı bunu bekler.
  final Map<String, Future<void>> _ready = {};

  final Map<String, int> _refCounts = {};

  /// App pause öncesi oynayan controller'lar (resume için).
  final Set<String> _wasPlaying = {};

  bool _initialized = false;

  /// App başlangıcında çağrılır (main.dart).
  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    dev.log('[VideoManager] Initialized', name: 'VideoManager');
  }

  /// Widget'ın tuttuğu controller hâlâ bu manager'da mı — değilse
  /// (max 1 kuralı başka asset için düşürdüyse) `VideoPlayer` kurulmamalı.
  bool isActive(String assetPath) => _controllers.containsKey(assetPath);

  /// Controller oluştur veya paylaş (referans sayacı +1).
  /// Otomatik: initialize + setLooping(true) + setVolume(0) + play.
  /// Max 1 aktif video — başka asset varsa önce release edilir.
  Future<VideoPlayerController> acquire(String assetPath) async {
    final cached = _controllers[assetPath];
    if (cached != null) {
      _refCounts[assetPath] = _refCounts[assetPath]! + 1;
      await _ready[assetPath];
      return cached;
    }

    if (_controllers.isNotEmpty) {
      await releaseAll();
    }

    dev.log('[VideoManager] Acquiring: $assetPath', name: 'VideoManager');

    final controller = VideoPlayerController.asset(assetPath);
    _controllers[assetPath] = controller;
    _refCounts[assetPath] = 1;
    final ready = _initialize(assetPath, controller);
    _ready[assetPath] = ready;
    await ready;
    return controller;
  }

  Future<void> _initialize(String assetPath, VideoPlayerController controller) async {
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      dev.log('[VideoManager] Playing: $assetPath', name: 'VideoManager');
    } catch (e) {
      dev.log(
        '[VideoManager] Failed to initialize: $assetPath — $e',
        name: 'VideoManager',
      );
      // Bu arada ayni asset yeniden alinmis olabilir; yalniz kendi kaydini sil.
      if (_controllers[assetPath] == controller) _forget(assetPath);
      unawaited(controller.dispose());
      rethrow;
    }
  }

  /// Referans sayacı -1; son bırakanda pause → dispose → cache'den sil.
  Future<void> release(String assetPath) async {
    final refs = _refCounts[assetPath];
    if (refs == null) return;
    if (refs > 1) {
      _refCounts[assetPath] = refs - 1;
      return;
    }
    await _dispose(assetPath);
  }

  /// Tüm controller'ları alıcı sayısına bakmadan release et.
  Future<void> releaseAll() async {
    for (final path in List<String>.from(_controllers.keys)) {
      await _dispose(path);
    }
  }

  Future<void> _dispose(String assetPath) async {
    final controller = _controllers[assetPath];
    if (controller == null) return;
    _forget(assetPath);

    dev.log('[VideoManager] Releasing: $assetPath', name: 'VideoManager');

    // Dispose öncesi pause ZORUNLU
    if (controller.value.isPlaying) {
      await controller.pause();
    }
    await controller.dispose();
  }

  void _forget(String assetPath) {
    _controllers.remove(assetPath);
    _ready.remove(assetPath);
    _refCounts.remove(assetPath);
    _wasPlaying.remove(assetPath);
  }

  /// Manuel pause.
  Future<void> pause(String assetPath) async {
    final controller = _controllers[assetPath];
    if (controller == null || !controller.value.isPlaying) return;
    await controller.pause();
  }

  /// Manuel resume.
  Future<void> resume(String assetPath) async {
    final controller = _controllers[assetPath];
    if (controller == null || controller.value.isPlaying) return;
    await controller.play();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        unawaited(_pauseAll());
      case AppLifecycleState.resumed:
        unawaited(_resumeAll());
      default:
        break;
    }
  }

  Future<void> _pauseAll() async {
    _wasPlaying.clear();
    for (final path in _controllers.keys.toList()) {
      final controller = _controllers[path];
      if (controller == null || !controller.value.isPlaying) continue;
      _wasPlaying.add(path);
      await controller.pause();
    }
    if (_wasPlaying.isNotEmpty) {
      dev.log(
        '[VideoManager] Paused ${_wasPlaying.length} video(s)',
        name: 'VideoManager',
      );
    }
  }

  Future<void> _resumeAll() async {
    for (final path in _wasPlaying.toList()) {
      await _controllers[path]?.play();
    }
    if (_wasPlaying.isNotEmpty) {
      dev.log(
        '[VideoManager] Resumed ${_wasPlaying.length} video(s)',
        name: 'VideoManager',
      );
    }
    _wasPlaying.clear();
  }
}
