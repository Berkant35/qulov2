import 'dart:async' show unawaited;
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Singleton video manager — Hardware Manager Pattern.
///
/// Arka plan video oynatımı için controller lifecycle yönetimi sağlar.
/// Dispose öncesi pause ZORUNLU. Max 1 aktif video kuralı.
class VideoManager with WidgetsBindingObserver {
  VideoManager._();
  static final VideoManager instance = VideoManager._();

  /// Asset path → controller cache.
  final Map<String, VideoPlayerController> _controllers = {};

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

  /// Controller oluştur veya cache'den al.
  /// Otomatik: initialize + setLooping(true) + setVolume(0) + play.
  /// Max 1 aktif video — mevcut varsa önce release edilir.
  Future<VideoPlayerController> acquire(String assetPath) async {
    // Aynı asset zaten cache'de ise direkt dön
    if (_controllers.containsKey(assetPath)) {
      return _controllers[assetPath]!;
    }

    // Max 1 aktif video kuralı — mevcut controller varsa release et
    if (_controllers.isNotEmpty) {
      await releaseAll();
    }

    dev.log('[VideoManager] Acquiring: $assetPath', name: 'VideoManager');

    final controller = VideoPlayerController.asset(assetPath);
    _controllers[assetPath] = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
    } catch (e) {
      dev.log(
        '[VideoManager] Failed to initialize: $assetPath — $e',
        name: 'VideoManager',
      );
      _controllers.remove(assetPath);
      controller.dispose();
      rethrow;
    }

    dev.log('[VideoManager] Playing: $assetPath', name: 'VideoManager');
    return controller;
  }

  /// Pause → dispose → cache'den sil.
  Future<void> release(String assetPath) async {
    final controller = _controllers.remove(assetPath);
    if (controller == null) return;

    _wasPlaying.remove(assetPath);

    dev.log('[VideoManager] Releasing: $assetPath', name: 'VideoManager');

    // Dispose öncesi pause ZORUNLU
    if (controller.value.isPlaying) {
      await controller.pause();
    }
    await controller.dispose();
  }

  /// Tüm controller'ları release et.
  Future<void> releaseAll() async {
    final paths = List<String>.from(_controllers.keys);
    for (final path in paths) {
      await release(path);
    }
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
    for (final entry in _controllers.entries) {
      if (entry.value.value.isPlaying) {
        _wasPlaying.add(entry.key);
        await entry.value.pause();
      }
    }
    if (_wasPlaying.isNotEmpty) {
      dev.log(
        '[VideoManager] Paused ${_wasPlaying.length} video(s)',
        name: 'VideoManager',
      );
    }
  }

  Future<void> _resumeAll() async {
    for (final path in _wasPlaying) {
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
