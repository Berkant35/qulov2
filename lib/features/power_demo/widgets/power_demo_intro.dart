import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_power_bar.dart';

/// Demonun girişi: 6 güç ikonu, "gerçek quiz'in provası" + Başla.
class PowerDemoIntro extends StatelessWidget {
  const PowerDemoIntro({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.lg,
                      children: [
                        for (final power in PowerDemoPowerBar.order)
                          PowerIcon(type: power.type, size: AppSpacing.xxl),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      context.tr('power_demo_intro_title'),
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.tr('power_demo_intro_body'),
                      style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: context.tr('power_demo_start'), onPressed: onStart),
        ],
      ),
    );
  }
}
