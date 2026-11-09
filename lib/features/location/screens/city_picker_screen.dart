import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/location/mixins/city_picker_screen_mixin.dart';
import 'package:qulo_v2/features/location/providers/city_picker_provider.dart';
import 'package:qulo_v2/features/location/widgets/city_picker_country_bar.dart';
import 'package:qulo_v2/features/location/widgets/city_picker_list.dart';

/// Konum vermeyen kullanıcının yedek yolu: şehir seç → sunucu şehir merkezini
/// konum olarak yazar → Discover çalışır. Sonradan konum izni verilirse GPS
/// güncellemesi şehir merkezinin yerine geçer (sunucu `location_source = gps`).
class CityPickerScreen extends ConsumerStatefulWidget {
  const CityPickerScreen({super.key});

  @override
  ConsumerState<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends ConsumerState<CityPickerScreen> with CityPickerScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cityPickerProvider);
    final hintStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appColors.textSecondary);

    return AppScaffold(
      title: context.tr('city_picker_title'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.tr('city_picker_search_hint'),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.countries.isNotEmpty)
            CityPickerCountryBar(
              countries: state.countries,
              selected: state.country,
              onSelected: onCountrySelected,
            ),
          if (state.regionUnsupported) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(context.tr('city_picker_region_hint'), style: hintStyle),
          ],
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: CityPickerList(state: state, onCityTap: onCityTap, onRetry: retry),
          ),
        ],
      ),
    );
  }
}
