import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/identity_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/identity/widgets/identity_editor_sheet.dart';
import 'package:qulo_v2/features/pref_consent/widgets/pref_consent_checkbox.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/identity_provider.dart';

import '../../helpers/fake_navigation.dart';
import '../../helpers/fake_repositories.dart';

typedef _H = ({FakeUserRepository repo, FakeNavigationService nav, String Function(String) tr});

Future<_H> _pump(
  WidgetTester tester, {
  IdentityModel initial = IdentityModel.empty,
  Size? size,
  double textScale = 1,
  bool confirmAnswer = true,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'))..identity = initial;
  final nav = FakeNavigationService(confirmAnswer: confirmAnswer);
  final container = ProviderContainer(
    overrides: [
      userRepositoryProvider.overrideWithValue(repo),
      navigationServiceProvider.overrideWithValue(nav),
    ],
  );
  addTearDown(container.dispose);
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Material(child: IdentityEditorSheet(entryPoint: 'profile_banner')),
      ),
    ),
  );
  await tester.pump();
  final ctx = tester.element(find.byType(IdentityEditorSheet));
  return (repo: repo, nav: nav, tr: (String k) => ctx.tr(k));
}

/// Sayfa kaydırılabilir; ekran dışındaki çip/kutu için önce görünür yap.
Future<void> _tapText(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
}

Future<void> _tapSave(WidgetTester tester, _H h) async {
  final save = find.text(h.tr('identity_save'));
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pump();
}

