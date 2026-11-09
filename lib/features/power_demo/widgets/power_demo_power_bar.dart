import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/features/power_demo/constants/power_demo_keys.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';

/// Demo gücünün quiz'deki görsel karşılığı (ikon, renk). Değerler birebir aynı adlı.
extension DemoPowerType on DemoPower {
  PowerType get type => PowerType.fromApiName(apiName)!;
}

/// Demonun güç çubuğu: gerçek quiz'in saf [PowerBarButton]'ları, her biri "1 hak" ve fiyatsız
/// (demoda mor fiyat gösterilmez) + üstte "hediye" çipi. Provider okumaz.
///
/// Yalnız [target] (bu adımda öğretilen güç) dokunulabilir; [targetKey] onu sarar ki talimat
/// katmanı deliği tam o butonun üstüne açsın.
class PowerDemoPowerBar extends StatelessWidget {
  const PowerDemoPowerBar({
    super.key,
    required this.powers,
    required this.used,
    required this.target,
    required this.targetKey,
    required this.onTap,
  });

  /// Gerçek quiz çubuğunun sırası (`PowerBarMixin`).
  static const order = [
    DemoPower.oracle,
    DemoPower.half,
    DemoPower.skip,
    DemoPower.hint,
    DemoPower.timeExtend,
    DemoPower.skipAll,
  ];

  final List<DemoPower> powers;
  final Set<DemoPower> used;
  final DemoPower? target;
  final GlobalKey targetKey;
  final ValueChanged<DemoPower> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                QIcon(QIcons.gift.outlined, size: AppSpacing.md, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    context.tr('power_demo_gift'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final power in powers)
              KeyedSubtree(
                key: power == target ? targetKey : ValueKey(power),
                child: PowerBarButton(
                  type: power.type,
                  count: 1,
                  isUsed: used.contains(power),
                  purpleCost: 0,
                  label: context.tr(PowerDemoKeys.barLabel(power)),
                  onTap: power == target ? () async => onTap(power) : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
