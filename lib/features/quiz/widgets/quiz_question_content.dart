import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/question_owner_header.dart';
import 'package:qulo_v2/data/models/quiz_model.dart' show QuizQuestionModel;
import 'package:qulo_v2/features/quiz/mixins/power_effect_labels_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_question_content_mixin.dart';
import 'package:qulo_v2/features/quiz/models/quiz_target_args.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_confirm_button.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_question_card.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer_section.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';

/// Aktif quiz sorusu: sayaç, soru, ipucu, şıklar ve güç çubuğu.
///
/// Güç efektleri (spec §5) yalnız bu quiz'e özel sarmalayıcılarda: Yarıla/Kâhin
/// `PowerEffectAnswerOption`, İpucu ve Doğru Say / Hepsini Geç [QuizQuestionCard], Ek Süre
/// [QuizTimerSection]. Sohbetle paylaşılan `AnswerButton`/`QuizTimer` değişmez. Efekt
/// girdileri yalnız sunucu başarı dalında değişir (`QuizPowerMixin`).
///
/// Küçük ekran / büyük yazı: yalnız soru alanı kayar; sayaç üstte, Cevapla + güç çubuğu (ve
/// "?" baloncuğu) altta hep görünür — baloncuk açılınca şıkları örtmez, soru alanı daralır.
class QuizQuestionContent extends ConsumerWidget
    with PowerEffectLabelsMixin, QuizQuestionContentMixin {
  final QuizQuestionModel question;
  /// Sorusu cozulen kisi — isim/foto/mesafe (yoksa satir gizlenir).
  final QuizTargetArgs? target;
  final GlobalKey<QuizTimerState> timerKey;
  final String sessionId;
  final int? selectedAnswerIndex;
  final int? oracleSuggestedIndex;
  final List<int> removedIndices;
  final String? hintText;
  final bool isSubmitting;

  /// Değişince Ek Süre'nin "+N" çipi oynar.
  final int timeExtendEffectToken;

  /// Değişince soru kartı kenara kayar (Doğru Say / Hepsini Geç).
  final int skipEffectToken;
  final VoidCallback onTimeout;
  final ValueChanged<int> onSelectAnswer;
  final Future<void> Function() onSubmitAnswer;
  final Future<void> Function(String power) onPowerUsed;

  const QuizQuestionContent({
    super.key,
    required this.question,
    this.target,
    required this.timerKey,
    required this.sessionId,
    required this.selectedAnswerIndex,
    required this.oracleSuggestedIndex,
    required this.removedIndices,
    required this.hintText,
    required this.isSubmitting,
    required this.timeExtendEffectToken,
    required this.skipEffectToken,
    required this.onTimeout,
    required this.onSelectAnswer,
    required this.onSubmitAnswer,
    required this.onPowerUsed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accuracy = ref.watch(economyConfigProvider.select((c) => c.oracleAccuracy));
    final extendSeconds =
        ref.watch(economyConfigProvider.select((c) => c.timing.timeExtendSeconds));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuestionOwnerHeader(
                name: target?.name,
                photoUrl: target?.photoUrl,
                distanceKm: target?.distanceKm,
              ),
              QuizTimerSection(
                timerKey: timerKey,
                question: question,
                extendSeconds: extendSeconds,
                extendToken: timeExtendEffectToken,
                onTimeout: onTimeout,
                onWarning: () => logTimerWarning(question),
                onCritical: () => logTimerCritical(question),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            // Yatay boşluk kaydırma alanının İÇİNDE: Kâhin ışıması kenarda kırpılmasın.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.xl,
              AppSpacing.pagePadding,
              AppSpacing.md,
            ),
            child: QuizQuestionCard(
              key: ValueKey(question.questionId),
              question: question,
              hintText: visibleHint(hintText),
              removedIndices: removedIndices,
              oracleSuggestedIndex: oracleSuggestedIndex,
              selectedAnswerIndex: selectedAnswerIndex,
              oracleLabel: oracleAccuracyLabel(context, accuracy),
              skipEffectToken: skipEffectToken,
              onSelectAnswer: onSelectAnswer,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            0,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kaydırma alanının dışında: şık seçilince Cevapla küçük ekranda da hep görünür.
              if (selectedAnswerIndex != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: QuizConfirmButton(
                    isSubmitting: isSubmitting,
                    onSubmitAnswer: onSubmitAnswer,
                  ),
                ),
              // Soru başına yeniden kurulur: açık "?" baloncuğu sonraki soruya taşınmaz.
              PowerBar(
                key: ValueKey(question.questionId),
                sessionId: sessionId,
                hasHint: question.hasHint,
                onPowerUsed: onPowerUsed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
