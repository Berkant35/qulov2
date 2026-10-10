import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Başlıklı etiket çipleri grubu (kimlik ya da yönelim).
class IdentityChipGroup extends StatelessWidget {
  final String titleKey;
  final List<String> labels;
  final String Function(String label) labelKeyOf;
  final Set<String> selected;
  final ValueChanged<String>? onToggle;

  /// Bu grup 3 sınırına çarptıysa mesaj grubun altında gösterilir.
  final bool limitHit;

  const IdentityChipGroup({
    super.key,
    required this.titleKey,
    required this.labels,
    required this.labelKeyOf,
    required this.selected,
    required this.onToggle,
    this.limitHit = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr(titleKey), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final label in labels)
              FilterChip(
                label: Text(context.tr(labelKeyOf(label))),
                selected: selected.contains(label),
                onSelected: onToggle == null ? null : (_) => onToggle!(label),
                selectedColor: colors.primarySurface,
                checkmarkColor: colors.primary,
                side: BorderSide(color: selected.contains(label) ? colors.primary : colors.border),
              ),
          ],
        ),
        if (limitHit) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('identity_max_reached'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
