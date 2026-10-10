import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/providers/rainbow_flag.dart';

/// Güç satın alma sayfasındaki bakiye satırı: yeşil, mor ve — yalnız sunucu açtıysa — Rainbow.
class PowerSheetBalanceRow extends ConsumerWidget {
  final DiamondBalance balance;

  const PowerSheetBalanceRow({super.key, required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rainbowEnabled = ref.watchRainbowEnabled();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const DiamondIcon.green(size: 20),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${balance.green}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: context.appColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        const DiamondIcon.purple(size: 20),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${balance.purple}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: context.appColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (rainbowEnabled) ...[
          const SizedBox(width: AppSpacing.xl),
          const DiamondIcon.rainbow(size: 20),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${balance.rainbow}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: context.appColors.rainbow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
