import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_all_counter_effect.dart';

/// Demonun üst şeridi: ortada "3/7" adım sayacı (Hepsini Geç'te sona sayar), sonda tek "Atla".
///
/// Tanıtım carousel'inin genel "Atla"sı bu sayfada gizlenir; demodaki tek atla budur.
class PowerDemoHeader extends StatelessWidget {
  const PowerDemoHeader({
    super.key,
    required this.step,
    required this.total,
    required this.counterToken,
    required this.onSkip,
  });

  /// 1 tabanlı adım; `null` → sayaç yok (giriş ekranı).
  final int? step;
  final int total;

  /// Değişince sayaç [step]'ten [total]'e sayar (Hepsini Geç).
  final int counterToken;

  /// `null` → "Atla" yok (kapanış).
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final step = this.step;
    final onSkip = this.onSkip;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (step != null)
              // "a/b" sağdan sola dillerde de soldan sağa okunur.
              Directionality(
                textDirection: TextDirection.ltr,
                child: DefaultTextStyle.merge(
                  style: textTheme.titleMedium?.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  child: SkipAllCounterEffect(from: step, to: total, playToken: counterToken),
                ),
              ),
            if (onSkip != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(
                    context.tr('skip'),
                    style: textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
