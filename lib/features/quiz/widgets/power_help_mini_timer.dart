import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';
import 'package:qulo_v2/core/widgets/power_effects/time_extend_effect.dart';

/// Ek Süre minyatürü: sayaç çubuğu süre eklenince dolar, sonunda "+N" çipi belirir
/// (gerçek quiz'deki [TimeExtendEffect]). [round] her turu taze çiple başlatır.
class PowerHelpMiniTimer extends StatelessWidget {
  const PowerHelpMiniTimer({
    super.key,
    required this.shown,
    required this.round,
    required this.seconds,
  });

  /// Çubuğun doluluğu: süre eklenmeden önce / sonra.
  static const _before = 0.4;
  static const _after = 0.9;

  final bool shown;
  final int round;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          height: AppSpacing.md,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: ColoredBox(
              color: context.appColors.surfaceElevated,
              child: AnimatedFractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: shown ? _after : _before,
                duration: reduceMotionOf(context) ? Duration.zero : PowerEffectTiming.enter,
                curve: PowerEffectTiming.curve,
                child: ColoredBox(color: context.appColors.secondary),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          end: 0,
          top: AppSpacing.lg,
          // "+N" sağdan sola dillerde de "+N" okunur.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TimeExtendEffect(
              key: ValueKey(round),
              seconds: seconds,
              playToken: shown ? 1 : 0,
            ),
          ),
        ),
      ],
    );
  }
}
