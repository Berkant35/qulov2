import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/features/location/providers/city_picker_state.dart';

/// Şehir sonuçları: yükleniyor / hata / boş / liste. Ad çevrilmez, olduğu gibi.
class CityPickerList extends StatelessWidget {
  final CityPickerState state;
  final ValueChanged<CityModel> onCityTap;
  final VoidCallback onRetry;

  const CityPickerList({super.key, required this.state, required this.onCityTap, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.cities.isEmpty) return const Center(child: AppLoadingWidget.large());
    if (state.hasError) return ErrorRetryWidget(onRetry: onRetry);
    if (state.cities.isEmpty) {
      return Center(
        child: Text(
          context.tr('city_picker_no_results'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appColors.textHint),
        ),
      );
    }
    final saving = state.savingCityId;
    return ListView.separated(
      itemCount: state.cities.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: context.appColors.divider),
      itemBuilder: (context, index) {
        final city = state.cities[index];
        return ListTile(
          title: Text(city.name),
          trailing: saving == city.id
              ? const AppLoadingWidget.small()
              : Icon(Icons.chevron_right, color: context.appColors.textHint),
          onTap: saving == null ? () => onCityTap(city) : null,
        );
      },
    );
  }
}
