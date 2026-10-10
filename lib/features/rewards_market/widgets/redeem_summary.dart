import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';

/// İtfa özeti: fiyat, işlem sonrası bakiye, bu ay kullanım (spec §7.4).
class RedeemSummary extends StatelessWidget {
  const RedeemSummary({
    super.key,
    required this.price,
    required this.balance,
    required this.monthlyCap,
    required this.usedThisMonth,
  });

  final int price;
  final int balance;
  final int? monthlyCap;
  final int usedThisMonth;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final after = balance - price;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          SummaryRow(label: context.tr('market_sheet_price'), value: price),
          const SizedBox(height: AppSpacing.xs),
          SummaryRow(
            label: context.tr('market_sheet_balance_after'),
            value: after,
            valueColor: after < 0 ? colors.error : null,
          ),
          if (monthlyCap != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context
                    .tr('market_sheet_monthly_usage')
                    .replaceAll('{used}', '$usedThisMonth')
                    .replaceAll('{cap}', '$monthlyCap'),
                style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final int value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        const DiamondIcon.rainbow(size: 16, showGlow: false),
        const SizedBox(width: AppSpacing.xs),
        Text('$value', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}
