import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/services/pending_languages_store.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/onboarding/screens/onboarding_screen.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_diamonds_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_indicators.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_powers_page.dart';
import 'package:qulo_v2/features/power_demo/data/power_demo_outcome_store.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_outcome.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_view.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_finale.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/onboarding_seen_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_navigation.dart';
import '../../helpers/power_demo_driver.dart';

/// Tanıtım carousel'inin Güçler sayfası: sunucu anahtarı açıksa interaktif demo, kapalıysa
/// eski statik ızgara. Demonun kendi kayıtları (power_demo_skip + sonuç) görünümün işidir
/// (`power_demo_view_test`); burada yalnız carousel ile birleşimi sınanır: doğru sayfa, tek
/// "Atla", demo sayfasında carousel "İleri"si yok, demodan sonra Elmaslar sayfası, kaydırarak
/// çıkışta (girişte de) tek kayıt ve küçük ekranda Cevapla'nın kaydırmadan ulaşılabilir olması.

const _onboarding = PowerDemoEntryPoint.onboarding;
final _t = enTranslations;

/// Carousel'in genel "Atla"sı (PageView'ın DIŞINDAKİ) — demonun kendi "Atla"sı PageView içindedir
/// ve aynı metni taşır.
int _generalSkipCount() =>
    find.text(_t['onboarding_v2_skip']!).evaluate().length -
    find
        .descendant(
          of: find.byType(PageView),
          matching: find.text(_t['onboarding_v2_skip']!),
        )
        .evaluate()
        .length;

Finder _demoSkip() => find.descendant(
  of: find.byType(PowerDemoView),
  matching: find.text(_t['skip']!),
);

/// Sonsuz dönen animasyonlar (arka plan, Lottie, sayaç nabzı) yüzünden `pumpAndSettle` yok.
Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpCarousel(
  WidgetTester tester, {
  required bool demoEnabled,
  Size size = const Size(390, 844),
  FakeViewPadding padding = FakeViewPadding.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        powerDemoEnabledProvider.overrideWithValue(demoEnabled),
        onboardingSeenPrefsProvider.overrideWithValue(prefs),
        navigationServiceProvider.overrideWithValue(FakeNavigationService()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const OnboardingScreen(),
      ),
    ),
  );
  await tester.pump(); // AppLocalizationsDelegate.load asenkron
  await _settle(tester, 2);
}

/// Alt çubuğun "İleri"si (finaldeki demo "İleri"si aynı metni taşır → düğme türüyle ayrılır).
Finder _carouselNext() =>
    find.widgetWithText(ElevatedButton, _t['onboarding_v2_next']!);

/// Alt çubuktaki "İleri" ile bir sayfa ilerler.
Future<void> _nextPage(WidgetTester tester) async {
  await tester.tap(_carouselNext());
  await _settle(tester);
}

Future<void> _goToPowersPage(WidgetTester tester) async {
  await _nextPage(tester);
  await _nextPage(tester);
}

PowerDemoDriver _demo(WidgetTester tester) =>
    PowerDemoDriver(tester, entryPoint: _onboarding);

