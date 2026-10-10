import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/pref_consent/widgets/pref_consent_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../helpers/fake_repositories.dart';

/// Onay penceresini [confirmAnswer] ile yanıtlar, `pop` ve `push` çağrılarını kaydeder.
class _FakeNavigationService implements NavigationService {
  _FakeNavigationService({required this.confirmAnswer});

  final bool confirmAnswer;
  final dialogs = <String>[];
  int pops = 0;

  @override
  Future<T?> showAppDialog<T>(AppDialog dialog) async {
    dialogs.add(dialog.name);
    return confirmAnswer as T;
  }

  @override
  void pop<T>([T? result]) => pops++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNavigationService.${invocation.memberName}');
}

typedef _Harness = ({
  FakeUserRepository users,
  _FakeNavigationService nav,
  List<String> events,
  BuildContext Function() context,
});

Future<_Harness> _pump(
  WidgetTester tester, {
  bool confirmAnswer = true,
  AppFailure? failure,
  Size size = const Size(375, 667),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final users = FakeUserRepository(
    UserModel(id: 'u1', email: 'u1@qulo.test', genderPrefSetAt: DateTime.utc(2026, 9, 1)),
  )..prefConsentFailure = failure;
  final nav = _FakeNavigationService(confirmAnswer: confirmAnswer);
  final events = <String>[];
  AnalyticsManager.debugEventSink = (name, params) => events.add('$name:${params?['consent']}');
  addTearDown(() => AnalyticsManager.debugEventSink = null);

  final container = ProviderContainer(overrides: [
    userRepositoryProvider.overrideWithValue(users),
    navigationServiceProvider.overrideWithValue(nav),
  ]);
  addTearDown(container.dispose);
  // Riverpod 3 izlenmeyen provider'ı duraklatır; sayfa userProvider.notifier'ı okur.
  container.listen(userProvider, (_, __) {});
  await container.read(userProvider.notifier).fetchMe();

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      // Gerçek sayfa gibi Scaffold'suz: hata snackbar'ına güvenilemeyeceğini test de bilir.
      home: const Material(child: PrefConsentSheet()),
    ),
  ));
  await tester.pump();
  return (
    users: users,
    nav: nav,
    events: events,
    context: () => tester.element(find.byType(PrefConsentSheet)),
  );
}

void main() {
  Finder acceptButton(_Harness h) =>
      find.widgetWithText(AppButton, h.context().tr('pref_consent_accept'));
  Finder rejectButton(_Harness h) =>
      find.widgetWithText(TextButton, h.context().tr('pref_consent_reject'));

  testWidgets('"Rıza veriyorum" → tek çağrı GRANTED, tercih gönderilmez, sayfa kapanır', (tester) async {
    final h = await _pump(tester);

    await tester.tap(acceptButton(h));
    await tester.pumpAndSettle();

    expect(h.users.prefConsentCalls, [(status: PrefConsent.granted, genderPref: null)]);
    expect(h.nav.dialogs, isEmpty);
    expect(h.nav.pops, 1);
    expect(h.events, ['${AnalyticsEvents.prefConsentAnswered}:granted']);
  });

  testWidgets('"Rıza vermiyorum" + onay → tek çağrı DECLINED, tercih gönderilmez', (tester) async {
    final h = await _pump(tester);

    await tester.tap(rejectButton(h));
    await tester.pumpAndSettle();

    expect(h.nav.dialogs, ['pref_consent_decline']);
    expect(h.users.prefConsentCalls, [(status: PrefConsent.declined, genderPref: null)]);
    expect(h.nav.pops, 1);
    expect(h.events, ['${AnalyticsEvents.prefConsentAnswered}:declined']);
  });

  testWidgets('"Rıza vermiyorum" + vazgeç → çağrı yok, sayfa açık kalır', (tester) async {
    final h = await _pump(tester, confirmAnswer: false);

    await tester.tap(rejectButton(h));
    await tester.pumpAndSettle();

    expect(h.nav.dialogs, ['pref_consent_decline']);
    expect(h.users.prefConsentCalls, isEmpty);
    expect(h.nav.pops, 0);
    expect(h.events, isEmpty);
    expect(find.byType(PrefConsentSheet), findsOneWidget);
  });

  testWidgets('sunucu hatası → pop yok, olay yok, hata sayfa İÇİNDE görünür, yeni denemede temizlenir',
      (tester) async {
    final h = await _pump(tester, failure: const NetworkFailure());

    await tester.tap(acceptButton(h));
    await tester.pumpAndSettle();

    expect(h.users.prefConsentCalls, hasLength(1));
    expect(h.nav.pops, 0);
    expect(h.events, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    final inlineError = find.descendant(
      of: find.byType(PrefConsentSheet),
      matching: find.text(h.context().tr('error_no_connection')),
    );
    expect(inlineError, findsOneWidget);
    expect(tester.widget<AppButton>(acceptButton(h)).onPressed, isNotNull);

    // Yeni deneme başlayınca eski hata silinir (başarılı olsa da olmasa da).
    h.users.prefConsentFailure = null;
    await tester.tap(acceptButton(h));
    await tester.pumpAndSettle();
    expect(inlineError, findsNothing);
    expect(h.nav.pops, 1);
  });

  testWidgets('375x200 + yazı 1.5x: taşma yok, iki düğme kaydırınca erişilir ve çalışır', (tester) async {
    final h = await _pump(tester, size: const Size(375, 200), textScale: 1.5);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(rejectButton(h));
    await tester.pump();
    await tester.tap(rejectButton(h));
    await tester.pumpAndSettle();
    expect(h.users.prefConsentCalls, [(status: PrefConsent.declined, genderPref: null)]);

    await tester.ensureVisible(acceptButton(h));
    await tester.pump();
    await tester.tap(acceptButton(h));
    await tester.pumpAndSettle();
    expect(h.users.prefConsentCalls.last, (status: PrefConsent.granted, genderPref: null));
    expect(tester.takeException(), isNull);
  });
}
