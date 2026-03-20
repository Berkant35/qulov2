import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';

class RescuePowerOption {
  final PowerType type;
  final int inventoryCount;
  final int diamondCost;

  const RescuePowerOption({
    required this.type,
    required this.inventoryCount,
    required this.diamondCost,
  });

  bool get hasInventory => inventoryCount > 0;
}

class AnswerFeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  final String? correctAnswerText;
  final VoidCallback onComplete;
  final bool canRescue;
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
                      _RescueCards(
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

class _RescueCards extends StatelessWidget {
  final RescuePowerOption? skipOption;
  final RescuePowerOption? skipAllOption;
  final void Function(String power)? onRescue;
  final VoidCallback? onDeclineRescue;

  const _RescueCards({
    this.skipOption,
    this.skipAllOption,
    this.onRescue,
    this.onDeclineRescue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('quiz_rescue_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (skipOption != null)
            _RescueOptionTile(
              option: skipOption!,
              label: context.tr('quiz_rescue_skip'),
              onTap: () async => onRescue?.call('SKIP'),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (skipAllOption != null)
            _RescueOptionTile(
              option: skipAllOption!,
              label: context.tr('quiz_rescue_skip_all'),
              onTap: () async => onRescue?.call('SKIP_ALL'),
            ),
          const SizedBox(height: AppSpacing.md),
          SafeTapButton(
            onTap: onDeclineRescue != null
                ? () async => onDeclineRescue!()
                : null,
            builder: (context, isLoading, safeTap) => TextButton(
              onPressed: safeTap,
              child: isLoading
                  ? AppLoadingWidget.small()
                  : Text(
                      context.tr('quiz_rescue_decline'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RescueOptionTile extends StatelessWidget {
  final RescuePowerOption option;
  final String label;
  final Future<void> Function() onTap;

  const _RescueOptionTile({
    required this.option,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = option.type.color;

    return SafeTapButton(
      onTap: onTap,
      builder: (context, isLoading, safeTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: safeTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
              color: color.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                QIcon(option.type.iconPath, size: 22, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                isLoading
                    ? AppLoadingWidget.small()
                    : _CostBadge(option: option),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CostBadge extends StatelessWidget {
  final RescuePowerOption option;

  const _CostBadge({required this.option});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (option.hasInventory) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.appColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: context.appColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '${option.inventoryCount}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.appColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.appColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DiamondIcon.purple(size: 12, showGlow: false),
          const SizedBox(width: 3),
          Text(
            '${option.diamondCost}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.appColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
