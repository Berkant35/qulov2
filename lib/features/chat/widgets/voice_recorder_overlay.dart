import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/audio_recorder_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class VoiceRecorderOverlay extends ConsumerStatefulWidget {
  final void Function(String filePath, int durationSeconds) onRecordComplete;
  final VoidCallback onCancel;

  const VoiceRecorderOverlay({
    super.key,
    required this.onRecordComplete,
    required this.onCancel,
  });

  @override
  ConsumerState<VoiceRecorderOverlay> createState() => _VoiceRecorderOverlayState();
}

class _VoiceRecorderOverlayState extends ConsumerState<VoiceRecorderOverlay>
    with SingleTickerProviderStateMixin {
  static const int _maxDurationSeconds = 60;

  late final AudioRecorderManager _recorder;

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
    _recorder = ref.read(audioRecorderManagerProvider);

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
      _filePath = await _recorder.getRecordingPath();

      await _recorder.startRecording(_filePath!);

      if (!mounted) return;

      setState(() => _hasStarted = true);

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          _timer?.cancel();
          return;
        }

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
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),

              const Spacer(),

              // Cancel button
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Send button
              Container(
                decoration: BoxDecoration(
                  gradient: context.appColors.primaryButtonGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _hasStarted ? _completeRecording : null,
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
