import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Test admin ülke önizlemesi (spec §7.3): Tümü + sunucunun verdiği ülkeler.
class MarketCountryPreviewChips extends StatelessWidget {
  const MarketCountryPreviewChips({
    super.key,
    required this.countries,
    required this.selected,
    required this.onSelected,
  });

  final List<String> countries;
  final String? selected;
  final void Function(String? country) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Row(
        children: [
          for (final country in <String?>[null, ...countries])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(country ?? context.tr('market_country_all')),
                selected: selected == country,
                onSelected: (_) => onSelected(country),
              ),
            ),
        ],
      ),
    );
  }
}
