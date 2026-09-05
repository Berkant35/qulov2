import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/exchange/mixins/convert_section_mixin.dart';

class ConvertSection extends ConsumerStatefulWidget {
  const ConvertSection({super.key});

  @override
  ConsumerState<ConvertSection> createState() => _ConvertSectionState();
}

class _ConvertSectionState extends ConsumerState<ConvertSection>
    with ConvertSectionMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = convertRatio;
    final maxValue = maxGreen;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('exchange_convert_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Diamond conversion visual
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Green side
              Column(
                children: [
                  const DiamondIcon.green(size: 40),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$greenAmount',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: context.appColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              // Purple side
              Column(
                children: [
                  const DiamondIcon.purple(size: 40),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$purpleResult',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: context.appColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.appColors.secondary,
              inactiveTrackColor: context.appColors.secondary.withValues(alpha: 0.2),
              thumbColor: context.appColors.secondary,
              overlayColor: context.appColors.secondary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: sliderValue.clamp(ratio.toDouble(), maxValue.toDouble()),
              min: ratio.toDouble(),
              max: maxValue.toDouble(),
              divisions: maxValue > ratio ? ((maxValue - ratio) ~/ ratio) : 1,
              onChanged: maxValue > ratio
                  ? (val) {
                      // Snap to multiples of ratio
                      final snapped = (val / ratio).round() * ratio;
                      setState(() => sliderValue = snapped.toDouble());
                    }
                  : null,
            ),
          ),

          // Ratio label
          Center(
            child: Text(
              '$ratio:1',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Convert button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: greenAmount >= ratio && !converting
                  ? onConvert
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.secondary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: converting
                  ? const AppLoadingWidget.small()
                  : Text(
                      context.tr('exchange_convert_button'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
