import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/location/mixins/country_label_mixin.dart';

/// Desteklenen ülkeler (kullanıcı sayısına göre sıralı) yatay çip satırı.
class CityPickerCountryBar extends StatelessWidget with CountryLabelMixin {
  final List<String> countries;
  final String? selected;
  final ValueChanged<String> onSelected;

  const CityPickerCountryBar({
    super.key,
    required this.countries,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kMinInteractiveDimension,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: countries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final code = countries[index];
          return ChoiceChip(
            label: Text(countryLabel(context, code)),
            selected: code == selected,
            onSelected: (_) => onSelected(code),
          );
        },
      ),
    );
  }
}
