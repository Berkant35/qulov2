import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/onboarding/widgets/power_grid_item.dart';

class OnboardingPowersPage extends StatefulWidget {
  const OnboardingPowersPage({super.key});

  @override
  State<OnboardingPowersPage> createState() => _OnboardingPowersPageState();
}

class _OnboardingPowersPageState extends State<OnboardingPowersPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _powers = [
    (QIcons.icOracle, 'power_copy'),
    (QIcons.icSplit, 'power_half'),
    (QIcons.icSkipForward, 'power_skip'),
    (QIcons.icLightbulb, 'power_hint'),
    (QIcons.icClock, 'power_time'),
    (QIcons.icFastForward, 'power_skip_all'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.tr('onboarding_v2_page3_title'),
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.85,
            ),
            itemCount: _powers.length,
            itemBuilder: (context, index) {
              final power = _powers[index];
              return PowerGridItem(
                iconPath: power.$1,
                label: context.tr(power.$2),
                index: index,
                animation: _controller,
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.tr('onboarding_v2_page3_desc'),
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
