import 'dart:io';

import 'package:record/record.dart';

class AudioRecorderManager {
  AudioRecorderManager._();
  static final AudioRecorderManager instance = AudioRecorderManager._();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentFilePath;

  bool get isRecording => _isRecording;

  /// Checks and requests microphone permission.
  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  /// Starts recording to the given [filePath] in AAC format.
  Future<void> startRecording(String filePath) async {
    if (_isRecording) return;

    final permitted = await hasPermission();
    if (!permitted) {
      throw Exception('Microphone permission not granted');
    }

    _currentFilePath = filePath;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: filePath,
    );

    _isRecording = true;
  }

  /// Stops the current recording and returns the file path.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;
    _currentFilePath = null;
    return path;
  }

  /// Cancels the current recording and deletes the file.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _recorder.stop();
    _isRecording = false;

    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentFilePath = null;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
