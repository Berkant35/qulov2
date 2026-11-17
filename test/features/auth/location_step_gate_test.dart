import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/auth_service.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/city_repository.dart';
import 'package:qulo_v2/features/auth/mixins/profile_completion_mixin.dart';
import 'package:qulo_v2/features/auth/mixins/register_screen_mixin.dart';
import 'package:qulo_v2/features/auth/screens/profile_completion_screen.dart';
import 'package:qulo_v2/features/auth/screens/register_screen.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_location.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

import '../../helpers/fake_location_manager.dart';
import '../../helpers/fake_navigation.dart';
import '../../helpers/fixed_user_notifier.dart';

/// Kayıt akışında konum adımından koordinatsız çıkılamaz (11-16 ölçümü: 6 haftada
/// 62 kullanıcı konumsuz kaldı). İzin ya da şehir; izin dayatılmaz, şehir seçimi
/// izinle eşit ağırlıkta alternatiftir.
const _istanbul = CityModel(id: 'TR-istanbul', name: 'İstanbul', country: 'TR');

class _Cities implements CityRepository {
  _Cities({this.fail = false});

  final bool fail;
  final saved = <String>[];

  @override
  Future<Result<void>> setCity(String cityId) async {
    saved.add(cityId);
    return fail ? const Failure(NetworkFailure()) : const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('_Cities.${invocation.memberName}');
}

class _FakeAuthService implements AuthService {
  final bodies = <Map<String, dynamic>>[];

  @override
  Future<void> completeProfile(Map<String, dynamic> body) async => bodies.add(body);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('_FakeAuthService.${invocation.memberName}');
}

class _RecordingAuth extends AuthNotifier {
  int completed = 0;
  final order = <String>[];

  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);

  @override
  Future<void> onProfileCompleted() async {
    completed++;
    order.add('onProfileCompleted');
  }
}

class _Rig {
  _Rig({this.city, bool citiesFail = false}) : cities = _Cities(fail: citiesFail) {
    nav.pushAnswer = city;
    AnalyticsManager.debugEventSink = (name, params) => events.add({'event': name, ...?params});
    AnalyticsForwarder.debugTrackSink = (name, category, metadata) => flowEvents.add({'event': name, ...?metadata});
    AnalyticsForwarder.instance.setEnabled(false);
  }

  final CityModel? city;
  final _Cities cities;
  final nav = FakeNavigationService();
  final location = FakeLocationManager();
  final auth = _FakeAuthService();
  final authNotifier = _RecordingAuth();
  final events = <Map<String, Object?>>[];
  final flowEvents = <Map<String, Object?>>[];

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() {
      AnalyticsManager.debugEventSink = null;
      AnalyticsForwarder.debugTrackSink = null;
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        navigationServiceProvider.overrideWithValue(nav),
        locationManagerProvider.overrideWithValue(location),
        cityRepositoryProvider.overrideWithValue(cities),
        authServiceProvider.overrideWithValue(auth),
        authProvider.overrideWith(() => authNotifier),
        userProvider.overrideWith(
          () => FixedUserNotifier(const UserModel(id: 'u1', email: 'u1@qulo.test', name: 'Ada')),
        ),
      ],
      child: MaterialApp(
        // InkSparkle shader'ı testte çözülemiyor.
        theme: AppTheme.dark.copyWith(splashFactory: NoSplash.splashFactory),
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: home,
      ),
    ));
    await tester.pump();
  }
}

