import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/l10n/translations/ar.dart';
import 'package:qulo_v2/core/l10n/translations/de.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/data/models/economy_config_model.dart';
import 'package:qulo_v2/features/power_demo/constants/power_demo_keys.dart';
import 'package:qulo_v2/features/power_demo/data/power_demo_outcome_store.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_outcome.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_question.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_scenario.dart';
import 'package:qulo_v2/features/power_demo/providers/power_demo_notifier.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_view.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/features/quiz/widgets/rescue_cards.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_navigation.dart';

/// Güç demosu görünümü uçtan uca: gerçek notifier + makine, sahte ekonomi ve navigasyon.
/// Demo sunucusuzdur; burada akış, talimat/sonuç metinleri, analitik, sonuç kaydı ve küçük
/// ekranda taşma sınanır. Kural ayrıntıları makine/notifier testlerinde.

/// Prod fiyatları (Doğru Say 50 / Hepsini Geç 90 mor) → 7 soruluk demo.
EconomyConfig _economy({
  int skipPurple = 50,
  int skipAllPurple = 90,
  double oracleAccuracy = 0.7,
  int timeExtendSeconds = 15,
  Map<String, int> starterPowers = RewardsConfig.defaultStarterPowers,
}) {
  const base = EconomyConfig.fallback;
  return EconomyConfig(
    core: base.core,
    subscriptionLimits: base.subscriptionLimits,
    rewards: RewardsConfig(
      milestones: base.rewards.milestones,
      referralPurple: base.rewards.referralPurple,
      maxCompletedReferrals: base.rewards.maxCompletedReferrals,
      starterPowers: starterPowers,
    ),
    timing: TimingConfig(
      questionTimeSeconds: base.timing.questionTimeSeconds,
      timeExtendSeconds: timeExtendSeconds,
      timePresets: base.timing.timePresets,
    ),
    powerCosts: PowerCostsConfig(
      oracle: base.powerCosts.oracle,
      half: base.powerCosts.half,
      skip: PowerCostConfig(greenCost: 0, purpleCost: skipPurple),
      skipAll: PowerCostConfig(greenCost: 0, purpleCost: skipAllPurple),
      timeExtend: base.powerCosts.timeExtend,
      hint: base.powerCosts.hint,
      powerBlock: base.powerCosts.powerBlock,
      powerUnblock: base.powerCosts.powerUnblock,
    ),
    oracleAccuracy: oracleAccuracy,
  );
}

class _FixedEconomy extends EconomyConfigNotifier {
  _FixedEconomy(this._config);

  final EconomyConfig _config;

  @override
  EconomyConfig build() => _config;

  @override
  Future<void> fetch() async {}
}

/// Ekrandaki demoyu kullanıcı gibi oynatır; senaryo ve durum notifier'dan okunur.
class _Demo {
  _Demo(this.tester, this.entryPoint, this.nav, this.texts);

  final WidgetTester tester;
  final PowerDemoEntryPoint entryPoint;
  final FakeNavigationService nav;
  final Map<String, String> texts;
  int exits = 0;

  /// Güç adımında dokunmadan önce ekranda görülen talimatlar (güç → görüldü mü).
  final seenInstructions = <DemoPower, bool>{};

  ProviderContainer get _container =>
      ProviderScope.containerOf(tester.element(find.byType(PowerDemoView)));
  PowerDemoProgress get progress =>
      _container.read(powerDemoProvider(entryPoint));
  PowerDemoScenario get scenario =>
      _container.read(powerDemoProvider(entryPoint).notifier).scenario;
  PowerDemoQuestion get question => scenario.questions[progress.stepIndex];

  String t(String key) => texts[key]!;

  String instructionOf(DemoPower power) =>
      t(PowerDemoKeys.instruction(power)).replaceAll(
        '{count}',
        FormatManager.instance.integer(scenario.length - progress.stepIndex),
      );

  Finder powerButton(DemoPower power) => find.byWidgetPredicate(
    (w) => w is PowerBarButton && w.type.apiName == power.apiName,
  );

