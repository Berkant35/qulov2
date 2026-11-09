import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_player.dart';

/// TIME_EXTEND: "+N" çipi aşağıdan sayaca doğru kayarak belirir ve sayacın yanında kalır
/// ("bu soruda süre eklendi"). Sayaç sayısının yukarı sayması çağıranın işidir.
///
/// [playToken] değişince çip baştan oynar; aynı token ile yeniden build oynatmaz, ilk
/// build de oynatmaz (çip yok). Konumlandırma çağıranındır; çip tıklanamaz.
class TimeExtendEffect extends StatefulWidget {
  const TimeExtendEffect({super.key, required this.seconds, required this.playToken});

  /// Eklenen süre (config `timing.timeExtendSeconds`); birim metni yok, yalnız "+N".
  final int seconds;
  final int playToken;

  @visibleForTesting
  static const Key chipKey = ValueKey('time_extend_chip');

  @override
  State<TimeExtendEffect> createState() => _TimeExtendEffectState();
}

class _TimeExtendEffectState extends State<TimeExtendEffect>
    with SingleTickerProviderStateMixin, PowerEffectPlayer<TimeExtendEffect> {
  /// Çip kendi yüksekliğinin %80'i aşağıdan gelir.
  static const _startOffset = Offset(0, 0.8);

  late final Animation<double> _fade = phase(0, 0.5);
  late final Animation<Offset> _slide = Tween<Offset>(begin: _startOffset, end: Offset.zero).animate(phase(0, 1));

  @override
  void didUpdateWidget(TimeExtendEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playToken != oldWidget.playToken) playIn(restart: true);
  }

  @override
  Widget build(BuildContext context) {
    return whenActive(
      () => IgnorePointer(
        child: FadeTransition(
          key: TimeExtendEffect.chipKey,
          opacity: _fade,
          child: SlideTransition(position: _slide, child: _TimeChip(seconds: widget.seconds)),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.success,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        child: Text(
          '+${context.fmt.integer(seconds)}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.inkOnDark,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
