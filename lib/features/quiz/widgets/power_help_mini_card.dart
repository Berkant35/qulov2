import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_mini_option.dart';

/// "?" minyatüründe soru kartı: soru satırı + iki şık. [stacked] arkasında ikinci bir kart
/// gösterir (Hepsini Geç: "kalan soruların hepsi").
class PowerHelpMiniCard extends StatelessWidget {
  const PowerHelpMiniCard({super.key, this.stacked = false});

  static const double _backOffset = AppSpacing.sm;

  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: context.appColors.textHint),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (stacked)
          PositionedDirectional(
            start: _backOffset,
            end: -_backOffset,
            top: -_backOffset,
            bottom: _backOffset,
            child: DecoratedBox(decoration: decoration),
          ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: decoration,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PowerHelpMiniOption(height: AppSpacing.md, filled: true),
              SizedBox(height: AppSpacing.sm),
              PowerHelpMiniOption(height: AppSpacing.lg),
              SizedBox(height: AppSpacing.sm),
              PowerHelpMiniOption(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }
}
