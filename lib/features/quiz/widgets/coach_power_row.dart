import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';

/// Güç turu kartındaki tek satır: güç ikonu + kısa açıklama.
class CoachPowerRow extends StatelessWidget {
  const CoachPowerRow({super.key, required this.type, required this.labelKey});

  final PowerType type;
  final String labelKey;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            PowerIcon(type: type, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.tr(labelKey),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
}
