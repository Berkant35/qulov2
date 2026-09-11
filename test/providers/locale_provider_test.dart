import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
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
  testWidgets('cihaz dil listesi boşsa İngilizce, bölgesiz', (tester) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(localeProvider);
    await tester.pumpAndSettle();

    final locale = container.read(localeProvider);
    expect(locale, const Locale('en'));
    expect(locale.countryCode, isNull);
  });

  testWidgets('cihaz bölge kodu yoksa dil bölgesiz kalır', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(localeProvider);
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), const Locale('tr'));
    expect(container.read(localeProvider).countryCode, isNull);
  });

  testWidgets('secilen dil yeniden acilista geri gelir — yazilan anahtar okunanla ayni', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final first = ProviderContainer();
    await first.read(localeProvider.notifier).setLocale(const Locale('fr'));
    first.dispose();

    final second = ProviderContainer();
    addTearDown(second.dispose);
    second.read(localeProvider);
    await tester.pumpAndSettle();

    expect(second.read(localeProvider), const Locale('fr', 'US'));
  });

  testWidgets('cihazin ilk DESTEKLENEN dili secilir; bolge ilk cihaz locale\'inden', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('xx', 'ZZ'), Locale('de', 'DE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(localeProvider);
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), const Locale('de', 'ZZ'));
  });

  testWidgets('hicbir cihaz dili desteklenmiyorsa Ingilizce — Turkce DEGIL (yurt disi hatasi)', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('xx', 'ZZ')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(localeProvider);
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), const Locale('en', 'ZZ'));
  });

  for (final (status, expected) in [
    (AuthStatus.authenticated, [
      {'locale': 'de'},
    ]),
    (AuthStatus.unauthenticated, <Map<String, dynamic>>[]),
  ]) {
    testWidgets('dil degisimi sunucuya: ${status.name} → ${expected.length} istek, yalniz dil kodu',
        (tester) async {
      // Bildirim/e-posta dili sunucudaki `locale`'den (notification locale sync).
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      SharedPreferences.setMockInitialValues({});
      final users = _RecordingUserRepository();
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(() => _SeededAuthNotifier(status)),
        userRepositoryProvider.overrideWithValue(users),
      ]);
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('de', 'AT'));

      expect(users.updates, expected);
    });
  }
}

class _SeededAuthNotifier extends AuthNotifier {
  _SeededAuthNotifier(this._status);
  final AuthStatus _status;

  @override
  AuthState build() => AuthState(status: _status);
}

class _RecordingUserRepository implements UserRepository {
  final updates = <Map<String, dynamic>>[];

  @override
  Future<Result<UserModel>> updateProfile(Map<String, dynamic> data) async {
    updates.add(data);
    return const Failure(NetworkFailure());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_RecordingUserRepository.${invocation.memberName}');
}
