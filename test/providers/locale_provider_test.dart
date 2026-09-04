import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dil tercihi kullanıcının, bölge cihazın: `en_US` ile `en_GB` ayrılmalı
/// (12/24 saat ve mil bundan türer). Cihaz bölgesi test binding'iyle sabitlenir.
void main() {
  testWidgets('kayıtlı dil tercihi cihaz bölgesiyle birleşir', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({'app_locale': 'tr'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(localeProvider);
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), const Locale('tr', 'US'));
  });

  testWidgets('setLocale dili değiştirir, bölgeyi korur, tercihe yalnız dili yazar', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(localeProvider.notifier).setLocale(const Locale('de'));

    expect(container.read(localeProvider), const Locale('de', 'GB'));
    expect((await SharedPreferences.getInstance()).getString('app_locale'), 'de');
  });
}
