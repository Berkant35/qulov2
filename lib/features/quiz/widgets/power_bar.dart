import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

class PowerBar extends ConsumerWidget {
  final String sessionId;
  final bool hasHint;
  final void Function(String power)? onPowerUsed;

  const PowerBar({
    super.key,
    required this.sessionId,
    this.hasHint = false,
    this.onPowerUsed,
  });

  static const _powers = [
    (PowerType.oracle, 'power_oracle'),
    (PowerType.half, 'power_half'),
    (PowerType.skip, 'power_skip'),
    (PowerType.hint, 'power_hint'),
    (PowerType.timeExtend, 'power_time'),
    (PowerType.skipAll, 'power_skip_all'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeState = ref.watch(exchangeProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _powers.map((p) {
          final isHint = p.$1 == PowerType.hint;
          final count = exchangeState.getCount(p.$1.apiName);
          final isDisabled = count <= 0 || (isHint && !hasHint);

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ActionChip(
              avatar: PowerIcon(
                type: p.$1,
                size: 18,
                showCount: count > 0,
                count: count,
              ),
              label: Text(context.tr(p.$2)),
              onPressed: isDisabled
                  ? null
                  : () => onPowerUsed?.call(p.$1.apiName),
            ),
          );
        }).toList(),
      ),
    );
  }
}
