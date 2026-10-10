import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/quiz/widgets/rescue_cards.dart';

class AnswerFeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  final String? correctAnswerText;
  final VoidCallback onComplete;
  final bool canRescue;

  /// İlk quiz ikinci şansı: SKIP kurtarması bu sefer bedava (sunucu
  /// `free_second_chance`). Ücretli SKIP satırının yerine belirgin kart çıkar.
  final bool freeSecondChance;
  final RescuePowerOption? skipOption;
  final RescuePowerOption? skipAllOption;
  final void Function(String power)? onRescue;
  final VoidCallback? onDeclineRescue;

  const AnswerFeedbackOverlay({
    super.key,
    required this.isCorrect,
    this.correctAnswerText,
    required this.onComplete,
    this.canRescue = false,
    this.freeSecondChance = false,
    this.skipOption,
    this.skipAllOption,
    this.onRescue,
    this.onDeclineRescue,
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

    final duration = widget.isCorrect
        ? const Duration(milliseconds: 800)
        : const Duration(milliseconds: 1000);

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
      if (!mounted) return;
      if (widget.isCorrect) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) widget.onComplete();
        });
      } else if (!widget.canRescue) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) widget.onComplete();
        });
      }
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
    final color = widget.isCorrect ? context.appColors.success : context.appColors.error;
    final icon = widget.isCorrect ? Icons.check_rounded : Icons.close_rounded;
    final label = widget.isCorrect
        ? context.tr('quiz_correct')
        : context.tr('quiz_wrong');

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            color: AppColors.scrimBase.withValues(alpha: 0.54),
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
                      child: Icon(icon, color: AppColors.inkOnDark, size: 52),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.onScrim,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!widget.isCorrect && widget.canRescue) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      RescueCards(
                        freeSecondChance: widget.freeSecondChance,
                        skipOption: widget.skipOption,
                        skipAllOption: widget.skipAllOption,
                        onRescue: widget.onRescue,
                        onDeclineRescue: widget.onDeclineRescue,
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
