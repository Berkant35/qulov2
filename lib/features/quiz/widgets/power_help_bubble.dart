import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/quiz/mixins/power_effect_labels_mixin.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_bubble_text.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_preview.dart';

/// "?" baloncuğu: gücün minyatür efekt döngüsü + tek cümle (+ Kâhin'de yüzde).
///
/// Modal değil: güç çubuğunun hemen üstünde akışın içinde durur; şıkları ve sayacı örtmez
/// (soru alanı kayar). Tek dokunuşla kapanır: kendisine ya da dışarıya dokunmak [onClose]'u
/// çağırır; dış dokunuş yutulmaz (şık seçimi aynı anda çalışır). "?" butonları [tapGroup]'ta.
class PowerHelpBubble extends StatelessWidget with PowerEffectLabelsMixin {
  const PowerHelpBubble({
    super.key,
    required this.type,
    required this.title,
    required this.oracleAccuracy,
    required this.timeExtendSeconds,
    required this.onClose,
  });

  /// Baloncuk + "?" butonlarının ortak dokunma grubu.
  static const Object tapGroup = #quizPowerHelp;

  static const double _borderAlpha = 0.5;

  final PowerType type;

  /// Gücün çubuktaki adı ("Yarıla").
  final String title;

  /// `EconomyConfig.oracleAccuracy`; yalnız Kâhin'de gösterilir.
  final double oracleAccuracy;

  /// `timing.timeExtendSeconds`; Ek Süre minyatüründeki "+N".
  final int timeExtendSeconds;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: tapGroup,
      onTapOutside: (_) => onClose(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: type.color.withValues(alpha: _borderAlpha)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                PowerHelpPreview(
                  type: type,
                  oraclePercent: oraclePercent(context, oracleAccuracy),
                  hintText: title,
                  timeExtendSeconds: timeExtendSeconds,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PowerHelpBubbleText(
                    title: title,
                    titleColor: type.color,
                    description: powerDescription(context, type),
                    accuracy: helpAccuracyLabel(context, type, oracleAccuracy),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
