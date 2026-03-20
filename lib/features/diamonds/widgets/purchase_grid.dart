import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

enum DiamondTier {
  starter(amount: 50, price: '\$0.99', diamondCount: 1, productId: 'qulopurple50'),
  popular(amount: 150, price: '\$2.49', diamondCount: 2, productId: 'qulopurple150'),
  bestValue(amount: 400, price: '\$4.99', diamondCount: 3, productId: 'qulopurple400'),
  mega(amount: 1000, price: '\$9.99', diamondCount: 4, productId: 'qulopurple1000'),
  ultra(amount: 2500, price: '\$19.99', diamondCount: 5, productId: 'qulopurple2500'),
  vip(amount: 6000, price: '\$39.99', diamondCount: 6, productId: 'qulopurple6000');

  final int amount;
  final String price;
  final int diamondCount;
  final String productId;

  const DiamondTier({
    required this.amount,
    required this.price,
    required this.diamondCount,
    required this.productId,
  });
}

class PurchasePackage {
  final DiamondTier tier;

  const PurchasePackage({required this.tier});

  int get amount => tier.amount;
  String get price => tier.price;
}

class PurchaseGrid extends StatelessWidget {
  final ValueChanged<PurchasePackage>? onPurchase;
  final bool isLoading;

  const PurchaseGrid({super.key, this.onPurchase, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: DiamondTier.values.length,
      itemBuilder: (context, index) {
        final tier = DiamondTier.values[index];
        final isBestValue = tier == DiamondTier.bestValue;
        return IgnorePointer(
          ignoring: isLoading,
          child: Opacity(
            opacity: isLoading ? 0.5 : 1.0,
            child: _PackageCard(
              tier: tier,
              isBestValue: isBestValue,
              onTap: () => onPurchase?.call(PurchasePackage(tier: tier)),
            ),
          ),
        );
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  final DiamondTier tier;
  final bool isBestValue;
  final VoidCallback onTap;

  const _PackageCard({
    required this.tier,
    required this.isBestValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isBestValue
                ? AppColors.primary.withValues(alpha: 0.7)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isBestValue ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DiamondPile(tier: tier),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${tier.amount}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      tier.price,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isBestValue)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: context.appColors.purpleGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.radiusMd - 1),
                      topRight: Radius.circular(AppSpacing.radiusMd - 1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    context.tr('best_value'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Stacked diamond pile — diamonds increase per tier, glow stays consistent
class _DiamondPile extends StatelessWidget {
  final DiamondTier tier;

  const _DiamondPile({required this.tier});

  static const List<List<_DiamondOffset>> _pileLayouts = [
    // 1 diamond (starter)
    [_DiamondOffset(0, 0, 0)],
    // 2 diamonds (popular)
    [_DiamondOffset(-5, 2, -15), _DiamondOffset(5, -2, 12)],
    // 3 diamonds (bestValue)
    [
      _DiamondOffset(-7, 3, -20),
      _DiamondOffset(6, -1, 15),
      _DiamondOffset(0, -4, -5),
    ],
    // 4 diamonds (mega)
    [
      _DiamondOffset(-8, 4, -22),
      _DiamondOffset(7, 2, 18),
      _DiamondOffset(-2, -4, 8),
      _DiamondOffset(3, -2, -12),
    ],
    // 5 diamonds (ultra)
    [
      _DiamondOffset(-9, 5, -25),
      _DiamondOffset(8, 3, 20),
      _DiamondOffset(-3, -3, 10),
      _DiamondOffset(4, -5, -8),
      _DiamondOffset(0, 1, -18),
    ],
    // 6 diamonds (vip)
    [
      _DiamondOffset(-10, 5, -28),
      _DiamondOffset(9, 4, 22),
      _DiamondOffset(-4, -2, 12),
      _DiamondOffset(5, -4, -10),
      _DiamondOffset(-1, -6, 5),
      _DiamondOffset(2, 2, -15),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final layout = _pileLayouts[tier.index];
    const diamondSize = 22.0;

    return SizedBox(
      height: 48,
      width: 48,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Consistent purple glow behind pile
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Stacked diamonds with offsets and rotation
          ...layout.map(
            (offset) => Transform.translate(
              offset: Offset(offset.dx, offset.dy),
              child: Transform.rotate(
                angle: offset.rotation * math.pi / 180,
                child: const DiamondIcon.purple(
                  size: diamondSize,
                  showGlow: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiamondOffset {
  final double dx;
  final double dy;
  final double rotation;

  const _DiamondOffset(this.dx, this.dy, this.rotation);
}
