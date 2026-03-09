import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class AnswerFeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  final String? correctAnswerText;
  final VoidCallback onComplete;

  const AnswerFeedbackOverlay({
    super.key,
    required this.isCorrect,
    this.correctAnswerText,
    required this.onComplete,
  });

  @override
  State<AnswerFeedbackOverlay> createState() => _AnswerFeedbackOverlayState();
}

class _AnswerFeedbackOverlayState extends State<AnswerFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    final duration =
        widget.isCorrect ? const Duration(milliseconds: 800) : const Duration(milliseconds: 1500);

    _controller = AnimationController(vsync: this, duration: duration);

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      final delay =
          widget.isCorrect ? const Duration(milliseconds: 200) : const Duration(milliseconds: 800);
      Future.delayed(delay, () {
        if (mounted) widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isCorrect ? AppColors.success : AppColors.error;
    final icon = widget.isCorrect ? Icons.check_rounded : Icons.close_rounded;
    final label = widget.isCorrect ? 'Correct!' : 'Wrong!';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!widget.isCorrect && widget.correctAnswerText != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.correctAnswerText!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
