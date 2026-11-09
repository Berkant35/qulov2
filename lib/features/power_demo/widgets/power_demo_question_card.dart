import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/keep_visible_on_select.dart';
import 'package:qulo_v2/core/widgets/power_effects/hint_reveal_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_answer_option.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_slide_effect.dart';
import 'package:qulo_v2/features/power_demo/constants/power_demo_keys.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_question.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';

/// Demo sorusu, gerçek quiz bileşenleriyle: sayaç ([timer]), soru, ipucu kartı, şıklar.
/// Cevapla kartta değil, kaydırma alanının dışında (`PowerDemoStage.confirm`).
///
/// Kart soru başına yeniden kurulur (`ValueKey(soru)`): Doğru Say kartı kenara kaydırıp gizler,
/// sıradaki soru taze kartla gelir. Seçilen şık görünür kalır ([KeepVisibleOnSelect]): Cevapla
/// belirince alan daralır, alt kenardaki şık kırpılmaz.
class PowerDemoQuestionCard extends StatelessWidget {
  const PowerDemoQuestionCard({
    super.key,
    required this.question,
    required this.progress,
    required this.oracleLabel,
    required this.timer,
    required this.onSelect,
  });

  final PowerDemoQuestion question;
  final PowerDemoProgress progress;

  /// Kâhin etiketi ("%70 doğru").
  final String oracleLabel;
  final Widget timer;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final hint = question.hasHint && p.hintVisible
        ? context.tr(PowerDemoKeys.questionHint(question))
        : null;
    return SkipSlideEffect(
      key: ValueKey(question.id),
      playToken: p.skipToken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          timer,
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr(PowerDemoKeys.question(question)),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.appColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          HintRevealEffect(text: hint),
          for (var i = 0; i < question.optionCount; i++)
            KeepVisibleOnSelect(
              selected: p.selectedIndex == i,
              child: PowerEffectAnswerOption(
                removed: p.removedIndices.contains(i),
                suggested: p.oracleIndex == i,
                oracleLabel: oracleLabel,
                child: AnswerButton(
                  text: context.tr(PowerDemoKeys.option(question, i)),
                  onTap: () => onSelect(i),
                  isSelected: p.selectedIndex == i,
                  isDisabled: p.removedIndices.contains(i),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
