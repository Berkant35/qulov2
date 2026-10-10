import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/pref_consent/widgets/gender_pref_consent_actions.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_preferences_section.dart';
import 'package:qulo_v2/features/settings/screens/create_ticket_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

import '../../helpers/fake_repositories.dart';

/// Onay penceresini [confirmAnswer] ile yanıtlar, `push` çağrılarını kaydeder.
class _FakeNavigationService implements NavigationService {
  _FakeNavigationService({this.confirmAnswer = true});

  final bool confirmAnswer;
  final dialogs = <String>[];
  final pushes = <({String name, Object? extra})>[];

  @override
  Future<T?> showAppDialog<T>(AppDialog dialog) async {
    dialogs.add(dialog.name);
    return confirmAnswer as T;
  }

  @override
  Future<T?> push<T>(String name, {Map<String, String>? params, Object? extra}) async {
    pushes.add((name: name, extra: extra));
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNavigationService.${invocation.memberName}');
}

Widget _app(ProviderContainer container, Widget home) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: home),
      ),
    );

Future<({FakeUserRepository users, _FakeNavigationService nav, BuildContext Function() context})> _pump(
  WidgetTester tester, {
  UserModel? user,
  bool confirmAnswer = true,
}) async {
  final users = FakeUserRepository(
    user ?? UserModel(id: 'u1', email: 'u1@qulo.test', genderPrefSetAt: DateTime.utc(2026, 9, 1)),
  );
  final nav = _FakeNavigationService(confirmAnswer: confirmAnswer);
  final container = ProviderContainer(overrides: [
    userRepositoryProvider.overrideWithValue(users),
    navigationServiceProvider.overrideWithValue(nav),
  ]);
  addTearDown(container.dispose);
  // Riverpod 3 izlenmeyen provider'ı duraklatır.
  container.listen(userProvider, (_, __) {});
  await container.read(userProvider.notifier).fetchMe();

  await tester.pumpWidget(_app(container, const GenderPrefConsentActions()));
  await tester.pump();
  return (
    users: users,
    nav: nav,
    context: () => tester.element(find.byType(GenderPrefConsentActions)),
  );
}

/// Sunucu gibi davranır: rıza reddedilince sonraki getMe tercihsiz + DECLINED kullanıcıyı döner.
class _DecliningUserRepository extends FakeUserRepository {
  _DecliningUserRepository(super.user);

  @override
  Future<Result<void>> setPrefConsent({required String status, String? genderPref}) async {
    final result = await super.setPrefConsent(status: status, genderPref: genderPref);
    if (result is Success && status == PrefConsent.declined) {
      user = UserModel(
        id: user.id,
        email: user.email,
        prefConsentStatus: PrefConsent.declined,
      );
    }
    return result;
  }
}

