import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/constants/identity_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/profile_section_card.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/identity/widgets/edit_profile_gender_row.dart';
import 'package:qulo_v2/features/identity/widgets/edit_profile_identity_section.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/identity_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

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

void main() {
  final events = <Map<String, Object?>>[];
  setUp(() {
    events.clear();
    AnalyticsManager.debugEventSink = (name, params) => events.add({'event': name, ...?params});
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  testWidgets('boş: "henüz eklenmedi" + Ekle; switch yok', (tester) async {
    final h = await _pump(tester, const EditProfileIdentitySection());
    expect(find.text(h.tr('identity_none')), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('isteğe bağlı bölüm: tamamlanma rozeti (0/1, 1/1) hiç çizilmez', (tester) async {
    for (final identity in [
      IdentityModel.empty,
      const IdentityModel(orientationLabels: ['gay']),
    ]) {
      await _pump(tester, const EditProfileIdentitySection(), identity: identity);
      expect(
        tester.widget<ProfileSectionCard>(find.byType(ProfileSectionCard)).completionText,
        isNull,
      );
      expect(find.text('0/1'), findsNothing);
      expect(find.text('1/1'), findsNothing);
    }
  });

  testWidgets('kayıt sürerken Düzenle düğmesi devre dışı', (tester) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['bisexual']),
    );
    TextButton editButton() => tester.widget<TextButton>(
      find.ancestor(of: find.text(h.tr('identity_edit')), matching: find.byType(TextButton)),
    );
    expect(editButton().onPressed, isNotNull);

    final gate = Completer<void>();
    h.repo.identitySaveGate = gate;
    await tester.tap(find.text(h.tr('identity_show_orientation')));
    await tester.pump();
    expect(editButton().onPressed, isNull);
    gate.complete();
    await tester.pumpAndSettle();
    expect(editButton().onPressed, isNotNull);
  });

  testWidgets('Düzenle: sayfa açılamazsa (kimlik yeniden yüklenemedi) hata snackbar\'ı', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['gay']),
    );
    // Bölüm eldeki değeri göstermeye devam ederken yeniden okuma düşer.
    h.repo.identityGetFailure = const ServerFailure(code: 'X', statusCode: 500);
    final element = tester.element(find.byType(EditProfileIdentitySection));
    ProviderScope.containerOf(element).invalidate(identityProvider);
    await tester.pump();
    await tester.tap(find.text(h.tr('identity_edit')));
    await tester.pump();
    await tester.pump();
    expect(h.nav.sheets, isEmpty);
    expect(find.text(h.tr('error_general')), findsOneWidget);
  });

  testWidgets('dolu: etiket chip\'i ve yalnız dolu grubun switch\'i', (tester) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['bisexual']),
    );
    expect(find.text(h.tr(IdentityLabels.orientationKey('bisexual'))), findsOneWidget);
    expect(find.text(h.tr('identity_show_orientation')), findsOneWidget);
    expect(find.text(h.tr('identity_show_gender')), findsNothing);
  });

  testWidgets('görünürlük switch\'i: tek save {show açık, consent: true}', (tester) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['bisexual']),
    );
    await tester.tap(find.text(h.tr('identity_show_orientation')));
    await tester.pumpAndSettle();
    expect(h.repo.identityCalls.single, (
      identity: const IdentityModel(orientationLabels: ['bisexual'], showOrientationLabels: true),
      consent: true,
    ));
  });

  testWidgets('kayıt sürerken switch devre dışı (ikinci dokunuş yok sayılır)', (tester) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['bisexual']),
    );
    final gate = Completer<void>();
    h.repo.identitySaveGate = gate;
    await tester.tap(find.text(h.tr('identity_show_orientation')));
    await tester.pump();
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.onChanged, isNull);
    gate.complete();
    await tester.pumpAndSettle();
    expect(h.repo.identityCalls, hasLength(1));
  });

  testWidgets('kaydetme hatası: switch değişmez, hata snackbar\'da', (tester) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['bisexual']),
    );
    h.repo.identityFailure = const ServerFailure(code: 'X', statusCode: 500);
    await tester.tap(find.text(h.tr('identity_show_orientation')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('kimlik yüklenemedi: switch/düzenle yok, yeniden dene var', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test', gender: 'WOMAN'))
      ..identityGetFailure = const ServerFailure(code: 'X', statusCode: 500);
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(repo),
        navigationServiceProvider.overrideWithValue(FakeNavigationService()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(userProvider, (_, __) {});
    container.listen(identityProvider, (_, __) {});
    await container.read(userProvider.notifier).fetchMe();
    const home = EditProfileIdentitySection();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: SingleChildScrollView(child: home)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    String tr(String k) => tester.element(find.byWidget(home)).tr(k);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text(tr('identity_banner_add')), findsNothing);
    expect(find.text(tr('retry')), findsOneWidget);
    // Cinsiyet satırı kimlikten bağımsız kalır.
    expect(find.text(tr('woman')), findsOneWidget);
  });

  testWidgets('Etiketlerimi sil + onay: boş kayıt consent:false; iptalde çağrı yok', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['gay']),
    );
    await tester.tap(find.text(h.tr('identity_clear')));
    await tester.pumpAndSettle();
    expect(h.nav.dialogs, ['identity_clear']);
    expect(h.repo.identityCalls.single, (identity: IdentityModel.empty, consent: false));
    expect(events, [
      {'event': AnalyticsEvents.identityLabelsCleared, 'entry_point': 'edit_profile'},
    ]);

    final h2 = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['gay']),
      confirmAnswer: false,
    );
    await tester.tap(find.text(h2.tr('identity_clear')));
    await tester.pumpAndSettle();
    expect(h2.repo.identityCalls, isEmpty);
    expect(events, hasLength(1)); // iptalde yeni event yok
  });

  testWidgets('Düzenle: editör sheet açılır', (tester) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['gay']),
    );
    await tester.tap(find.text(h.tr('identity_edit')));
    await tester.pumpAndSettle();
    expect(h.nav.sheets, ['identity_editor']);
  });

  testWidgets('cinsiyet satırı + değişiklik talebi hazır konuyla destek formunu açar', (
    tester,
  ) async {
    final h = await _pump(tester, const EditProfileIdentitySection(), gender: 'WOMAN');
    expect(find.text(h.tr('woman')), findsOneWidget);
    await tester.tap(find.text(h.tr('gender_change_request')));
    await tester.pump();
    expect(h.nav.pushes.single, (
      name: RouteNames.createTicket,
      extra: h.tr('gender_change_ticket_subject'),
    ));
  });

  testWidgets('eski OTHER kullanıcı: "other" etiketi gösterilir', (tester) async {
    final h = await _pump(tester, const EditProfileIdentitySection(), gender: 'OTHER');
    expect(find.text(h.tr('other')), findsOneWidget);
  });

  testWidgets('yeniden dene sürerken hata satırı değil yükleniyor görünür', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test', gender: 'WOMAN'))
      ..identityGetFailure = const ServerFailure(code: 'X', statusCode: 500);
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(repo),
        navigationServiceProvider.overrideWithValue(FakeNavigationService()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(userProvider, (_, __) {});
    container.listen(identityProvider, (_, __) {});
    await container.read(userProvider.notifier).fetchMe();
    const home = EditProfileIdentitySection();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: SingleChildScrollView(child: home)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    String tr(String k) => tester.element(find.byWidget(home)).tr(k);

    final gate = Completer<void>();
    repo.identityGetGate = gate;
    await tester.tap(find.text(tr('retry')));
    await tester.pump();
    expect(find.text(tr('retry')), findsNothing);
    expect(find.byType(AppLoadingWidget), findsOneWidget);

    repo.identityGetFailure = null;
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text(tr('identity_none')), findsOneWidget);
  });

  testWidgets('Etiketlerimi sil: hızlı iki dokunuş tek onay diyaloğu açar', (tester) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['gay']),
    );
    final gate = Completer<void>();
    h.nav.dialogGate = gate;
    await tester.tap(find.text(h.tr('identity_clear')));
    await tester.pump();
    await tester.tap(find.text(h.tr('identity_clear')), warnIfMissed: false);
    await tester.pump();
    expect(h.nav.dialogs, ['identity_clear']);

    gate.complete();
    await tester.pumpAndSettle();
    expect(h.repo.identityCalls, hasLength(1));
  });

  testWidgets('Etiketlerimi sil: iptalde meşgul bayrağı düşer, tekrar denenebilir', (tester) async {
    final h = await _pump(
      tester,
      const EditProfileIdentitySection(),
      identity: const IdentityModel(orientationLabels: ['gay']),
      confirmAnswer: false,
    );
    await tester.tap(find.text(h.tr('identity_clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(h.tr('identity_clear')));
    await tester.pumpAndSettle();
    expect(h.nav.dialogs, ['identity_clear', 'identity_clear']);
    expect(h.repo.identityCalls, isEmpty);
  });

  testWidgets('kullanıcı yüklenmedi (cinsiyet null): cinsiyet satırı çizilmez, "Diğer" yok', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'));
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(repo),
        navigationServiceProvider.overrideWithValue(FakeNavigationService()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(identityProvider, (_, __) {});
    await container.read(identityProvider.future);
    const home = EditProfileIdentitySection();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: SingleChildScrollView(child: home)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    String tr(String k) => tester.element(find.byWidget(home)).tr(k);
    expect(find.byType(EditProfileGenderRow), findsNothing);
    expect(find.text(tr('other')), findsNothing);
    expect(find.text(tr('identity_none')), findsOneWidget);
  });
}
