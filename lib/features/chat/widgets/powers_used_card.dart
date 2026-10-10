import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/chat/mixins/powers_used_card_mixin.dart';

/// Sonuç ekranında bu soruda kullanılan güçler (güç başına tek çip, tekrar sayısıyla).
class PowersUsedCard extends StatelessWidget with PowersUsedCardWidgetMixin {
  final List<String> powers;
  const PowersUsedCard({super.key, required this.powers});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('result_powers_used'),
            style: textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final entry in countByPower(powers).entries)
                if (PowerType.fromApiName(entry.key) case final type?)
                  Chip(
                    avatar: PowerIcon(type: type, size: 16),
                    label: Text(
                      powerChipLabel(context, entry.key, entry.value),
                      style: textTheme.bodySmall?.copyWith(color: type.color),
                    ),
                    backgroundColor: type.color.withValues(alpha: 0.1),
                    side: BorderSide(color: type.color.withValues(alpha: 0.3)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
