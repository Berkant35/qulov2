import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_player.dart';

/// ORACLE: önerilen şık için tek seferlik yumuşak vurgu (ışıma) + köşede "%X doğru" etiketi.
///
/// Mevcut sonsuz nabız yerine tek giriş animasyonudur: [active] `false → true` olunca ışıma
/// ve etiket belirir, sonra sabit kalır. İlk build zaten aktifse animasyonsuz açılır.
/// Işıma köşe yarıçapı `AppSpacing.radiusMd` (cevap şıkkıyla aynı) varsayar; etiket
/// çocuğun üst-son köşesine biner, yerleşimi etkilemez ve dokunuşu engellemez.
class OracleHighlight extends StatefulWidget {
  const OracleHighlight({super.key, required this.child, required this.active, required this.label});

  final Widget child;
  final bool active;

  /// Hazır metin (örn. "%70 doğru"); yüzde formatı çağıranda `context.fmt.percent` ile yapılır.
  final String label;

  @visibleForTesting
  static const Key glowKey = ValueKey('oracle_glow');
  @visibleForTesting
  static const Key labelKey = ValueKey('oracle_label');

  @override
  State<OracleHighlight> createState() => _OracleHighlightState();
}

class _OracleHighlightState extends State<OracleHighlight>
    with SingleTickerProviderStateMixin, PowerEffectPlayer<OracleHighlight> {
  static const _glowAlpha = 0.4;
  static const _glowBlur = 14.0;
  static const _glowSpread = 2.0;
  static const _labelStartScale = 0.85;

  late final Animation<double> _glow = phase(0, 1);
  late final Animation<double> _labelIn = phase(0.3, 1);
  late final Animation<double> _labelScale = Tween<double>(begin: _labelStartScale, end: 1).animate(_labelIn);

  @override
  void initState() {
    super.initState();
    settleAt(widget.active ? 1 : 0);
  }

  @override
  void didUpdateWidget(OracleHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    widget.active ? playIn() : playOut();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = context.appColors.primary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _glow,
          child: widget.child,
          builder: (context, child) {
            final t = _glow.value;
            return DecoratedBox(
              key: OracleHighlight.glowKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: t == 0
                    ? null
                    : [
                        BoxShadow(
                          color: glowColor.withValues(alpha: _glowAlpha * t),
                          blurRadius: _glowBlur * t,
                          spreadRadius: _glowSpread * t,
                        ),
                      ],
              ),
              child: child,
            );
          },
        ),
        // start+end sınırı etiketi çocuğun genişliğiyle kısıtlar (uzun çeviri taşmaz, "…" ile kısalır).
        PositionedDirectional(
          top: -AppSpacing.md,
          start: AppSpacing.md,
          end: AppSpacing.md,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: whenActive(
              () => IgnorePointer(
                child: FadeTransition(
                  key: OracleHighlight.labelKey,
                  opacity: _labelIn,
                  child: ScaleTransition(scale: _labelScale, child: _OracleLabel(text: widget.label)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OracleLabel extends StatelessWidget {
  const _OracleLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