void main() {
  late List<Map<String, Object?>> events;
  setUp(() {
    events = [];
    AnalyticsManager.debugEventSink = (name, params) => events.add({'event': name, ...?params});
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  testWidgets('boş kimlik: etiket seçince rıza kutusu çıkar, işaretsizken Kaydet çağrı yapmaz', (
    tester,
  ) async {
    final h = await _pump(tester);
    expect(find.byType(PrefConsentCheckbox), findsNothing);
    await _tapText(tester, h.tr(IdentityLabels.orientationKey('gay')));
    await tester.pump();
    expect(find.byType(PrefConsentCheckbox), findsOneWidget);
    await _tapSave(tester, h);
    expect(h.repo.identityCalls, isEmpty);
  });

  testWidgets(
    'rıza işaretli: tek save {katalog sırasında etiketler, consent: true}, kapanır, değersiz event',
    (tester) async {
      final h = await _pump(tester);
      await _tapText(tester, h.tr(IdentityLabels.orientationKey('queer')));
      await _tapText(tester, h.tr(IdentityLabels.orientationKey('bisexual')));
      await tester.pump();
      await _tapText(tester, h.tr('identity_consent_checkbox'));
      await tester.pump();
      await _tapSave(tester, h);
      expect(h.repo.identityCalls.single, (
        identity: const IdentityModel(orientationLabels: ['bisexual', 'queer']),
        consent: true,
      ));
      expect(h.nav.pops, 1);
      expect(events, [
        {'event': AnalyticsEvents.identityLabelsSaved, 'entry_point': 'profile_banner'},
      ]);
    },
  );

  testWidgets('grup başına 4. seçim eklenmez, uyarı görünür', (tester) async {
    final h = await _pump(tester);
    for (final k in ['gay', 'queer', 'bisexual', 'pansexual']) {
      final chip = find.text(h.tr(IdentityLabels.orientationKey(k)));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
    }
    expect(find.text(h.tr('identity_max_reached')), findsOneWidget);
    await _tapText(tester, h.tr('identity_consent_checkbox'));
    await tester.pump();
    await _tapSave(tester, h);
    expect(h.repo.identityCalls.single.identity.orientationLabels, ['gay', 'bisexual', 'queer']);
  });

  testWidgets('mevcut etiketi olan kullanıcı: rıza kutusu yok, Kaydet consent:true', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      initial: const IdentityModel(orientationLabels: ['gay'], showOrientationLabels: true),
    );
    expect(find.byType(PrefConsentCheckbox), findsNothing);
    await _tapText(tester, h.tr(IdentityLabels.genderKey('cis_man')));
    await tester.pump();
    expect(find.byType(PrefConsentCheckbox), findsNothing);
    await _tapSave(tester, h);
    expect(h.repo.identityCalls.single, (
      identity: const IdentityModel(
        genderLabels: ['cis_man'],
        orientationLabels: ['gay'],
        showOrientationLabels: true,
      ),
      consent: true,
    ));
  });

  testWidgets('tüm seçimleri kaldırıp Kaydet: consent:false boş kayıt (silme) + cleared event', (
    tester,
  ) async {
    final h = await _pump(tester, initial: const IdentityModel(orientationLabels: ['gay']));
    await _tapText(tester, h.tr(IdentityLabels.orientationKey('gay')));
    await tester.pump();
    await _tapSave(tester, h);
    expect(h.nav.dialogs, ['identity_clear']);
    expect(h.repo.identityCalls.single, (identity: IdentityModel.empty, consent: false));
    expect(events, [
      {'event': AnalyticsEvents.identityLabelsCleared, 'entry_point': 'profile_banner'},
    ]);
  });

  testWidgets('sunucu hatası: kapanmaz, satır içi hata', (tester) async {
    final h = await _pump(tester, initial: const IdentityModel(orientationLabels: ['gay']));
    h.repo.identityFailure = const ServerFailure(code: 'SERVER_ERROR', statusCode: 500);
    await _tapText(tester, h.tr(IdentityLabels.orientationKey('queer')));
    await tester.pump();
    await _tapSave(tester, h);
    expect(h.nav.pops, 0);
    expect(find.text(h.tr('error_general')), findsOneWidget);
  });

  testWidgets('375x667 @1.3: taşma yok, Kaydet ulaşılabilir', (tester) async {
    final h = await _pump(
      tester,
      size: const Size(375, 667),
      textScale: 1.3,
      initial: const IdentityModel(orientationLabels: ['gay']),
    );
    expect(tester.takeException(), isNull);
    await _tapSave(tester, h);
    expect(tester.takeException(), isNull);
    expect(h.repo.identityCalls, hasLength(1));
  });

  testWidgets('etiketsiz + seçimsiz: Kaydet kapalı, repo çağrılmaz, cleared event yok', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _tapSave(tester, h);
    expect(h.repo.identityCalls, isEmpty);
    expect(h.nav.pops, 0);
    expect(events, isEmpty);
    final button = tester.widget<AppButton>(find.widgetWithText(AppButton, h.tr('identity_save')));
    expect(button.onPressed, isNull);
  });

  testWidgets('silme: onay iptal → çağrı yok, sayfa açık; onay → clear + cleared event', (
    tester,
  ) async {
    final cancel = await _pump(
      tester,
      initial: const IdentityModel(orientationLabels: ['gay']),
      confirmAnswer: false,
    );
    await _tapText(tester, cancel.tr(IdentityLabels.orientationKey('gay')));
    await tester.pump();
    await _tapSave(tester, cancel);
    await tester.pump();
    expect(cancel.nav.dialogs, ['identity_clear']);
    expect(cancel.repo.identityCalls, isEmpty);
    expect(cancel.nav.pops, 0);
    expect(events, isEmpty);
    expect(find.byType(IdentityEditorSheet), findsOneWidget);
  });

  testWidgets('silme onayı: clear çağrısı tek, sayfa kapanır', (tester) async {
    final h = await _pump(
      tester,
      initial: const IdentityModel(genderLabels: ['agender'], showGenderLabels: true),
    );
    await _tapText(tester, h.tr(IdentityLabels.genderKey('agender')));
    await tester.pump();
    await _tapSave(tester, h);
    await tester.pump();
    expect(h.nav.dialogs, ['identity_clear']);
    expect(h.repo.identityCalls.single, (identity: IdentityModel.empty, consent: false));
    expect(h.nav.pops, 1);
  });

  testWidgets('seçimler boşalınca rıza işareti sıfırlanır (KVKK: kutu hep işaretsiz başlar)', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _tapText(tester, h.tr(IdentityLabels.orientationKey('gay')));
    await tester.pump();
    await _tapText(tester, h.tr('identity_consent_checkbox'));
    await tester.pump();
    expect(tester.widget<PrefConsentCheckbox>(find.byType(PrefConsentCheckbox)).value, isTrue);
    await _tapText(tester, h.tr(IdentityLabels.orientationKey('gay')));
    await tester.pump();
    expect(find.byType(PrefConsentCheckbox), findsNothing);
    await _tapText(tester, h.tr(IdentityLabels.orientationKey('queer')));
    await tester.pump();
    expect(tester.widget<PrefConsentCheckbox>(find.byType(PrefConsentCheckbox)).value, isFalse);
  });

  testWidgets('sınır mesajı limite çarpan grubun altında (yönelim)', (tester) async {
    final h = await _pump(tester);
    for (final k in ['gay', 'queer', 'bisexual', 'pansexual']) {
      await _tapText(tester, h.tr(IdentityLabels.orientationKey(k)));
      await tester.pump();
    }
    final message = find.text(h.tr('identity_max_reached'));
    expect(message, findsOneWidget);
    final lastOrientationChip = tester.getBottomLeft(
      find.text(h.tr(IdentityLabels.orientationKey('homoflexible'))),
    );
    final genderTitle = tester.getTopLeft(find.text(h.tr('identity_group_gender')));
    final messageTop = tester.getTopLeft(message).dy;
    expect(messageTop, greaterThan(lastOrientationChip.dy));
    expect(messageTop, lessThan(genderTitle.dy));
  });

  testWidgets('sınır mesajı limite çarpan grubun altında (kimlik)', (tester) async {
    final h = await _pump(tester);
    for (final k in ['cis_man', 'trans_man', 'agender', 'bigender']) {
      await _tapText(tester, h.tr(IdentityLabels.genderKey(k)));
      await tester.pump();
    }
    final message = find.text(h.tr('identity_max_reached'));
    expect(message, findsOneWidget);
    // "questioning" iki grupta da aynı metin (ör. "Questioning"); kimlik grubu yönelimden sonra
    // çizildiği için son eşleşme kimlik çipidir.
    final lastGenderChip = tester.getBottomLeft(
      find.text(h.tr(IdentityLabels.genderKey('questioning'))).last,
    );
    expect(tester.getTopLeft(message).dy, greaterThan(lastGenderChip.dy));
  });

  testWidgets('kaydederken çip dokunuşları yok sayılır', (tester) async {
    final h = await _pump(tester, initial: const IdentityModel(orientationLabels: ['gay']));
    final gate = Completer<void>();
    h.repo.identitySaveGate = gate;
    await _tapText(tester, h.tr(IdentityLabels.orientationKey('queer')));
    await tester.pump();
    await _tapSave(tester, h);
    await _tapText(tester, h.tr(IdentityLabels.orientationKey('bisexual')));
    await tester.pump();
    final bisexual = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, h.tr(IdentityLabels.orientationKey('bisexual'))),
    );
    expect(bisexual.selected, isFalse);
    gate.complete();
    await tester.pump();
    expect(h.repo.identityCalls.single.identity.orientationLabels, ['gay', 'queer']);
  });

  testWidgets('sayfa içeriği SafeArea içinde (alt güvenli alan)', (tester) async {
    await _pump(tester);
    expect(
      find.descendant(of: find.byType(IdentityEditorSheet), matching: find.byType(SafeArea)),
      findsOneWidget,
    );
  });
}
