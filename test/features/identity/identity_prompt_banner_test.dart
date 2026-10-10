import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/one_time_flag_store.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/identity/widgets/identity_prompt_banner.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/identity_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/core/network/result.dart';

import '../../helpers/fake_navigation.dart';
import '../../helpers/fake_repositories.dart';

typedef _H = ({FakeUserRepository repo, FakeNavigationService nav, String Function(String) tr});

Future<_H> _pump(
  WidgetTester tester,
  Widget home, {
  IdentityModel identity = IdentityModel.empty,
  String gender = 'WOMAN',
  bool confirmAnswer = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test', gender: gender))
    ..identity = identity;
  final nav = FakeNavigationService(confirmAnswer: confirmAnswer);
  final container = ProviderContainer(
    overrides: [
      userRepositoryProvider.overrideWithValue(repo),
      navigationServiceProvider.overrideWithValue(nav),
    ],
  );
  addTearDown(container.dispose);
  container.listen(userProvider, (_, __) {});
  container.listen(identityProvider, (_, __) {});
  await container.read(userProvider.notifier).fetchMe();
  await container.read(identityProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: SingleChildScrollView(child: home)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final ctx = tester.element(find.byWidget(home));
  return (repo: repo, nav: nav, tr: (String k) => ctx.tr(k));
}

/// Profil ekranındaki gibi: kullanıcı yüklü bir kapsayıcı (banner bayrağı kullanıcıya özel).
Future<ProviderContainer> _container(FakeUserRepository repo, {FakeNavigationService? nav}) async {
  final container = ProviderContainer(
    overrides: [
      userRepositoryProvider.overrideWithValue(repo),
      if (nav != null) navigationServiceProvider.overrideWithValue(nav),
    ],
  );
  addTearDown(container.dispose);
  container.listen(userProvider, (_, __) {});
  await container.read(userProvider.notifier).fetchMe();
  return container;
}

void main() {
  testWidgets('kimlik boş + kapatılmamış: görünür', (tester) async {
    final h = await _pump(tester, const IdentityPromptBanner());
    expect(find.text(h.tr('identity_banner_text')), findsOneWidget);
  });

  testWidgets('kimlik dolu: görünmez', (tester) async {
    final h = await _pump(
      tester,
      const IdentityPromptBanner(),
      identity: const IdentityModel(orientationLabels: ['gay']),
    );
    expect(find.text(h.tr('identity_banner_text')), findsNothing);
  });

  testWidgets('kapat: gizlenir ve cihazda hatırlanır', (tester) async {
    final h = await _pump(tester, const IdentityPromptBanner());
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text(h.tr('identity_banner_text')), findsNothing);
    expect(await OneTimeFlagStore.isSet('identity_prompt_dismissed_u1'), isTrue);
    expect(
      await OneTimeFlagStore.isSet('identity_prompt_dismissed'),
      isFalse,
      reason: 'cihaz geneli anahtar yazılmaz',
    );
  });

  testWidgets('daha önce kapatılmış: görünmez', (tester) async {
    SharedPreferences.setMockInitialValues({'identity_prompt_dismissed_u1': true});
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'));
    final container = await _container(repo);
    container.listen(identityProvider, (_, __) {});
    await container.read(identityProvider.future);
    const home = IdentityPromptBanner();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: home),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byWidget(home));
    expect(find.text(ctx.tr('identity_banner_text')), findsNothing);
  });

  testWidgets('kapatmış kullanıcı: kimlik GET\'i hiç tetiklenmez (maliyet koruması)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'identity_prompt_dismissed_u1': true});
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'));
    final container = await _container(repo);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: IdentityPromptBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.identityGetCount, 0);
  });

  testWidgets('kimlik yüklenirken banner görünmez; yüklenince görünür', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final gate = Completer<void>();
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'))
      ..identityGetGate = gate;
    final container = await _container(repo);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: IdentityPromptBanner()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final ctx = tester.element(find.byType(IdentityPromptBanner));
    expect(repo.identityGetCount, 1); // yükleme gerçekten sürüyor
    expect(find.text(ctx.tr('identity_banner_text')), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text(ctx.tr('identity_banner_text')), findsOneWidget);
  });

  testWidgets('kimlik yüklenemedi: banner görünmez, hata sızmaz', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'))
      ..identityGetFailure = const ServerFailure(code: 'X', statusCode: 500);
    final container = await _container(repo);
    container.listen(identityProvider, (_, __) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: IdentityPromptBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(IdentityPromptBanner));
    expect(repo.identityGetCount, 1);
    expect(find.text(ctx.tr('identity_banner_text')), findsNothing);

    // Aynı kurulum hata olmadan banner'ı gösterir: yukarıdaki iddia gerçekten hataya bağlı.
    repo.identityGetFailure = null;
    container.invalidate(identityProvider);
    await tester.pumpAndSettle();
    expect(find.text(ctx.tr('identity_banner_text')), findsOneWidget);
  });

  testWidgets('Ekle: editör sheet açılır', (tester) async {
    final h = await _pump(tester, const IdentityPromptBanner());
    await tester.tap(find.text(h.tr('identity_banner_add')));
    await tester.pump();
    expect(h.nav.sheets, ['identity_editor']);
  });

  testWidgets('A kapattı: A hâlâ görmez, B (aynı cihaz) banner\'ı görür', (tester) async {
    SharedPreferences.setMockInitialValues({'identity_prompt_dismissed_u1': true});
    for (final (id, visible) in [('u1', false), ('u2', true)]) {
      final repo = FakeUserRepository(UserModel(id: id, email: '$id@qulo.test'));
      final container = await _container(repo);
      container.listen(identityProvider, (_, __) {});
      await container.read(identityProvider.future);
      await tester.pumpWidget(const SizedBox()); // önceki kullanıcının ağacı sökülür
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: const [AppLocalizationsDelegate()],
            supportedLocales: const [Locale('en')],
            locale: const Locale('en'),
            home: const Scaffold(body: IdentityPromptBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(IdentityPromptBanner));
      expect(
        find.text(ctx.tr('identity_banner_text')),
        visible ? findsOneWidget : findsNothing,
        reason: 'kullanıcı $id',
      );
    }
  });

  testWidgets('Ekle: sayfa açılamazsa genel hata snackbar\'ı', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'));
    final nav = FakeNavigationService();
    final container = await _container(repo, nav: nav);
    container.listen(identityProvider, (_, __) {});
    await container.read(identityProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: IdentityPromptBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(IdentityPromptBanner));
    // Banner eldeki (boş) değerle görünürken yeniden okuma düşer.
    repo.identityGetFailure = const ServerFailure(code: 'X', statusCode: 500);
    container.invalidate(identityProvider);
    await tester.pump();
    await tester.tap(find.text(ctx.tr('identity_banner_add')));
    await tester.pump();
    await tester.pump();
    expect(nav.sheets, isEmpty);
    expect(find.text(ctx.tr('error_general')), findsOneWidget);
  });
}
