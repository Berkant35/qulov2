import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qulo_v2/core/services/audio_recorder_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class VoiceRecorderOverlay extends StatefulWidget {
  final void Function(String filePath, int durationSeconds) onRecordComplete;
  final VoidCallback onCancel;

  const VoiceRecorderOverlay({
    super.key,
    required this.onRecordComplete,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderOverlay> createState() => _VoiceRecorderOverlayState();
}

class _VoiceRecorderOverlayState extends State<VoiceRecorderOverlay>
    with SingleTickerProviderStateMixin {
  static const int _maxDurationSeconds = 60;

  final AudioRecorderManager _recorder = AudioRecorderManager.instance;

  Timer? _timer;
  int _seconds = 0;
  bool _hasStarted = false;
  bool _isCancelling = false;
  String? _filePath;

  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _filePath = '${dir.path}/voice_$timestamp.m4a';

      await _recorder.startRecording(_filePath!);

      if (!mounted) return;

      setState(() => _hasStarted = true);

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;

        setState(() => _seconds++);

        if (_seconds >= _maxDurationSeconds) {
          _completeRecording();
        }
      });
    } catch (e) {
      if (mounted) widget.onCancel();
    }
  }

  Future<void> _completeRecording() async {
    _timer?.cancel();

    final path = await _recorder.stopRecording();
    if (path != null && mounted) {
      widget.onRecordComplete(path, _seconds);
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _recorder.cancelRecording();

    if (mounted) widget.onCancel();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -5) {
          setState(() => _isCancelling = true);
        } else {
          setState(() => _isCancelling = false);
        }
      },
      onVerticalDragEnd: (details) {
        if (_isCancelling) {
          _cancelRecording();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: _isCancelling
              ? AppColors.error.withValues(alpha: 0.25)
              : AppColors.error.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Blinking red dot
              FadeTransition(
                opacity: _blinkAnimation,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Timer
              Text(
                _hasStarted ? _formatTime(_seconds) : '0:00',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),

              const Spacer(),

              // Cancel hint
              AnimatedOpacity(
                opacity: _isCancelling ? 1.0 : 0.7,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 16,
                      color: _isCancelling
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Kaydir: Iptal',
                      style: TextStyle(
                        color: _isCancelling
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
