import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/reward_brands.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_error.dart';
import 'package:qulo_v2/features/rewards_market/market_labels.dart';
import 'package:qulo_v2/features/rewards_market/mixins/market_item_sheet_mixin.dart';
import 'package:qulo_v2/features/rewards_market/providers/market_provider.dart';
import 'package:qulo_v2/features/rewards_market/widgets/brand_logo.dart';
import 'package:qulo_v2/features/rewards_market/widgets/redeem_summary.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Ürün + itfa sayfası (spec §7.4).
class MarketItemSheet extends ConsumerStatefulWidget {
  const MarketItemSheet({super.key, required this.item, this.sourceItemId});

  final MarketItem item;
  final String? sourceItemId;

  static Future<void> show(WidgetRef ref, {required MarketItem item, String? sourceItemId}) =>
      ref.read(navigationServiceProvider).showAppBottomSheet(CustomBottomSheet(
            name: 'market_item',
            maxHeightFactor: AppBottomSheet.tallHeightFactor,
            builder: (_) => MarketItemSheet(item: item, sourceItemId: sourceItemId),
          ));

  @override
  ConsumerState<MarketItemSheet> createState() => _MarketItemSheetState();
}

class _MarketItemSheetState extends ConsumerState<MarketItemSheet> with MarketItemSheetMixin {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final MarketView? market = ref.watch(marketProvider).valueOrNull;
    final int fallbackBalance = ref.watch(userProvider.select((u) => u.valueOrNull?.rainbowDiamonds ?? 0));
    final int balance = market?.balance ?? fallbackBalance;
    final canAfford = balance >= item.rainbowPrice;
    final shownError = error ?? (canAfford ? null : const RedeemError(RedeemErrorKind.insufficient, code: 'LOCAL'));
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BrandLogo(brandKey: item.brandKey, logoUrl: item.logoUrl, size: 48),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rewardBrandLabel(context, item.brandKey), style: textTheme.titleMedium),
                      Text(
                        context.fmt.money(item.faceValue, item.currency),
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.tr(rewardHowtoKey(item.brandKey)), style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            RedeemSummary(
              price: item.rainbowPrice,
              balance: balance,
              monthlyCap: market?.monthlyCap,
              usedThisMonth: market?.usedThisMonth ?? 0,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr('market_sheet_delivery_note'),
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            if (shownError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(redeemErrorMessage(shownError, context.tr), style: textTheme.bodyMedium?.copyWith(color: colors.error)),
              if (shownError.kind == RedeemErrorKind.insufficient)
                Text(
                  context.tr('market_error_insufficient_hint'),
                  style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.tr('market_redeem_button'),
              isLoading: submitting,
              onPressed: canAfford && !submitting ? submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
