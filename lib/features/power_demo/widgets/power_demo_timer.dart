import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/time_extend_effect.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

/// Gerçek quiz sayacı + Ek Süre'de beliren "+N" çipi (sayacın satırında, sonda).
///
/// Sayacın sayıyı yukarı sayması çağıranın işidir (`QuizTimerState.addSeconds`); çip yalnız
/// "bu soruda süre eklendi" der. Demo süreyi hiç bitirmez: [onCritical] (5 sn) sayacı durdurur.
class PowerDemoTimer extends StatelessWidget {
  const PowerDemoTimer({
    super.key,
    required this.timerKey,
    required this.questionId,
    required this.seconds,
    required this.totalSeconds,
    required this.extendSeconds,
    required this.extendToken,
    required this.onCritical,
  });

  final GlobalKey<QuizTimerState> timerKey;
  final String questionId;
  final int seconds;
  final int totalSeconds;

  /// Ek Süre'nin eklediği saniye (config `timing.timeExtendSeconds`).
  final int extendSeconds;

  /// Değişince "+N" çipi oynar.
  final int extendToken;
  final VoidCallback onCritical;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        QuizTimer(
          key: timerKey,
          seconds: seconds,
          totalSeconds: totalSeconds,
          questionId: questionId,
          onTimeout: _neverTimesOut,
          onCritical: onCritical,
        ),
        // Saniye satırının sonunda; ilerleme çubuğunun altına iner, üstünü örtmez.
        PositionedDirectional(
          end: 0,
          bottom: -AppSpacing.sm,
          // "+N" sağdan sola dillerde de "+N" okunur.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TimeExtendEffect(seconds: extendSeconds, playToken: extendToken),
          ),
        ),
      ],
    );
  }

  /// [onCritical] sayacı 5 sn'de durdurduğu için çağrılmaz; demo kimseyi süreden elemez.
  static void _neverTimesOut() {}
}
