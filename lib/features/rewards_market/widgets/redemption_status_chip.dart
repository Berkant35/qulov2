import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';

/// Talep durumu rozeti (bekliyor / teslim edildi / reddedildi).
class RedemptionStatusChip extends StatelessWidget {
  const RedemptionStatusChip({super.key, required this.status});

  final RedemptionStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = switch (status) {
      RedemptionStatus.pending => colors.warning,
      RedemptionStatus.fulfilled => colors.success,
      RedemptionStatus.rejected => colors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        context.tr(redemptionStatusKey(status)),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
