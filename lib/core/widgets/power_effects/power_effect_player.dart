import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';

/// Güç efektlerinin ortak oynatıcısı: tek denetleyici, `0` = efekt öncesi, `1` = son hâl.
///
/// Efekt widget'ları ilk kurulumda [settleAt] ile doğrudan yerleşir (ilk çizimde oynamaz),
/// sonraki girdi değişimlerinde [playIn] / [playOut] çağırır. "Hareketi azalt" açıksa
/// oynatma yerine hedef değere anında atlanır; böylece son hâl ilk karede görünür.
mixin PowerEffectPlayer<T extends StatefulWidget> on SingleTickerProviderStateMixin<T> {
  late final AnimationController effect = AnimationController(
    vsync: this,
    duration: PowerEffectTiming.enter,
    reverseDuration: PowerEffectTiming.exit,
  );

  /// Animasyonsuz yerleşir (ilk kurulum).
  void settleAt(double value) => effect.value = value;

  /// Son hâle oynar. [restart] önce başa alır (aynı efektin yeniden oynatılması).
  void playIn({bool restart = false}) {
    if (reduceMotionOf(context)) {
      effect.value = 1;
      return;
    }
    effect.forward(from: restart ? 0 : null);
  }

  /// Efekt öncesi hâle kapanır.
  void playOut() {
    if (reduceMotionOf(context)) {
      effect.value = 0;
      return;
    }
    effect.reverse();
  }

  /// Denetleyicinin `[begin, end]` aralığındaki 0→1 dilimi, [PowerEffectTiming.curve] ile.
  Animation<double> phase(double begin, double end) =>
      effect.drive(CurveTween(curve: Interval(begin, end, curve: PowerEffectTiming.curve)));

  /// Efekt dinlenme hâlindeyken (başlamadı ya da kapandı) içeriği ağaçta tutmaz;
  /// görünmez ama bulunabilir metin kalmasın diye.
  Widget whenActive(Widget Function() builder) => AnimatedBuilder(
        animation: effect,
        builder: (context, _) => effect.isDismissed ? const SizedBox.shrink() : builder(),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Okuma koşulsuz: MediaQuery bağımlılığı ilk çağrıda kurulmalı ki ayar sonradan değişirse haber gelsin.
    final reduce = reduceMotionOf(context);
    if (reduce && effect.isAnimating) {
      effect.value = effect.status == AnimationStatus.reverse ? 0 : 1;
    }
  }

  @override
  void dispose() {
    effect.dispose();
    super.dispose();
  }
}
