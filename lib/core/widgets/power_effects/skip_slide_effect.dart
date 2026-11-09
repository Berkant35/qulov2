import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_player.dart';

/// SKIP: soru kartı okuma yönünde kenara kayıp soluklaşır, yerinde ✓ rozeti belirir.
///
/// [playToken] değişince oynar; ilk build ve aynı token oynatmaz. Son hâlde kart görünmez
/// ve dokunuş yakalamaz, ✓ kalır: sıradaki soruya geçerken çağıran efekti yeniden kurar
/// (örn. `key: ValueKey(soruNo)`). Aynı efekt tekrar oynatılırsa kart başa dönüp yeniden kayar.
class SkipSlideEffect extends StatefulWidget {
  const SkipSlideEffect({super.key, required this.child, required this.playToken});

  final Widget child;
  final int playToken;

  @visibleForTesting
  static const Key childKey = ValueKey('skip_slide_child');
  @visibleForTesting
  static const Key badgeKey = ValueKey('skip_slide_badge');

  @override
  State<SkipSlideEffect> createState() => _SkipSlideEffectState();
}

class _SkipSlideEffectState extends State<SkipSlideEffect>
    with SingleTickerProviderStateMixin, PowerEffectPlayer<SkipSlideEffect> {
  /// Kart giriş süresinin ilk %70'inde kayar; ✓ ikinci yarıda belirir (kısa bir örtüşmeyle).
  static const _slideEnd = 0.7;
  static const _badgeStart = 0.5;
  static const _badgeStartScale = 0.6;

  late final Animation<double> _away = phase(0, _slideEnd);
  late final Animation<Offset> _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(1, 0)).animate(_away);
  late final Animation<double> _cardOpacity = Tween<double>(begin: 1, end: 0).animate(_away);
  late final Animation<double> _badgeIn = phase(_badgeStart, 1);
  late final Animation<double> _badgeScale = Tween<double>(begin: _badgeStartScale, end: 1).animate(_badgeIn);

  @override
  void didUpdateWidget(SkipSlideEffect oldWidget) {
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
          animation: effect,
          child: SlideTransition(
            position: _slide,
            textDirection: Directionality.of(context),
            child: FadeTransition(key: SkipSlideEffect.childKey, opacity: _cardOpacity, child: widget.child),
          ),
          builder: (context, card) => IgnorePointer(ignoring: effect.value > 0, child: card),
        ),
        whenActive(
          () => IgnorePointer(
            child: FadeTransition(
              key: SkipSlideEffect.badgeKey,
              opacity: _badgeIn,
              child: ScaleTransition(scale: _badgeScale, child: const _SkipBadge()),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkipBadge extends StatelessWidget {
  const _SkipBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: context.appColors.success, shape: BoxShape.circle),
      child: const SizedBox.square(
        dimension: AppSpacing.xxxl,
        child: Icon(Icons.check_rounded, color: AppColors.inkOnDark, size: AppSpacing.xl),
      ),
    );
  }
}
