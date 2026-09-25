import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Gercek AVFoundation eklentisini taklit eder: dispose edilmis bir oyuncu
/// id'siyle gorunum kurulursa `StateError` atar (Crashlytics'teki
/// "No active player with ID 1" tam olarak bu yol).
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _streams = {};
  final List<int> disposed = [];

  /// false ise `initialized` olayi `emitInitialized` ile elle verilir.
  bool autoInitialize = true;
  int _nextId = 0;

  /// video_player, platformu ilk kullanimda statik alana alir ve bir daha
  /// okumaz — dosya basina TEK fake kurulur, testler arasinda bu sifirlanir.
  void reset() {
    _streams.clear();
    disposed.clear();
    autoInitialize = true;
    _nextId = 0;
  }

  void emitInitialized(int playerId) {
    _streams[playerId]!.add(VideoEvent(
      eventType: VideoEventType.initialized,
      size: const Size(16, 9),
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _nextId++;
    _streams[id] = StreamController<VideoEvent>();
    if (autoInitialize) emitInitialized(id);
    return id;
  }

  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
    await _streams.remove(playerId)?.close();
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _streams[playerId]!.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Widget buildView(int playerId) {
    if (disposed.contains(playerId)) {
      throw StateError('No active player with ID $playerId.');
    }
    return const SizedBox.expand();
  }
}
