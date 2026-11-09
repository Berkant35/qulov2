import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/features/location/providers/city_picker_provider.dart';
import 'package:qulo_v2/features/location/providers/city_picker_state.dart';
import 'package:qulo_v2/features/location/screens/city_picker_screen.dart';

/// Şehir seçici ekranının mantığı: arama (debounce), ülke seçimi, kayıt sonucu.
mixin CityPickerScreenMixin on ConsumerState<CityPickerScreen> {
  final searchCtrl = TextEditingController();
  Timer? _debounce;

  void initMixin() {
    Future.microtask(() => ref.read(cityPickerProvider.notifier).start());
  }

  void disposeMixin() {
    _debounce?.cancel();
    searchCtrl.dispose();
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.debounce, () => ref.read(cityPickerProvider.notifier).search(query));
  }

  void onCountrySelected(String country) => ref.read(cityPickerProvider.notifier).selectCountry(country);

  void retry() => ref.read(cityPickerProvider.notifier).search(searchCtrl.text);

  /// Başarıda ekran kapanır (Discover şehir merkeziyle yeniden yüklenir).
  /// 404 `CITY_NOT_FOUND`: liste tazelenir, kullanıcı yeniden seçer.
  Future<void> onCityTap(CityModel city) async {
    final nav = ref.read(navigationServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final messages = {
      CitySaveResult.cityGone: context.tr('city_picker_city_gone'),
      CitySaveResult.failed: context.tr('city_picker_save_failed'),
    };
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await ref.read(cityPickerProvider.notifier).save(city);
    if (result == null) return;
    if (result == CitySaveResult.saved) {
      nav.pop(true);
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(messages[result]!)));
  }
}
