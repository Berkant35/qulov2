import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';

class PassportPremiumGate extends ConsumerWidget {
  const PassportPremiumGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(QIcons.lock, size: 64, color: context.appColors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('passport_premium_only'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('passport_premium_desc'),
              style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => PaywallBottomSheetContent.show(ref, trigger: 'passport_locked'),
                style: FilledButton.styleFrom(backgroundColor: context.appColors.primaryDark),
                child: Text(context.tr('upgrade_to_premium')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
