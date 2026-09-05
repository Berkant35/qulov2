import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/passport/constants/popular_cities.dart';
import 'package:qulo_v2/features/passport/widgets/popular_city_card.dart';

class PopularCityGrid extends StatelessWidget {
  const PopularCityGrid({super.key, required this.onCitySelected});

  final void Function(PopularCity city) onCitySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(context.tr('passport_popular_cities'), style: theme.textTheme.titleSmall?.copyWith(color: context.appColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: AppSpacing.sm, crossAxisSpacing: AppSpacing.sm, childAspectRatio: 2.8),
          itemCount: popularCities.length,
          itemBuilder: (context, index) {
            final city = popularCities[index];
            return PopularCityCard(city: city, onTap: () => onCitySelected(city));
          },
        ),
      ],
    );
  }
}
