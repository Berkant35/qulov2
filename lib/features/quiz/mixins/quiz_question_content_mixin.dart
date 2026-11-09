import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/quiz_model.dart' show QuizQuestionModel;

/// `QuizQuestionContent`'in sunum dışı işleri: sayaç uyarı olayları ve ipucu görünürlüğü.
mixin QuizQuestionContentMixin {
  /// `QuizTimer`'ın uyarı (onWarning) ve kritik (onCritical) eşikleri.
  static const _warningSeconds = 10;
  static const _criticalSeconds = 5;

  /// Sayaç 10 sn'ye indi.
  void logTimerWarning(QuizQuestionModel question) => _logTimer(
        AnalyticsEvents.quizTimerWarning,
        question,
        secondsRemaining: _warningSeconds,
      );

  /// Sayaç 5 sn'ye indi.
  void logTimerCritical(QuizQuestionModel question) => _logTimer(
        AnalyticsEvents.quizTimerCritical,
        question,
        secondsRemaining: _criticalSeconds,
      );

  /// İpucu kartının metni; boş ipucu kart açmaz.
  String? visibleHint(String? hintText) =>
      (hintText?.isNotEmpty ?? false) ? hintText : null;

  void _logTimer(String event, QuizQuestionModel question, {required int secondsRemaining}) {
    AnalyticsManager.instance.logEvent(
      event,
      params: {
        AnalyticsEvents.paramQuestionIndex: question.questionNumber,
        AnalyticsEvents.paramSecondsRemaining: secondsRemaining,
      },
    );
  }
}
