import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/half_strike_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/oracle_highlight.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';

/// Tek şıkkın güç efektleri: Kâhin vurgusu ([OracleHighlight]) + Yarıla'nın üstünü çizip
/// kapatması ([HalfStrikeEffect]) + şıkkın üst boşluğunun elenen şıkla birlikte kapanması.
///
/// Gerçek quiz ve güç demosu aynı bileşeni kullanır (demo neyi öğretiyorsa quiz onu yapar).
/// Şıkkın kendisi [child] (quiz'de `AnswerButton`); efekt opt-in sarmalayıcıdır, sohbet sorusu
/// çıplak `AnswerButton` kullanır (spec §13.2). Kâhin'in sonsuz nabzı (`isOracleSuggested`)
/// yerine tek giriş animasyonu + "%X doğru" etiketi gelir (spec §5).
///
/// Sıra bilinçli: [OracleHighlight] dışta, çünkü [HalfStrikeEffect] kapanırken çocuğunu kırpar
/// ve etiket şıkkın üst kenarına taşar.
class PowerEffectAnswerOption extends StatelessWidget {
  const PowerEffectAnswerOption({
    super.key,
    required this.removed,
    required this.suggested,
    required this.oracleLabel,
    required this.child,
  });

  /// [HalfStrikeEffect] çizgiyi girişin ilk %45'inde çeker, kalanında kapanır; boşluk da o an.
  static const _collapseStart = 0.45;

  /// Yarıla eledi: üstü çizilir, kapanır, dokunuş yakalamaz.
  final bool removed;

  /// Kâhin bu şıkkı önerdi.
  final bool suggested;

  /// Kâhin etiketi ("%70 doğru"); yüzde biçimi çağıranda.
  final String oracleLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(top: removed ? 0 : AppSpacing.md),
      duration: reduceMotionOf(context) ? Duration.zero : PowerEffectTiming.enter,
      curve: const Interval(_collapseStart, 1, curve: PowerEffectTiming.curve),
      child: OracleHighlight(
        active: suggested,
        label: oracleLabel,
        child: HalfStrikeEffect(removed: removed, child: child),
      ),
    );
  }
}
