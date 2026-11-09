import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/half_strike_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/hint_reveal_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/oracle_highlight.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_slide_effect.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_mini_card.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_mini_option.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_mini_timer.dart';

/// "?" minyatürünün sahnesi (`PowerHelpPreview.canvas` boyutunda): her güç gerçek quiz'deki
/// ortak efektiyle. [shown] efektin son hâlde olup olmadığı; [round] Doğru Say / Ek Süre'de
/// her turu taze kartla başlatır (bu efektler yalnız jeton değişince oynar).
class PowerHelpScene extends StatelessWidget {
  const PowerHelpScene({
    super.key,
    required this.type,
    required this.shown,
    required this.round,
    required this.oraclePercent,
    required this.hintText,
    required this.timeExtendSeconds,
  });

  /// Yarıla minyatürü: 4 şık, ikisi elenir.
  static const _halfOptionCount = 4;
  static const _halfRemoved = {1, 3};

  final PowerType type;
  final bool shown;
  final int round;
  final String oraclePercent;
  final String hintText;
  final int timeExtendSeconds;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      PowerType.oracle => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PowerHelpMiniOption(height: AppSpacing.xl),
            const SizedBox(height: AppSpacing.md),
            OracleHighlight(
              active: shown,
              label: oraclePercent,
              child: const PowerHelpMiniOption(height: AppSpacing.xl),
            ),
            const SizedBox(height: AppSpacing.md),
            const PowerHelpMiniOption(height: AppSpacing.xl),
          ],
        ),
      PowerType.half => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _halfOptionCount; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.sm),
                child: HalfStrikeEffect(
                  removed: shown && _halfRemoved.contains(i),
                  child: const PowerHelpMiniOption(height: AppSpacing.lg),
                ),
              ),
          ],
        ),
      PowerType.hint => Column(
          children: [
            const PowerHelpMiniOption(height: AppSpacing.md, filled: true),
            const SizedBox(height: AppSpacing.sm),
            HintRevealEffect(text: shown ? hintText : null),
            const SizedBox(height: AppSpacing.sm),
            const PowerHelpMiniOption(height: AppSpacing.lg),
          ],
        ),
      PowerType.timeExtend => Center(
          child: PowerHelpMiniTimer(shown: shown, round: round, seconds: timeExtendSeconds),
        ),
      PowerType.skip || PowerType.skipAll => SkipSlideEffect(
          key: ValueKey(round),
          playToken: shown ? 1 : 0,
          child: PowerHelpMiniCard(stacked: type == PowerType.skipAll),
        ),
      // Quiz çubuğunda yok (yalnız sohbet sorusu engeli).
      PowerType.powerBlock || PowerType.powerUnblock => const SizedBox.shrink(),
    };
  }
}
