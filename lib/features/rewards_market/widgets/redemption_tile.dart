import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/market_labels.dart';
import 'package:qulo_v2/features/rewards_market/widgets/brand_logo.dart';
import 'package:qulo_v2/features/rewards_market/widgets/redemption_delivery_box.dart';
import 'package:qulo_v2/features/rewards_market/widgets/redemption_status_chip.dart';

class RedemptionTile extends StatelessWidget {
  const RedemptionTile({super.key, required this.redemption, required this.onCopy, required this.onOpen});

  final Redemption redemption;
  final void Function(String code) onCopy;
  final void Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final r = redemption;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BrandLogo(brandKey: r.brandKey, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rewardBrandLabel(context, r.brandKey)} · ${context.fmt.money(r.faceValue, r.currency)}',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (r.createdAt != null)
                      Text(context.fmt.date(r.createdAt!), style: textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
              RedemptionStatusChip(status: r.status),
            ],
          ),
          if (r.status == RedemptionStatus.fulfilled && (r.deliveryCode != null || r.deliveryUrl != null)) ...[
            const SizedBox(height: AppSpacing.sm),
            RedemptionDeliveryBox(code: r.deliveryCode, url: r.deliveryUrl, onCopy: onCopy, onOpen: onOpen),
          ],
          if (r.status == RedemptionStatus.rejected) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(context.tr('redemption_rejected_note'), style: textTheme.bodySmall),
            if (r.rejectReason != null)
              Text(
                context.tr('redemption_reason').replaceAll('{reason}', r.rejectReason!),
                style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
          ],
        ],
      ),
    );
  }
}
