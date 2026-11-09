import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/keep_visible_on_select.dart';
import 'package:qulo_v2/core/widgets/power_effects/hint_reveal_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_answer_option.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_slide_effect.dart';
import 'package:qulo_v2/data/models/quiz_model.dart' show QuizQuestionModel;
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';

/// Quiz soru kartı: soru, ipucu kartı, şıklar. Cevapla kaydırma alanının dışında (her zaman
/// görünür) — bkz. `QuizQuestionContent`. Seçilen şık görünür kalır ([KeepVisibleOnSelect]):
/// Cevapla belirince alan daralır, alt kenardaki şık kırpılmaz.
///
/// Doğru Say / Hepsini Geç'te kart kenara kayar ([SkipSlideEffect]). Çağıran kartı soru başına
/// yeniden kurar (`key: ValueKey(soru)`): sıradaki soru taze kartla ve efektsiz gelir.
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.hintText,
    required this.removedIndices,
    required this.oracleSuggestedIndex,
    required this.selectedAnswerIndex,
    required this.oracleLabel,
    required this.skipEffectToken,
    required this.onSelectAnswer,
  });

  final QuizQuestionModel question;

  /// Görünecek ipucu (boşsa null).
  final String? hintText;
  final List<int> removedIndices;
  final int? oracleSuggestedIndex;
  final int? selectedAnswerIndex;

  /// Kâhin etiketi ("%70 doğru").
  final String oracleLabel;
  final int skipEffectToken;
  final ValueChanged<int> onSelectAnswer;

  @override
  Widget build(BuildContext context) {
    return SkipSlideEffect(
      playToken: skipEffectToken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question.questionText,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          HintRevealEffect(text: hintText),
          ...question.answers.map((a) {
            final isRemoved = removedIndices.contains(a.index);
            final isSelected = selectedAnswerIndex == a.index;
            return KeepVisibleOnSelect(
              key: ValueKey(a.index),
              selected: isSelected,
              child: PowerEffectAnswerOption(
                removed: isRemoved,
                suggested: oracleSuggestedIndex == a.index,
                oracleLabel: oracleLabel,
                child: AnswerButton(
                  text: a.text,
                  onTap: () {
                    if (!isRemoved) onSelectAnswer(a.index);
                  },
                  isSelected: isSelected,
                  isDisabled: isRemoved,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
