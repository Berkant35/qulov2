import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/data/repositories/city_repository.dart';
import 'package:qulo_v2/features/location/providers/city_picker_provider.dart';
import 'package:qulo_v2/features/location/screens/city_picker_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_navigation.dart';

/// Yalnız seçim kipi (kayıt / profil tamamlama): hesap henüz yok, seçici ağa YAZMAZ,
/// seçilen şehri çağırana döndürür.
const _istanbul = CityModel(id: 'TR-istanbul', name: 'İstanbul', country: 'TR');

class _Cities implements CityRepository {
  final saved = <String>[];

  @override
  Future<Result<CityListResponse>> search({String? country, String query = '', int limit = 100}) async =>
      const Success(CityListResponse(countries: ['TR'], cities: [_istanbul]));

  @override
  Future<Result<void>> setCity(String cityId) async {
    saved.add(cityId);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('_Cities.${invocation.memberName}');
}

void main() {
  testWidgets('şehre dokununca şehir döner, sunucuya yazılmaz', (tester) async {
    final cities = _Cities();
    final nav = FakeNavigationService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        deviceRegionProvider.overrideWithValue('TR'),
        cityRepositoryProvider.overrideWithValue(cities),
        navigationServiceProvider.overrideWithValue(nav),
      ],
      child: MaterialApp(
        // InkSparkle shader'ı testte çözülemiyor.
        theme: AppTheme.dark.copyWith(splashFactory: NoSplash.splashFactory),
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const CityPickerScreen(selectOnly: true),
      ),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('İstanbul'));
    await tester.pump();

    expect(nav.popResults, [_istanbul]);
    expect(cities.saved, isEmpty);
  });
}
