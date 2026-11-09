import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_player.dart';

/// SKIP_ALL: başlıktaki "N/M" sayacı hızla M'ye sayar, sayaç bitince yanında ✓ belirir.
///
/// "from/to" metni `from`'dan `to`'ya sayar (payda `to` sabit). Stil çevreden (`DefaultTextStyle`)
/// gelir; ✓ metnin dışında yer alır, sayaç yerinden oynamaz. [playToken] değişince baştan
/// oynar; ilk build ve aynı token oynatmaz.
class SkipAllCounterEffect extends StatefulWidget {
  const SkipAllCounterEffect({super.key, required this.from, required this.to, required this.playToken})
      : assert(from <= to, 'sayaç geriye saymaz');

  final int from;
  final int to;
  final int playToken;

  @visibleForTesting
  static const Key counterKey = ValueKey('skip_all_counter');
  @visibleForTesting
  static const Key checkKey = ValueKey('skip_all_check');

  @override
  State<SkipAllCounterEffect> createState() => _SkipAllCounterEffectState();
}

class _SkipAllCounterEffectState extends State<SkipAllCounterEffect>
    with SingleTickerProviderStateMixin, PowerEffectPlayer<SkipAllCounterEffect> {
  /// Sayım giriş süresinin ilk %80'inde biter; ✓ son %30'da belirir.
  static const _countEnd = 0.8;
  static const _checkStart = 0.7;
  static const _tabularFigures = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

  late final Animation<double> _count = phase(0, _countEnd);
  late final Animation<double> _check = phase(_checkStart, 1);

  @override
  void didUpdateWidget(SkipAllCounterEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playToken != oldWidget.playToken) playIn(restart: true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _count,
          builder: (context, _) {
            final current = widget.from + ((widget.to - widget.from) * _count.value).round();
            return Text(
              '${context.fmt.integer(current)}/${context.fmt.integer(widget.to)}',
              key: SkipAllCounterEffect.counterKey,
              style: _tabularFigures,
            );
          },
        ),
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: -(AppSpacing.lg + AppSpacing.xs),
          child: Center(
            child: whenActive(
              () => FadeTransition(
                key: SkipAllCounterEffect.checkKey,
                opacity: _check,
                child: Icon(Icons.check_rounded, color: context.appColors.success, size: AppSpacing.lg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