void main() {
  final events = <(String, Map<String, Object>?)>[];

  List<Map<String, Object>?> paramsOf(String name) => [
    for (final e in events)
      if (e.$1 == name) e.$2,
  ];

  setUp(() {
    events.clear();
    SharedPreferences.setMockInitialValues({});
    AnalyticsManager.debugEventSink = (name, params) =>
        events.add((name, params));
    AnalyticsForwarder.instance.setEnabled(false);
    HapticManager.instance.setEnabled(false);
  });

  tearDown(() {
    AnalyticsManager.debugEventSink = null;
    AnalyticsForwarder.instance.setEnabled(true);
    HapticManager.instance.setEnabled(true);
  });

  // 2026-10-29: yeni kullanıcı tüm dillerle başlar (global havuz). "Başla" seçimi
  // auth sonrası PUT /users/me/languages ile sunucuya yazılır; tek dil gönderirse
  // sunucunun 18 dilli kayıt varsayılanını ezer.
  testWidgets('Başla: varsayılan seçim tüm diller, uygulama dili başta', (
    tester,
  ) async {
    await _pumpCarousel(tester, demoEnabled: false);
    for (var i = 0; i < 4; i++) {
      await _nextPage(tester);
    }
    await tester.tap(
      find.widgetWithText(ElevatedButton, _t['onboarding_v2_start']!),
    );
    await _settle(tester);

    final saved = await PendingLanguagesStore.read();
    expect(saved.first, 'en');
    expect(saved.toSet(), AppConstants.supportedQuestionLocales.toSet());
    expect(saved.length, AppConstants.supportedQuestionLocales.length);
  });

  testWidgets('anahtar açık → 3. sayfa demo', (tester) async {
    await _pumpCarousel(tester, demoEnabled: true);
    await _goToPowersPage(tester);

    expect(find.byType(PowerDemoView), findsOneWidget);
    expect(find.byType(OnboardingPowersPage), findsNothing);
    expect(find.text(_t['power_demo_start']!), findsOneWidget);
  });

  testWidgets('anahtar kapalı → eski ızgara', (tester) async {
    await _pumpCarousel(tester, demoEnabled: false);
    await _goToPowersPage(tester);

    expect(find.byType(OnboardingPowersPage), findsOneWidget);
    expect(find.byType(PowerDemoView), findsNothing);
    // Demo yoksa genel "Atla" olağan yerinde kalır.
    expect(_generalSkipCount(), 1);
  });

  testWidgets('demo sayfasında genel Atla görünmez, diğer sayfalarda görünür', (
    tester,
  ) async {
    await _pumpCarousel(tester, demoEnabled: true);
    expect(_generalSkipCount(), 1, reason: '1. sayfa');

    await _nextPage(tester);
    expect(_generalSkipCount(), 1, reason: '2. sayfa');

    await _nextPage(tester);
    expect(find.byType(PowerDemoView), findsOneWidget);
    expect(_generalSkipCount(), 0, reason: 'demo sayfası');
    expect(_demoSkip(), findsOneWidget, reason: 'demonun kendi tek Atla\'sı');

    await tester.tap(_demoSkip());
    await _settle(tester);
    expect(_generalSkipCount(), 1, reason: '4. sayfa');
  });

  // Ruling 15: demo sayfasında tek talimat — finalde iki "İleri", adım ortasında ikinci çıkış
  // yolu kafa karıştırır. Çıkış: demonun Atla'sı, finaldeki demo "İleri"si ya da kaydırma.
  testWidgets(
    'anahtar açık: demo sayfasında carousel İleri yok (göstergeler kalır), diğer sayfalarda var',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      expect(_carouselNext(), findsOneWidget, reason: '1. sayfa');

      await _nextPage(tester);
      expect(_carouselNext(), findsOneWidget, reason: '2. sayfa');

      await _nextPage(tester);
      expect(find.byType(PowerDemoView), findsOneWidget);
      expect(_carouselNext(), findsNothing, reason: 'demo sayfası');
      expect(
        find.byType(OnboardingIndicators),
        findsOneWidget,
        reason: 'sayfa göstergeleri kalır',
      );

      await tester.tap(_demoSkip());
      await _settle(tester);
      expect(find.byType(OnboardingDiamondsPage), findsOneWidget);
      expect(_carouselNext(), findsOneWidget, reason: '4. sayfa');
    },
  );

  testWidgets(
    'anahtar kapalı: 3. sayfada (eski ızgara) carousel İleri var ve ilerletir',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: false);
      await _goToPowersPage(tester);

      expect(find.byType(OnboardingPowersPage), findsOneWidget);
      expect(_carouselNext(), findsOneWidget);
      await _nextPage(tester);
      expect(find.byType(OnboardingDiamondsPage), findsOneWidget);
    },
  );

  testWidgets(
    'demo sayfasında üst boşluk yok: demo carousel\'in üst kenarından başlar',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      await _goToPowersPage(tester);

      // Genel Atla da yer tutucusu da yok: dikey alanın hepsi demonun (küçük ekranda Cevapla'ya yer).
      final pageView = tester.getRect(find.byType(PageView));
      expect(pageView.top, 0);
      expect(tester.getRect(find.byType(PowerDemoView)).top, 0);
    },
  );

  testWidgets(
    'demoda Atla → 4. sayfa (diamonds) + onboarding_v2_page_view page_index 3',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      await _goToPowersPage(tester);

      await tester.tap(_demoSkip());
      await _settle(tester);

      expect(find.byType(OnboardingDiamondsPage), findsOneWidget);
      expect(find.byType(PowerDemoView), findsNothing);
      final last = paramsOf(AnalyticsEvents.onboardingV2PageView).last!;
      expect(last[AnalyticsEvents.paramPageIndex], 3);
      expect(last[AnalyticsEvents.paramPageName], 'diamonds');
      // Demo atlandı, tanıtım değil: genel "Atla" olayı yok.
      expect(paramsOf(AnalyticsEvents.onboardingV2Skip), isEmpty);
      expect(paramsOf(AnalyticsEvents.powerDemoSkip), hasLength(1));
    },
  );

  testWidgets(
    "demo adım 2'deyken sayfa kaydırılırsa skipped(2) + power_demo_skip",
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      await _goToPowersPage(tester);
      await _demo(tester).playUntil(
        (p) => p.stepIndex == 1 && p.phase == PowerDemoPhase.awaitingPower,
      );

      // Sayfanın yarısından fazla ama tamamından az: 5. sayfa (Dil) hiç kurulmasın.
      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await _settle(tester);

      expect(find.byType(OnboardingDiamondsPage), findsOneWidget);
      expect(find.byType(PowerDemoView), findsNothing);
      // Kaydı görünüm atar (dispose); carousel ikinci kayıt eklemez.
      final skip = paramsOf(AnalyticsEvents.powerDemoSkip).single!;
      expect(skip[AnalyticsEvents.paramFromStep], 2);
      expect(skip[AnalyticsEvents.paramEntryPoint], 'onboarding');
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoSkipped(2));
      expect(paramsOf(AnalyticsEvents.powerDemoComplete), isEmpty);
      expect(
        paramsOf(
          AnalyticsEvents.onboardingV2PageView,
        ).last![AnalyticsEvents.paramPageIndex],
        3,
      );
    },
  );

  // Spec §9.1 "hepsini atlayan" kovası: Başla'ya hiç basmadan sayfayı terk eden de atlayandır.
  testWidgets(
    'girişte (Başla öncesi) sayfa kaydırılırsa tek power_demo_skip(from_step 0) + skipped(0)',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      await _goToPowersPage(tester);
      expect(_demo(tester).progress.phase, PowerDemoPhase.intro);

      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await _settle(tester);

      expect(find.byType(OnboardingDiamondsPage), findsOneWidget);
      expect(find.byType(PowerDemoView), findsNothing);
      final skip = paramsOf(AnalyticsEvents.powerDemoSkip).single!;
      expect(skip[AnalyticsEvents.paramFromStep], 0);
      expect(
        skip.containsKey(AnalyticsEvents.paramPower),
        isFalse,
        reason: 'giriş adımının gücü yok',
      );
      expect(skip[AnalyticsEvents.paramEntryPoint], 'onboarding');
      expect(paramsOf(AnalyticsEvents.powerDemoStart), isEmpty);
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoSkipped(0));
    },
  );

  testWidgets(
    'girişte kısa sürükleyip geri bırakmak (sayfa değişmez) kayıt yazmaz',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      await _goToPowersPage(tester);

      await tester.drag(find.byType(PageView), const Offset(-100, 0));
      await _settle(tester);

      expect(
        find.byType(PowerDemoView),
        findsOneWidget,
        reason: 'demo sayfasında kalındı',
      );
      expect(paramsOf(AnalyticsEvents.powerDemoSkip), isEmpty);
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoNotSeen());
    },
  );

  testWidgets(
    '2. sayfadan demoya doğru kısa sürükleyip geri dönmek (demo hiç yerleşmedi) kayıt yazmaz',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      await _nextPage(tester);

      await tester.drag(find.byType(PageView), const Offset(-100, 0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.byType(PowerDemoView),
        findsOneWidget,
        reason: 'sürüklerken demo sayfası kuruldu',
      );
      await _settle(tester);

      expect(
        find.byType(PowerDemoView),
        findsNothing,
        reason: 'geri bırakılınca sayfa kaldırıldı',
      );
      expect(paramsOf(AnalyticsEvents.powerDemoSkip), isEmpty);
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoNotSeen());
    },
  );

  // Yarıdan fazla sürükleyip bırakmadan geri dönmek: sayfa 3'e "geçip" 2'ye döner, üst alan ve
  // alt çubuk animasyonla boyut değiştirir. Talimat deliği yeni yerleşime göre ölçülmezse güce
  // dokunuş yutulur, demo bu adımda kilitlenir.
  testWidgets(
    'adım ortasında yarıdan fazla sürükleyip geri dönünce güce dokunmak çalışır, kayıt yok',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      await _goToPowersPage(tester);
      final demo = _demo(tester);
      await demo.playUntil((p) => p.phase == PowerDemoPhase.awaitingPower);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(-50, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        find.byType(OnboardingDiamondsPage),
        findsOneWidget,
        reason: 'yarıyı geçti: 4. sayfa göründü',
      );
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await _settle(tester);

      expect(find.byType(PowerDemoView), findsOneWidget);
      expect(demo.progress.phase, PowerDemoPhase.awaitingPower);
      await demo.playOne(); // güce dokun
      expect(
        demo.progress.phase,
        PowerDemoPhase.awaitingAnswer,
        reason: 'talimat deliği güç butonunun son konumunda',
      );
      expect(paramsOf(AnalyticsEvents.powerDemoSkip), isEmpty);
    },
  );

  testWidgets(
    'demo tamamlandıktan sonra sayfa kaydırılırsa atlama kaydı yok, sonuç completed',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      await _goToPowersPage(tester);
      await _demo(tester).playUntil((p) => p.phase == PowerDemoPhase.finale);

      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await _settle(tester);

      expect(find.byType(OnboardingDiamondsPage), findsOneWidget);
      expect(paramsOf(AnalyticsEvents.powerDemoSkip), isEmpty);
      expect(paramsOf(AnalyticsEvents.powerDemoComplete), hasLength(1));
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoCompleted());
    },
  );

  testWidgets(
    'demo tamamlanınca → 4. sayfa, atlama kaydı yok, sonuç completed',
    (tester) async {
      await _pumpCarousel(tester, demoEnabled: true);
      await _goToPowersPage(tester);
      await _demo(tester).playUntil((p) => p.phase == PowerDemoPhase.finale);

      await tester.tap(
        find.descendant(
          of: find.byType(PowerDemoFinale),
          matching: find.text(_t['next']!),
        ),
      );
      await _settle(tester);

      expect(find.byType(OnboardingDiamondsPage), findsOneWidget);
      expect(paramsOf(AnalyticsEvents.powerDemoComplete), hasLength(1));
      expect(paramsOf(AnalyticsEvents.powerDemoSkip), isEmpty);
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoCompleted());
      expect(
        paramsOf(
          AnalyticsEvents.onboardingV2PageView,
        ).last![AnalyticsEvents.paramPageIndex],
        3,
      );
    },
  );

  testWidgets('375×667, textScale 1.3: carousel çerçevesinde demo taşmaz', (
    tester,
  ) async {
    await _pumpCarousel(tester, demoEnabled: true, size: const Size(375, 667));
    await _goToPowersPage(tester);
    // Büyük yazı demo sayfasına varınca açılır: 1. ve 2. tanıtım sayfalarının bu boyutta
    // kendi taşması bu testin konusu değil.
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pump();
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byType(PowerDemoView)),
      ).scale(10),
      13,
    );
    expect(tester.takeException(), isNull);

    await _demo(tester).playUntil((p) {
      expect(tester.takeException(), isNull, reason: 'adım ${p.stepIndex + 1}');
      return p.phase == PowerDemoPhase.finale;
    });
    expect(tester.takeException(), isNull);
  });

  // Gerçek cihaz çerçeveleri (durum çubuğu / Android gezinme çubuğu dahil). Ölçüm (final inceleme,
  // SF fontu): Cevapla kayan alandaydı → SE'de ipucu adımında 129 px, 360×800'de 35 px ekran dışı.
  for (final c in const [
    (
      name: 'SE 375×667',
      size: Size(375, 667),
      top: 20.0,
      bottom: 0.0,
      scale: 1.0,
    ),
    (
      name: 'SE 375×667',
      size: Size(375, 667),
      top: 20.0,
      bottom: 0.0,
      scale: 1.3,
    ),
    (
      name: 'Android 360×800',
      size: Size(360, 800),
      top: 24.0,
      bottom: 48.0,
      scale: 1.0,
    ),
    (
      name: 'Android 360×800',
      size: Size(360, 800),
      top: 24.0,
      bottom: 48.0,
      scale: 1.3,
    ),
  ]) {
    testWidgets(
      '${c.name} textScale ${c.scale}: şık seçilince Cevapla kaydırmadan ekranda ve dokunulabilir',
      (tester) async {
        await _pumpCarousel(
          tester,
          demoEnabled: true,
          size: c.size,
          padding: FakeViewPadding(top: c.top, bottom: c.bottom),
        );
        await _goToPowersPage(tester);
        // Büyük yazı demo sayfasına varınca açılır (1. ve 2. sayfanın kendi taşması kapsam dışı).
        tester.platformDispatcher.textScaleFactorTestValue = c.scale;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await tester.pump();

        final screen = Rect.fromLTRB(
          0,
          c.top,
          c.size.width,
          c.size.height - c.bottom,
        );
        final demo = _demo(tester);
        final checked = <DemoPower?>[];
        await demo.playUntil(
          (p) => p.phase == PowerDemoPhase.finale,
          onAnswerReady: (q) {
            demo.expectAnswerReachable(
              screen,
              reason: 'adım ${q.id} (${q.power?.apiName})',
            );
            checked.add(q.power);
          },
        );
        // İpucu adımı (en uzun içerik: soru + ipucu kartı + şıklar) mutlaka sınandı.
        expect(
          checked,
          containsAll([
            DemoPower.timeExtend,
            DemoPower.oracle,
            DemoPower.half,
            DemoPower.hint,
          ]),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