  /// Efektler, kutlama ve "kart kenara kayar" beklemeleri dahil ekranı oturtur. `pumpAndSettle`
  /// kullanılmaz: sayaç nabzı sonsuz döner.
  Future<void> settle([int frames = 16]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> start() async {
    await tester.tap(find.text(t('power_demo_start')));
    await settle();
  }

  Future<void> usePower() async {
    final power = question.power!;
    seenInstructions[power] = find
        .text(instructionOf(power))
        .evaluate()
        .isNotEmpty;
    await tester.tap(powerButton(power));
    await settle();
  }

  int _wrongIndex(PowerDemoQuestion q) => [
    for (var i = 0; i < q.optionCount; i++)
      if (i != q.correctIndex && !progress.removedIndices.contains(i)) i,
  ].first;

  Future<void> answer({bool correct = true}) async {
    final q = question;
    final index = correct ? q.correctIndex : _wrongIndex(q);
    await _tapVisible(find.text(t(PowerDemoKeys.option(q, index))));
    await _tapVisible(find.text(t('quiz_confirm_answer')));
    await settle();
  }

  /// Küçük ekranda soru kartı kayar: dokunmadan önce görünür alana getir.
  Future<void> _tapVisible(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> rescue() async {
    await tester.tap(find.text(t('quiz_rescue_skip')));
    await settle();
  }

  /// Bir sonraki eylemi yapar ([wrongAtStep] numaralı adımda — 1 tabanlı — yanlış cevap verir).
  Future<void> next({int? wrongAtStep, VoidCallback? afterEach}) async {
    switch (progress.phase) {
      case PowerDemoPhase.intro:
        await start();
      case PowerDemoPhase.awaitingPower:
        await usePower();
      case PowerDemoPhase.awaitingAnswer:
        await answer(correct: progress.stepIndex + 1 != wrongAtStep);
      case PowerDemoPhase.rescue:
        await rescue();
      case PowerDemoPhase.skippingAll:
        await settle();
      case PowerDemoPhase.finale:
      case PowerDemoPhase.skipped:
        break;
    }
    afterEach?.call();
  }

  Future<void> playToFinale({int? wrongAtStep, VoidCallback? afterEach}) async {
    for (var guard = 0; progress.phase != PowerDemoPhase.finale; guard++) {
      expect(
        guard,
        lessThan(40),
        reason: 'demo ilerlemiyor: ${progress.phase}',
      );
      await next(wrongAtStep: wrongAtStep, afterEach: afterEach);
    }
  }
}

Future<_Demo> _pumpDemo(
  WidgetTester tester, {
  PowerDemoEntryPoint entryPoint = PowerDemoEntryPoint.onboarding,
  EconomyConfig? economy,
  String locale = 'en',
  Map<String, String> texts = enTranslations,
  double textScale = 1,
  bool reduceMotion = false,
  bool isActive = true,
}) async {
  final nav = FakeNavigationService();
  late final _Demo demo;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (economy != null)
          economyConfigProvider.overrideWith(() => _FixedEconomy(economy)),
        navigationServiceProvider.overrideWithValue(nav),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale(locale)],
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: PowerDemoView(
            entryPoint: entryPoint,
            isActive: isActive,
            onExit: () => demo.exits++,
          ),
        ),
      ),
    ),
  );
  demo = _Demo(tester, entryPoint, nav, texts);
  await tester.pump(); // AppLocalizationsDelegate.load asenkron
  return demo;
}

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
    // market/quiz_intro olayları flow_events'e de gider; 15 sn'lik flush zamanlayıcısı kurulmasın.
    AnalyticsForwarder.instance.setEnabled(false);
    // Haptik gecikmeleri (Future.delayed) test sonunda bekleyen zamanlayıcı bırakmasın.
    HapticManager.instance.setEnabled(false);
  });

  tearDown(() {
    AnalyticsManager.debugEventSink = null;
    AnalyticsForwarder.instance.setEnabled(true);
    HapticManager.instance.setEnabled(true);
  });

  testWidgets(
    'uçtan uca: 7 adım, her güç adımında talimat görünür, bitişte onExit bir kez + outcome completed + power_demo_complete',
    (tester) async {
      final demo = await _pumpDemo(tester, economy: _economy());

      await demo.start();
      expect(find.text('1/7'), findsOneWidget);
      await demo.playToFinale();

      expect(demo.seenInstructions, {
        for (final p in DemoPower.values) p: true,
      });
      expect(find.text('7/7'), findsOneWidget);
      expect(find.text(demo.t('power_demo_finale_title')), findsOneWidget);
      expect(
        find.text(demo.t('power_demo_finale_gift').replaceAll('{count}', '1')),
        findsOneWidget,
      );

      await tester.tap(find.text(demo.t('next')));
      await tester.pump();
      await tester.tap(find.text(demo.t('next')), warnIfMissed: false);
      await tester.pump();
      expect(demo.exits, 1);

      expect(await PowerDemoOutcomeStore.read(), const PowerDemoCompleted());
      expect(paramsOf(AnalyticsEvents.powerDemoStart), hasLength(1));
      expect(
        paramsOf(
          AnalyticsEvents.powerDemoStepView,
        ).map((p) => p![AnalyticsEvents.paramStepIndex]),
        [1, 2, 3, 4, 5, 6],
      );
      expect(
        paramsOf(
          AnalyticsEvents.powerDemoPowerUsed,
        ).map((p) => p![AnalyticsEvents.paramPower]),
        [for (final p in DemoPower.values) p.apiName],
      );
      expect(
        paramsOf(
          AnalyticsEvents.powerDemoAnswer,
        ).map((p) => p![AnalyticsEvents.paramCorrect]),
        [true, true, true, true],
      );
      final complete = paramsOf(AnalyticsEvents.powerDemoComplete).single!;
      expect(complete[AnalyticsEvents.paramWrongAnswers], 0);
      expect(complete[AnalyticsEvents.paramEntryPoint], 'onboarding');
      expect(complete[AnalyticsEvents.paramDurationMs], greaterThan(0));
      expect(paramsOf(AnalyticsEvents.powerDemoSkip), isEmpty);
    },
  );

  testWidgets(
    "adım 3'te Atla → onExit + skipped(3) + power_demo_skip from_step 3",
    (tester) async {
      final demo = await _pumpDemo(tester, economy: _economy());
      await demo.start();
      while (demo.progress.stepIndex < 2) {
        await demo.next();
      }
      expect(find.text(demo.instructionOf(DemoPower.half)), findsOneWidget);

      await tester.tap(find.text(demo.t('skip')));
      await demo.settle();

      expect(demo.exits, 1);
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoSkipped(3));
      final skip = paramsOf(AnalyticsEvents.powerDemoSkip).single!;
      expect(skip[AnalyticsEvents.paramFromStep], 3);
      expect(skip[AnalyticsEvents.paramPower], 'HALF');
      expect(skip[AnalyticsEvents.paramEntryPoint], 'onboarding');
      expect(paramsOf(AnalyticsEvents.powerDemoComplete), isEmpty);
    },
  );

  testWidgets(
    'yanlış şık seçilse de doğru sayılır: kurtarma kartı yok, sonraki adım',
    (tester) async {
      final demo = await _pumpDemo(tester, economy: _economy());
      await demo.start();
      await demo.usePower();
      await demo.answer(correct: false);
      await demo.settle();

      expect(find.byType(RescueCards), findsNothing);
      expect(demo.progress.phase, isNot(PowerDemoPhase.rescue));
      expect(demo.progress.stepIndex, 1);
      expect(demo.progress.wrongAnswers, 0);
      expect(paramsOf(AnalyticsEvents.powerDemoRescueUsed), isEmpty);
      expect(
        paramsOf(
          AnalyticsEvents.powerDemoAnswer,
        ).single![AnalyticsEvents.paramCorrect],
        true,
      );
    },
  );

  testWidgets('Kâhin etiketi %65 (oracleAccuracy 0.65)', (tester) async {
    final demo = await _pumpDemo(
      tester,
      economy: _economy(oracleAccuracy: 0.65),
    );
    await demo.start();
    await demo.next();
    await demo.next();
    expect(demo.question.power, DemoPower.oracle);
    await demo.usePower();

    final label = demo
        .t('power_oracle_accuracy')
        .replaceAll('{percent}', FormatManager.instance.percent(65));
    expect(find.text(label), findsOneWidget);
  });

  testWidgets('EconomyConfig.fallback ile 9 soru ve %70', (tester) async {
    // Ekonomi hiç çekilemedi (çevrimdışı ilk açılış): provider yedek değerde kalır.
    final demo = await _pumpDemo(tester);
    await demo.start();
    expect(find.text('1/9'), findsOneWidget);
    await demo.next();
    await demo.next();
    await demo.usePower();

    final label = demo
        .t('power_oracle_accuracy')
        .replaceAll('{percent}', FormatManager.instance.percent(70));
    expect(find.text(label), findsOneWidget);

    await demo.playToFinale();
    expect(find.text('9/9'), findsOneWidget);
  });

  testWidgets('starterPowers HALF=0 → hediye cümlesi yok', (tester) async {
    final demo = await _pumpDemo(
      tester,
      economy: _economy(
        starterPowers: {...RewardsConfig.defaultStarterPowers, 'HALF': 0},
      ),
    );
    await demo.playToFinale();

    expect(find.text(demo.t('power_demo_finale_title')), findsOneWidget);
    expect(
      find.textContaining(
        demo.t('power_demo_finale_gift').split('{count}').first,
      ),
      findsNothing,
    );
  });

  testWidgets('starterPowers en küçük değer N → hediye cümlesi N ile', (
    tester,
  ) async {
    final demo = await _pumpDemo(
      tester,
      economy: _economy(
        starterPowers: {
          for (final p in DemoPower.values) p.apiName: 3,
          'HINT': 2,
          'POWER_BLOCK':
              0, // sohbet gücü: demo onu öğretmez, hediye cümlesini etkilemez
        },
      ),
    );
    await demo.playToFinale();

    expect(
      find.text(demo.t('power_demo_finale_gift').replaceAll('{count}', '2')),
      findsOneWidget,
    );
  });

  testWidgets('market girişinde kayıt cümlesi yok', (tester) async {
    final demo = await _pumpDemo(
      tester,
      entryPoint: PowerDemoEntryPoint.market,
      economy: _economy(),
    );
    await demo.playToFinale();

    expect(
      find.textContaining(
        demo.t('power_demo_finale_gift').split('{count}').first,
      ),
      findsNothing,
    );
    expect(find.text(demo.t('power_demo_finale_ready')), findsOneWidget);
    expect(
      paramsOf(
        AnalyticsEvents.powerDemoComplete,
      ).single![AnalyticsEvents.paramEntryPoint],
      'market',
    );
    // Sonuç deposu yalnız onboarding içindir: market denemesi kaydı değiştirmez.
    expect(await PowerDemoOutcomeStore.read(), const PowerDemoNotSeen());
  });

  for (final (locale, texts) in [
    ('en', enTranslations),
    ('de', deTranslations),
    ('ar', arTranslations),
  ]) {
    testWidgets('375×667, textScale 1.3: her adımda taşma yok ($locale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final demo = await _pumpDemo(
        tester,
        economy: _economy(skipPurple: 20, skipAllPurple: 60),
        locale: locale,
        texts: texts,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      // Adım 2'de yanlış cevap: kurtarma kartı da küçük ekranda sınanır.
      await demo.playToFinale(
        wrongAtStep: 2,
        afterEach: () => expect(
          tester.takeException(),
          isNull,
          reason: 'adım ${demo.progress.stepIndex + 1}',
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('hiçbir route push edilmez', (tester) async {
    final demo = await _pumpDemo(tester, economy: _economy());
    await demo.playToFinale(wrongAtStep: 1);
    await tester.tap(find.text(demo.t('next')));
    await tester.pump();

    expect(demo.nav.pushes, isEmpty);
    expect(demo.nav.pops, 0);
    expect(demo.nav.dialogs, isEmpty);
    expect(demo.nav.sheets, isEmpty);
    expect(demo.exits, 1);
  });

  testWidgets(
    "adım 1: sayaç 5 sn'de durur, 0'a inmez; ek süre timeExtendSeconds kadar ekler",
    (tester) async {
      final demo = await _pumpDemo(
        tester,
        economy: _economy(timeExtendSeconds: 20),
      );
      await demo.start();
      await demo.settle(150); // 15 sn bekle: gerçek quiz'de süre biterdi

      QuizTimerState timer() =>
          tester.state<QuizTimerState>(find.byType(QuizTimer));
      expect(timer().remainingSeconds, 5);
      expect(demo.progress.phase, PowerDemoPhase.awaitingPower);

      await tester.tap(demo.powerButton(DemoPower.timeExtend));
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 600),
      ); // sayı yukarı sayar (en çok 1 tık düşer)
      expect(timer().remainingSeconds, inInclusiveRange(24, 25));
      expect(find.text('+20'), findsOneWidget);

      await demo.settle(400); // 40 sn daha: yine 5'te durur
      expect(timer().remainingSeconds, 5);
      expect(demo.progress.phase, PowerDemoPhase.awaitingAnswer);
    },
  );

  testWidgets(
    'Doğru Say: kart kenara kayarken adım 5 kalır, sonra Hepsini Geç talimatı (kalan 2)',
    (tester) async {
      final demo = await _pumpDemo(tester, economy: _economy());
      await demo.start();
      while (demo.question.power != DemoPower.skip) {
        await demo.next();
      }

      await tester.tap(demo.powerButton(DemoPower.skip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('5/7'), findsOneWidget);
      expect(find.text(demo.t('power_demo_result_skip')), findsOneWidget);
      expect(find.text(demo.instructionOf(DemoPower.skipAll)), findsNothing);

      await demo.settle();
      expect(find.text('6/7'), findsOneWidget);
      expect(
        find.text(
          demo.t('power_demo_hint_skip_all').replaceAll('{count}', '2'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Ek Süre sayımı sürerken sonraki adıma geçilirse yeni soruya saniye eklenmez',
    (tester) async {
      final demo = await _pumpDemo(tester, economy: _economy());
      await demo.start();
      final questionSeconds = EconomyConfig.fallback.timing.questionTimeSeconds;

      await tester.tap(demo.powerButton(DemoPower.timeExtend));
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 60),
      ); // sayım başladı (~30 ms'de bir +1), bitmedi
      // Sayım bitmeden cevapla: zaman ilerletmeden (yalnız sıfır süreli kareler).
      await demo.answer();
      expect(demo.progress.stepIndex, 1, reason: 'adım 2 (Kâhin)');

      await tester.pump(
        PowerEffectTiming.enter,
      ); // eski sayım sürseydi kalan saniyeleri eklerdi
      final timer = tester.state<QuizTimerState>(find.byType(QuizTimer));
      expect(
        timer.remainingSeconds,
        lessThanOrEqualTo(questionSeconds),
        reason:
            'yeni soru tam süreyle başlar, önceki adımın Ek Süre sayımı taşınmaz',
      );
    },
  );

  testWidgets('Atla sonrası (skipped) başlıkta ölü Atla görünmez', (
    tester,
  ) async {
    final demo = await _pumpDemo(tester, economy: _economy());
    await demo.start();

    await tester.tap(find.text(demo.t('skip')));
    await tester.pump();

    expect(demo.progress.phase, PowerDemoPhase.skipped);
    expect(demo.exits, 1);
    expect(
      find.text(demo.t('skip')),
      findsNothing,
      reason: 'makine skipped\'ta Atla\'yı yok sayar',
    );
  });

  testWidgets(
    'hareketi azalt açıkken demo tamamlanır, ek süre tek seferde eklenir',
    (tester) async {
      final demo = await _pumpDemo(
        tester,
        economy: _economy(),
        reduceMotion: true,
      );
      await demo.start();
      await demo.settle(70); // 7 sn: sayaç 11'den 5'e iner, durur

      await tester.tap(demo.powerButton(DemoPower.timeExtend));
      await tester.pump();
      expect(
        tester.state<QuizTimerState>(find.byType(QuizTimer)).remainingSeconds,
        20,
      );

      await demo.playToFinale();
      expect(paramsOf(AnalyticsEvents.powerDemoComplete), hasLength(1));
    },
  );

  testWidgets(
    'yarıda bırakılırsa (dispose) power_demo_skip + skipped(adım) yazılır',
    (tester) async {
      final demo = await _pumpDemo(tester, economy: _economy());
      await demo.start();
      await demo.next(); // adım 1 gücü
      await demo.next(); // adım 1 cevabı → adım 2

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final skip = paramsOf(AnalyticsEvents.powerDemoSkip).single!;
      expect(skip[AnalyticsEvents.paramFromStep], 2);
      expect(skip[AnalyticsEvents.paramPower], 'ORACLE');
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoSkipped(2));
      expect(demo.exits, 0);
    },
  );

  // Spec §9.1: "hepsini atlayan" = power_demo_skip. Başla'ya basmadan sayfayı terk eden (carousel'de
  // kaydırma, route'ta geri) de atlayandır — eskiden hiçbir şey yazılmıyor, sonuç not_seen kalıyordu.
  testWidgets(
    'girişte (Başla öncesi) bırakılırsa tek power_demo_skip(from_step 0) + skipped(0)',
    (tester) async {
      final demo = await _pumpDemo(tester, economy: _economy());

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final skip = paramsOf(AnalyticsEvents.powerDemoSkip).single!;
      expect(skip[AnalyticsEvents.paramFromStep], 0);
      expect(skip.containsKey(AnalyticsEvents.paramPower), isFalse);
      expect(skip[AnalyticsEvents.paramEntryPoint], 'onboarding');
      expect(paramsOf(AnalyticsEvents.powerDemoStart), isEmpty);
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoSkipped(0));
      expect(demo.exits, 0, reason: 'bırakmak çıkış geri çağrısı değildir');
    },
  );

  testWidgets(
    'hiç etkin olmadan (kaydırırken bir anlığına kurulan sayfa) bırakılırsa hiçbir şey yazılmaz',
    (tester) async {
      await _pumpDemo(tester, economy: _economy(), isActive: false);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(events.where((e) => e.$1.startsWith('power_demo_')), isEmpty);
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoNotSeen());
    },
  );

  testWidgets(
    'etkin olup sonra pasifleşen (sayfa değişti) görünüm girişte bırakılırsa skip(0) bir kez',
    (tester) async {
      await _pumpDemo(tester, economy: _economy());
      await _pumpDemo(
        tester,
        economy: _economy(),
        isActive: false,
      ); // carousel: sayfa ilerledi

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(
        paramsOf(
          AnalyticsEvents.powerDemoSkip,
        ).single![AnalyticsEvents.paramFromStep],
        0,
      );
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoSkipped(0));
    },
  );

  testWidgets(
    'girişte Atla → from_step 0, sonuç skipped(0), başlangıç olayı yok; sonra bırakmak ikinci kayıt atmaz',
    (tester) async {
      final demo = await _pumpDemo(tester, economy: _economy());

      await tester.tap(find.text(demo.t('skip')));
      await tester.pump();

      expect(demo.exits, 1);
      expect(
        paramsOf(
          AnalyticsEvents.powerDemoSkip,
        ).single![AnalyticsEvents.paramFromStep],
        0,
      );
      expect(paramsOf(AnalyticsEvents.powerDemoStart), isEmpty);
      expect(await PowerDemoOutcomeStore.read(), const PowerDemoSkipped(0));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(
        paramsOf(AnalyticsEvents.powerDemoSkip),
        hasLength(1),
        reason: 'dispose çift kayıt atmaz',
      );
    },
  );

  testWidgets('tamamlandıktan sonra bırakmak atlama kaydı atmaz', (
    tester,
  ) async {
    final demo = await _pumpDemo(tester, economy: _economy());
    await demo.playToFinale();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(paramsOf(AnalyticsEvents.powerDemoSkip), isEmpty);
    expect(paramsOf(AnalyticsEvents.powerDemoComplete), hasLength(1));
    expect(await PowerDemoOutcomeStore.read(), const PowerDemoCompleted());
  });
}
