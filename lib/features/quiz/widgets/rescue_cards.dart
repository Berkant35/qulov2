import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/features/quiz/widgets/free_second_chance_card.dart';

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

/// Yanlış cevap sonrası kurtarma kartı: SKIP / SKIP_ALL / vazgeç. İlk quiz
/// ikinci şansında ücretli SKIP satırı yerine [FreeSecondChanceCard] çıkar —
/// eski veride ücretsiz SKIP'i kimse kullanmadı, büyük olasılıkla fark edilmedi.
class RescueCards extends StatelessWidget {
  final bool freeSecondChance;
  final RescuePowerOption? skipOption;
  final RescuePowerOption? skipAllOption;
  final void Function(String power)? onRescue;
  final VoidCallback? onDeclineRescue;

  const RescueCards({
    super.key,
    this.freeSecondChance = false,
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
          if (freeSecondChance)
            FreeSecondChanceCard(onTap: () async => onRescue?.call('SKIP'))
          else if (skipOption != null)
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(
          color: context.appColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: context.appColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          context.fmt.integer(option.inventoryCount),
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.appColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
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
