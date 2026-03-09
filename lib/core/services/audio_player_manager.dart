import 'dart:async';
import 'package:just_audio/just_audio.dart';

class AudioPlayerManager {
  AudioPlayerManager._();
  static final AudioPlayerManager instance = AudioPlayerManager._();

  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;

  /// URL of the audio currently loaded / playing.
  String? get currentUrl => _currentUrl;

  /// Whether the player is actively playing right now.
  bool get isPlaying => _player.playing;

  /// Stream of the current playback position.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of the total duration (null until loaded).
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream of the player state (playing, paused, completed, etc.).
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Play an audio file from [url]. If a different audio is already playing,
  /// it is stopped first so only one audio plays at a time.
  Future<void> play(String url) async {
    if (_currentUrl == url && _player.playing) return;

    if (_currentUrl != url) {
      await _player.stop();
      await _player.setUrl(url);
      _currentUrl = url;
    }

    await _player.play();
  }

  /// Pause the current playback.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Stop playback and reset position.
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  /// Seek to a specific [position].
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Release the player resources.
  void dispose() {
    _player.dispose();
  }
}
