import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/time_extend_effect.dart';
import 'package:qulo_v2/data/models/quiz_model.dart' show QuizQuestionModel;
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

/// Quiz sayacı + Ek Süre'de beliren "+N" çipi (sayacın satırında, sonda).
///
/// Sayının yukarı sayması [QuizTimerState.addSeconds]'tadır (değişmedi); çip yalnız
/// "bu soruda süre eklendi" der. Çip soru başına yeniden kurulur: sonraki soruda görünmez.
class QuizTimerSection extends StatelessWidget {
  const QuizTimerSection({
    super.key,
    required this.timerKey,
    required this.question,
    required this.extendSeconds,
    required this.extendToken,
    required this.onTimeout,
    required this.onWarning,
    required this.onCritical,
  });

  final GlobalKey<QuizTimerState> timerKey;
  final QuizQuestionModel question;

  /// Ek Süre'nin eklediği saniye (config `timing.timeExtendSeconds`).
  final int extendSeconds;

  /// Değişince "+N" çipi oynar (yalnız sunucu başarı dalında artar).
  final int extendToken;
  final VoidCallback onTimeout;
  final VoidCallback onWarning;
  final VoidCallback onCritical;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        QuizTimer(
          key: timerKey,
          seconds: question.startSeconds,
          totalSeconds: question.timeLimitSeconds,
          questionId: question.questionId,
          onTimeout: onTimeout,
          onWarning: onWarning,
          onCritical: onCritical,
        ),
        // Saniye satırının sonunda; ilerleme çubuğunu örtmez.
        PositionedDirectional(
          end: 0,
          bottom: -AppSpacing.sm,
          // "+N" sağdan sola dillerde de "+N" okunur.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TimeExtendEffect(
              key: ValueKey(question.questionId),
              seconds: extendSeconds,
              playToken: extendToken,
            ),
          ),
        ),
      ],
    );
  }
}
