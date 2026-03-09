import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';

class AnswerFeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  final String? correctAnswerText;
  final VoidCallback onComplete;
  final bool canRescue;
  final int skipInventoryCount;
  final int skipDiamondCost;
  final VoidCallback? onRescue;
  final VoidCallback? onDeclineRescue;

  const AnswerFeedbackOverlay({
    super.key,
    required this.isCorrect,
    this.correctAnswerText,
    required this.onComplete,
    this.canRescue = false,
    this.skipInventoryCount = 0,
    this.skipDiamondCost = 20,
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

    final duration =
        widget.isCorrect ? const Duration(milliseconds: 800) : const Duration(milliseconds: 1000);

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
      if (widget.isCorrect) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) widget.onComplete();
        });
      } else if (!widget.canRescue) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) widget.onComplete();
        });
      }
      // canRescue=true: don't auto-close, user will tap rescue or decline
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
                    if (!widget.isCorrect && widget.canRescue) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildRescueCard(theme),
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

  Widget _buildRescueCard(ThemeData theme) {
    final hasInventory = widget.skipInventoryCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PowerIcon(type: PowerType.skip, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Skip ile Kurtul!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bu soruyu geçerek devam edebilirsin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onRescue,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasInventory ? AppColors.success : AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                hasInventory
                    ? 'SKIP Kullan (×${widget.skipInventoryCount})'
                    : 'SKIP Satın Al — ${widget.skipDiamondCost} 💎',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: widget.onDeclineRescue,
            child: Text(
              'Vazgeç',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
