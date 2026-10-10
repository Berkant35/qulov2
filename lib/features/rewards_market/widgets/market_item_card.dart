import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/market_labels.dart';
import 'package:qulo_v2/features/rewards_market/widgets/brand_logo.dart';

/// Katalog kartı: logo, marka, kupür + para birimi, Rainbow fiyatı.
///
/// Yatay listede sabit yükseklikte durur: kart metni en fazla [maxTextScale] büyür ve liste yüksekliği
/// ([extentOf]) aynı sıkıştırılmış ölçekle hesaplanır — büyük sistem yazısında içerik taşmaz.
class MarketItemCard extends StatelessWidget {
  const MarketItemCard({super.key, required this.item, required this.onTap});

  /// 1.0 metin ölçeğindeki kart yüksekliği.
  static const double baseExtent = 132;
  static const double width = 120;
  static const double maxTextScale = 1.3;

  /// Satır yüksekliği ≈ punto × 1.5 (cömert pay; yazı tipinden bağımsız).
  static const double _lineHeightFactor = 1.5;

  /// Liste yüksekliği: metin satırlarının (marka, kupür, fiyat) payı sıkıştırılmış ölçekle büyür.
  static double extentOf(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: maxTextScale);
    final textTheme = Theme.of(context).textTheme;
    var growth = 0.0;
    for (final style in [textTheme.labelMedium, textTheme.titleMedium, textTheme.labelLarge]) {
      final fontSize = style?.fontSize ?? 14;
      growth += (scaler.scale(fontSize) - fontSize) * _lineHeightFactor;
    }
    return baseExtent + growth;
  }

  final MarketItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.border.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandLogo(brandKey: item.brandKey, logoUrl: item.logoUrl, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                rewardBrandLabel(context, item.brandKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(color: colors.textSecondary),
              ),
              Text(
                context.fmt.money(item.faceValue, item.currency),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Row(
                children: [
                  const DiamondIcon.rainbow(size: 16, showGlow: false),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      '${item.rainbowPrice}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