void main() {
  group('RegisterStepLocation', () {
    Widget step({String? cityName, bool granted = false, VoidCallback? onPick, VoidCallback? onContinue}) =>
        Scaffold(
          body: RegisterStepLocation(
            locationGranted: granted,
            isRequesting: false,
            onRequestLocation: () {},
            onContinue: onContinue ?? () {},
            onPickCity: onPick ?? () {},
            selectedCityName: cityName,
          ),
        );

    Future<void> pumpStep(WidgetTester tester, Widget w) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        // InkSparkle shader'ı testte çözülemiyor.
        theme: AppTheme.dark.copyWith(splashFactory: NoSplash.splashFactory),
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: w,
      ));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('"Atla" yok; "Şehir seç" izinle eşit ağırlıkta, devam yok', (tester) async {
      var picked = 0;
      await pumpStep(tester, step(onPick: () => picked++));
      final ctx = tester.element(find.byType(RegisterStepLocation));

      expect(find.text(ctx.tr('location_skip')), findsNothing);
      expect(find.widgetWithText(AppButton, ctx.tr('enable_location')), findsOneWidget);
      expect(find.widgetWithText(AppButton, ctx.tr('continue_btn')), findsNothing);

      await tester.tap(find.widgetWithText(AppButton, ctx.tr('city_picker_choose_city')));
      expect(picked, 1);
    });

    testWidgets('şehir seçilince adı görünür ve devam açılır', (tester) async {
      var continued = 0;
      await pumpStep(tester, step(cityName: 'İstanbul', onContinue: () => continued++));
      final ctx = tester.element(find.byType(RegisterStepLocation));

      expect(find.text('İstanbul'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, ctx.tr('continue_btn')));
      expect(continued, 1);
      // Şehri değiştirmek mümkün kalır.
      expect(find.widgetWithText(AppButton, ctx.tr('city_picker_choose_city')), findsOneWidget);
    });
  });

  group('e-postalı kayıt (RegisterScreen)', () {
    Future<RegisterScreenMixin> pumpRegister(WidgetTester tester, _Rig rig) async {
      await rig.pump(tester, const RegisterScreen());
      return tester.state(find.byType(RegisterScreen)) as RegisterScreenMixin;
    }

    testWidgets('izin yok + şehir yok → konum adımı geçilemez', (tester) async {
      final rig = _Rig();
      final mixin = await pumpRegister(tester, rig);
      mixin.currentStep = 4;

      mixin.nextStep();
      await tester.pump(const Duration(milliseconds: 400));

      expect(mixin.validateCurrentStep(), isFalse);
      expect(mixin.currentStep, 4);
    });

    testWidgets('şehir seçici seçimsiz dönerse adımda kalınır', (tester) async {
      final rig = _Rig(); // pushAnswer null = geri dönüldü
      final mixin = await pumpRegister(tester, rig);
      mixin.currentStep = 4;

      await mixin.pickCity(AnalyticsEvents.sourceRegister);

      expect(rig.nav.pushes.single, (name: RouteNames.cityPicker, extra: true));
      expect(mixin.pickedCity, isNull);
      expect(mixin.validateCurrentStep(), isFalse);
      expect(rig.events, isEmpty);
    });

    testWidgets('şehir seçilince adım geçilir ve seçim olayı source ile atılır', (tester) async {
      final rig = _Rig(city: _istanbul);
      final mixin = await pumpRegister(tester, rig);
      mixin.currentStep = 4;

      await mixin.pickCity(AnalyticsEvents.sourceRegister);

      expect(mixin.pickedCity, _istanbul);
      expect(mixin.validateCurrentStep(), isTrue);
      expect(rig.events, [
        {'event': AnalyticsEvents.onboardingCitySelect, AnalyticsEvents.paramSource: 'register'},
      ]);
      // Hesap henüz yok: şehir bu aşamada sunucuya YAZILMAZ (yalnız seçim kipi).
      expect(rig.cities.saved, isEmpty);
    });

    testWidgets('izin verilirse seçili şehir düşer (GPS şehir merkezinin önüne geçer)', (tester) async {
      final rig = _Rig(city: _istanbul);
      final mixin = await pumpRegister(tester, rig);
      await mixin.pickCity(AnalyticsEvents.sourceRegister);
      expect(mixin.pickedCity, isNotNull);

      rig.location
        ..serviceEnabled = true
        ..permission = LocationPermissionStatus.granted;
      final pending = mixin.requestLocation();
      await tester.pump();
      rig.location.position.complete(const LocationResult(lat: 41.0, lng: 29.0));
      await pending;

      expect(mixin.locationGranted, isTrue);
      expect(mixin.pickedCity, isNull);
      expect(mixin.hasLocation, isTrue);
    });
  });

  group('sosyal giriş (ProfileCompletionScreen)', () {
    Future<ProfileCompletionMixin> pumpCompletion(WidgetTester tester, _Rig rig) async {
      await rig.pump(tester, const ProfileCompletionScreen());
      final mixin = tester.state(find.byType(ProfileCompletionScreen)) as ProfileCompletionMixin;
      mixin
        ..birthday = DateTime(1995, 5, 5)
        ..gender = 'WOMAN';
      return mixin;
    }

    testWidgets('konum yok + şehir yok → profil tamamlanmaz', (tester) async {
      final rig = _Rig();
      final mixin = await pumpCompletion(tester, rig);

      await mixin.completeProfile();

      expect(rig.auth.bodies, isEmpty);
      expect(rig.authNotifier.completed, 0);
    });

    testWidgets('şehir seçilince profil tamamlanır, şehir hesaba yazılır, sonra oturum bitirilir', (tester) async {
      final rig = _Rig(city: _istanbul);
      final mixin = await pumpCompletion(tester, rig);
      await mixin.pickCity(AnalyticsEvents.sourceProfileCompletion);

      await mixin.completeProfile();

      expect(rig.auth.bodies.single.containsKey('lat'), isFalse);
      expect(rig.cities.saved, ['TR-istanbul']);
      expect(rig.authNotifier.completed, 1);
      expect(rig.events.map((e) => e['event']), contains(AnalyticsEvents.onboardingCitySelect));
      expect(rig.flowEvents, [
        {
          'event': AnalyticsEvents.onboardingLocationResolved,
          AnalyticsEvents.paramSource: 'profile_completion',
          AnalyticsEvents.paramMethod: 'city',
        },
      ]);
    });

    testWidgets('şehir yazımı hata verirse profil yine tamamlanır ve hata kaydedilir', (tester) async {
      final rig = _Rig(city: _istanbul, citiesFail: true);
      final mixin = await pumpCompletion(tester, rig);
      await mixin.pickCity(AnalyticsEvents.sourceProfileCompletion);

      await mixin.completeProfile();

      expect(rig.cities.saved, ['TR-istanbul']);
      expect(rig.authNotifier.completed, 1);
      expect(
        rig.events.where((e) => e['event'] == AnalyticsEvents.onboardingCitySaveFail).single,
        {'event': AnalyticsEvents.onboardingCitySaveFail, AnalyticsEvents.paramSource: 'profile_completion'},
      );
    });
  });
}
