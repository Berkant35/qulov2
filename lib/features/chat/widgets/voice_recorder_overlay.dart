import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/chat/mixins/voice_recorder_overlay_mixin.dart';

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
    with SingleTickerProviderStateMixin, VoiceRecorderOverlayMixin {
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

    initRecorder();
  }

  @override
  void dispose() {
    disposeRecorder();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isCancelling
              ? context.appColors.error.withValues(alpha: 0.25)
              : context.appColors.error.withValues(alpha: 0.12),
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
                  decoration: BoxDecoration(
                    color: context.appColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Timer
              Text(
                elapsedLabel,
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
                onPressed: cancelRecording,
                icon: Icon(Icons.delete_outline, color: context.appColors.error, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Send button
              Container(
                decoration: BoxDecoration(
                  gradient: context.appColors.primaryButtonGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: hasStarted ? completeRecording : null,
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
