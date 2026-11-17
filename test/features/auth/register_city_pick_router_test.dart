import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/data/repositories/city_repository.dart';
import 'package:qulo_v2/features/auth/mixins/register_screen_mixin.dart';
import 'package:qulo_v2/features/auth/screens/register_screen.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_location.dart';
import 'package:qulo_v2/features/location/providers/city_picker_provider.dart';
import 'package:qulo_v2/features/location/screens/city_picker_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/onboarding_seen_provider.dart';
import 'package:qulo_v2/routing/app_router.dart';

import '../../helpers/fake_location_manager.dart';

/// GERÇEK router + gerçek NavigationService ile e-postalı kayıt: hesap henüz yokken
/// konum adımında "Şehir seç" şehir seçiciyi açmalı, seçim kayıt ekranına dönmeli.
///
/// Sahte gezinmeyle yazılan testler bunu yakalayamadı: router'ın oturumsuz kullanıcı kuralı
/// `/city-picker`'ı landing'e atıyordu (2.0.19 build 106, gönderim öncesi bulundu).
const _istanbul = CityModel(id: 'TR-istanbul', name: 'İstanbul', country: 'TR');

class _Guest extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _Seen extends OnboardingSeenNotifier {
  @override
  bool build() => true;
}

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
  testWidgets('oturumsuz kayıt: Şehir seç → seçici açılır → seçim kayıt adımına döner', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AnalyticsManager.debugEventSink = (_, __) {};
    AnalyticsForwarder.debugTrackSink = (_, __, ___) {};
    AnalyticsForwarder.instance.setEnabled(false);
    addTearDown(() {
      AnalyticsManager.debugEventSink = null;
      AnalyticsForwarder.debugTrackSink = null;
    });

    final cities = _Cities();
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(_Guest.new),
      onboardingSeenProvider.overrideWith(_Seen.new),
      locationManagerProvider.overrideWithValue(FakeLocationManager()),
      cityRepositoryProvider.overrideWithValue(cities),
      deviceRegionProvider.overrideWithValue('TR'),
    ]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);

    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        // InkSparkle shader'ı testte çözülemiyor.
        theme: AppTheme.dark.copyWith(splashFactory: NoSplash.splashFactory),
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
      ),
    ));
    router.go('/auth/login/register');
    await settle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    // Konum adımı (5/7): önceki adımların doğrulaması bu testin konusu değil.
    (tester.state(find.byType(RegisterScreen)) as RegisterScreenMixin).goToStep(4);
    await settle();
    expect(find.byType(RegisterStepLocation), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Continue'), findsNothing, reason: 'konum da şehir de yok');

    await tester.tap(find.widgetWithText(AppButton, 'Choose a city'));
    await settle();
    expect(find.byType(CityPickerScreen), findsOneWidget, reason: 'landing\'e atılmamalı');
    expect(router.routerDelegate.currentConfiguration.uri.path, isNot('/auth/landing'));

    await tester.tap(find.text('İstanbul'));
    await settle();
    expect(find.byType(CityPickerScreen), findsNothing);
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('İstanbul'), findsOneWidget, reason: 'seçilen şehir adımda görünür');
    expect(find.widgetWithText(AppButton, 'Continue'), findsOneWidget);
    expect(cities.saved, isEmpty, reason: 'hesap yokken sunucuya yazılmaz');
  });
}