void main() {
  final setAt = DateTime.utc(2026, 9, 1);

  Finder withdrawButton(BuildContext Function() ctx) =>
      find.widgetWithText(TextButton, ctx().tr('pref_consent_withdraw'));
  Finder requestButton(BuildContext Function() ctx) =>
      find.widgetWithText(TextButton, ctx().tr('gender_pref_request_change'));

  group('"Rızamı geri al" görünürlüğü', () {
    final cases = <String, ({UserModel user, bool visible})>{
      'tercih kayıtlı + rıza GRANTED': (
        user: UserModel(
          id: 'u1',
          email: 'u1@qulo.test',
          genderPrefSetAt: setAt,
          prefConsentStatus: PrefConsent.granted,
        ),
        visible: true,
      ),
      'tercih kayıtlı + rıza henüz yok (null)': (
        user: UserModel(id: 'u1', email: 'u1@qulo.test', genderPrefSetAt: setAt),
        visible: true,
      ),
      'rıza DECLINED': (
        user: UserModel(
          id: 'u1',
          email: 'u1@qulo.test',
          genderPrefSetAt: setAt,
          prefConsentStatus: PrefConsent.declined,
        ),
        visible: false,
      ),
      'tercih hiç kaydedilmemiş (genderPrefSetAt yok)': (
        user: UserModel(id: 'u1', email: 'u1@qulo.test'),
        visible: false,
      ),
    };
    cases.forEach((name, c) {
      testWidgets(name, (tester) async {
        final h = await _pump(tester, user: c.user);
        expect(withdrawButton(h.context), c.visible ? findsOneWidget : findsNothing);
        // "Değişiklik talebi" her durumda var.
        expect(requestButton(h.context), findsOneWidget);
      });
    });
  });

  testWidgets('geri al + onay → tek çağrı DECLINED, tercih gönderilmez', (tester) async {
    final h = await _pump(tester);

    await tester.tap(withdrawButton(h.context));
    await tester.pumpAndSettle();

    expect(h.nav.dialogs, ['pref_consent_withdraw']);
    expect(h.users.prefConsentCalls, [(status: PrefConsent.declined, genderPref: null)]);
  });

  testWidgets('geri al + vazgeç → çağrı yok', (tester) async {
    final h = await _pump(tester, confirmAnswer: false);

    await tester.tap(withdrawButton(h.context));
    await tester.pumpAndSettle();

    expect(h.nav.dialogs, ['pref_consent_withdraw']);
    expect(h.users.prefConsentCalls, isEmpty);
  });

  testWidgets('"Değişiklik talebi" → createTicket rotası, extra = çevrilmiş hazır konu', (tester) async {
    final h = await _pump(tester);

    await tester.tap(requestButton(h.context));
    await tester.pumpAndSettle();

    expect(h.nav.pushes, [
      (name: RouteNames.createTicket, extra: h.context().tr('gender_pref_ticket_subject')),
    ]);
    expect(h.nav.pushes.single.extra, isA<String>());
    expect(h.nav.pushes.single.extra as String, isNotEmpty);
  });

  group('CreateTicketScreen.initialSubject', () {
    Future<TextEditingController> pumpTicket(WidgetTester tester, {String? subject}) async {
      final container = ProviderContainer(overrides: [
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test')),
        ),
        navigationServiceProvider.overrideWithValue(_FakeNavigationService()),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(_app(container, CreateTicketScreen(initialSubject: subject)));
      await tester.pump();
      final subjectField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      return subjectField.controller!;
    }

    testWidgets('verilince konu alanı dolu gelir', (tester) async {
      final ctrl = await pumpTicket(tester, subject: 'X');
      expect(ctrl.text, 'X');
      expect(find.text('X'), findsOneWidget);
    });

    testWidgets('verilmezse konu alanı boş', (tester) async {
      final ctrl = await pumpTicket(tester);
      expect(ctrl.text, isEmpty);
    });
  });

  testWidgets('düzenleme ekranı: rıza geri alınınca etiket "saklanmıyor"a döner, geri al düğmesi kaybolur',
      (tester) async {
    final users = _DecliningUserRepository(UserModel(
      id: 'u1',
      email: 'u1@qulo.test',
      genderPref: 'WOMAN',
      genderPrefSetAt: setAt,
      prefConsentStatus: PrefConsent.granted,
    ));
    final container = ProviderContainer(overrides: [
      userRepositoryProvider.overrideWithValue(users),
      navigationServiceProvider.overrideWithValue(_FakeNavigationService()),
    ]);
    addTearDown(container.dispose);
    container.listen(userProvider, (_, __) {});
    await container.read(userProvider.notifier).fetchMe();

    await tester.pumpWidget(_app(
      container,
      const SingleChildScrollView(child: EditProfilePreferencesSection(completionText: '4/4')),
    ));
    await tester.pump();
    final ctx = tester.element(find.byType(EditProfilePreferencesSection));
    final withdraw = find.widgetWithText(TextButton, ctx.tr('pref_consent_withdraw'));

    expect(find.text(ctx.tr('women')), findsOneWidget);
    expect(find.text(ctx.tr('gender_pref_not_stored')), findsNothing);
    expect(withdraw, findsOneWidget);

    await tester.ensureVisible(withdraw);
    await tester.pump();
    await tester.tap(withdraw);
    await tester.pumpAndSettle();

    expect(users.prefConsentCalls, [(status: PrefConsent.declined, genderPref: null)]);
    expect(find.text(ctx.tr('gender_pref_not_stored')), findsOneWidget);
    expect(find.text(ctx.tr('women')), findsNothing);
    expect(withdraw, findsNothing);
  });
}
