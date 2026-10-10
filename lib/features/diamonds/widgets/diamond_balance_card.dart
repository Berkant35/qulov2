import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/diamond_balance_section.dart';

class DiamondBalanceCard extends StatelessWidget {
  final int greenCount;
  final int purpleCount;

  /// null = Rainbow gösterilmez. Çağıran `UserModel.rainbowEnabled`'a göre verir
  /// (market dışı kullanıcıda Rainbow arka planda birikir, görünmez).
  final int? rainbowCount;

  const DiamondBalanceCard({
    super.key,
    required this.greenCount,
    required this.purpleCount,
    this.rainbowCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rainbow = rainbowCount;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: DiamondBalanceSection(
              icon: const DiamondIcon.purple(size: 32, showGlow: true),
              count: purpleCount,
              label: context.tr('purple_diamonds'),
              color: context.appColors.primary,
            ),
          ),
          const DiamondBalanceDivider(),
          Expanded(
            child: DiamondBalanceSection(
              icon: const DiamondIcon.green(size: 32, showGlow: true),
              count: greenCount,
              label: context.tr('green_diamonds'),
              color: context.appColors.secondary,
            ),
          ),
          if (rainbow != null) ...[
            const DiamondBalanceDivider(),
            Expanded(
              child: DiamondBalanceSection(
                icon: const DiamondIcon.rainbow(size: 32, showGlow: true),
                count: rainbow,
                label: context.tr('rainbow_diamonds'),
                color: context.appColors.rainbow,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
