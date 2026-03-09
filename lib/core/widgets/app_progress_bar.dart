import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class AppProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AppProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: LinearProgressIndicator(
          value: currentStep / totalSteps,
          minHeight: 4,
        ),
      ),
    );
  }
}
