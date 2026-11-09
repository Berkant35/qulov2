import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/economy_config_model.dart';
import 'package:qulo_v2/data/repositories/exchange_repository.dart';
import 'package:qulo_v2/data/repositories/quiz_repository.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_scenario.dart';
import 'package:qulo_v2/features/power_demo/providers/power_demo_notifier.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';

/// Güç demosunun ince Riverpod kabuğu: makineyi çağırır, durumu atar. Kural makinenin testinde
/// (`power_demo_machine_test.dart`); burada kablolama, fiyatın senaryoya yansıması, yok sayılan
/// eylemin sessizliği ve sunucudan/ekonomiden yalıtım sınanır.

/// Sunucu fiyatları (50/90 mor → 7 soru) ya da yedek fiyatlar (20/60 → 9 soru) ile ekonomi.
class _PricedEconomy extends EconomyConfigNotifier {
  _PricedEconomy(this.skipPurple, this.skipAllPurple);

  final int skipPurple;
  final int skipAllPurple;

  @override
  EconomyConfig build() {
    const base = EconomyConfig.fallback;
    return EconomyConfig(
      core: base.core,
      subscriptionLimits: base.subscriptionLimits,
      rewards: base.rewards,
      timing: base.timing,
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
    );
  }

  @override
  Future<void> fetch() async {}
}

/// Her çağrıda (ve her okumada) kırmızıya dönen sunucu depoları: demo bunlara dokunmamalı.
class _Tripwire {
  int providerReads = 0;
  int repositoryCalls = 0;
}

class _TripwireQuizRepository implements QuizRepository {
  _TripwireQuizRepository(this._tripwire);

  final _Tripwire _tripwire;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    _tripwire.repositoryCalls++;
    throw StateError('demo quizRepository çağırdı: ${invocation.memberName}');
  }
}

class _TripwireExchangeRepository implements ExchangeRepository {
  _TripwireExchangeRepository(this._tripwire);

  final _Tripwire _tripwire;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    _tripwire.repositoryCalls++;
    throw StateError(
      'demo exchangeRepository çağırdı: ${invocation.memberName}',
    );
  }
}

/// Yalnız başlatılan provider'ları kaydeder (yalıtım: demo sadece ekonomiyi okur).
base class _InitRecorder extends ProviderObserver {
  final added = <ProviderBase<Object?>>[];

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) => added.add(provider);
}

const _entry = PowerDemoEntryPoint.onboarding;

/// [ProviderContainer] + demo dinleyicisi. `container.listen` provider'ı ayakta tutar
/// (autoDispose), `notifications` yalnız GERÇEK durum değişimlerini sayar.
class _Harness {
  _Harness._(this.container, this.notifications);

  final ProviderContainer container;
  final List<PowerDemoProgress> notifications;

  PowerDemoNotifier get notifier =>
      container.read(powerDemoProvider(_entry).notifier);
  PowerDemoProgress get state => container.read(powerDemoProvider(_entry));
  PowerDemoScenario get scenario => notifier.scenario;
  int get correctIndex => scenario.questions[state.stepIndex].correctIndex;

  static _Harness create({
    int skipPurple = 50,
    int skipAllPurple = 90,
    List<Override> extra = const [],
    List<ProviderObserver> observers = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        economyConfigProvider.overrideWith(
          () => _PricedEconomy(skipPurple, skipAllPurple),
        ),
        ...extra,
      ],
      observers: observers,
    );
    addTearDown(container.dispose);
    final notifications = <PowerDemoProgress>[];
    container.listen<PowerDemoProgress>(
      powerDemoProvider(_entry),
      (_, next) => notifications.add(next),
    );
    return _Harness._(container, notifications);
  }

  /// Seçili güç adımını gücünü kullanıp doğru şıkla geçer.
  void passCurrentStep() {
    final power = scenario.questions[state.stepIndex].power;
    if (power != null) notifier.usePower(power);
    if (state.phase == PowerDemoPhase.skippingAll) {
      notifier.finishSkipAll();
      return;
    }
    if (state.phase != PowerDemoPhase.awaitingAnswer) return;
    notifier
      ..selectAnswer(correctIndex)
      ..submit();
  }
}

void main() {
  group('senaryo (ekonomi fiyatından)', () {
    test('senaryo 7 soru (prod fiyatı 50/90 mor)', () {
      final h = _Harness.create();

      expect(h.scenario.length, 7);
      expect(h.scenario.questions.map((q) => q.power).take(6), [
        DemoPower.timeExtend,
        DemoPower.oracle,
        DemoPower.half,
        DemoPower.hint,
        DemoPower.skip,
        DemoPower.skipAll,
      ]);
    });

    test('yedek fiyat 20/60 → 9 soru (çevrimdışı ilk açılış)', () {
      final h = _Harness.create(skipPurple: 20, skipAllPurple: 60);

      expect(h.scenario.length, 9);
    });

    test('hiç yüklenmemiş ekonomi (EconomyConfig.fallback) → 9 soru', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(powerDemoProvider(_entry), (_, __) {});

      expect(
        container.read(powerDemoProvider(_entry).notifier).scenario.length,
        9,
      );
    });

    test('başlangıç durumu giriş fazı, 0. adım', () {
      final h = _Harness.create();

      expect(h.state.phase, PowerDemoPhase.intro);
      expect(h.state.stepIndex, 0);
      expect(h.notifications, isEmpty);
    });
  });

  group('akış', () {
    test('start → ilk adım güç bekler', () {
      final h = _Harness.create()..notifier.start();

      expect(h.state.phase, PowerDemoPhase.awaitingPower);
      expect(h.state.stepIndex, 0);
    });

    test('usePower + doğru cevap → sonraki adım', () {
      final h = _Harness.create()..notifier.start();

      h.notifier.usePower(DemoPower.timeExtend);
      expect(h.state.phase, PowerDemoPhase.awaitingAnswer);
      expect(h.state.extraSecondsToken, 1);

      h.notifier.selectAnswer(h.correctIndex);
      final correct = h.notifier.submit();

      expect(correct, isTrue);
      expect(h.state.stepIndex, 1);
      expect(h.state.phase, PowerDemoPhase.awaitingPower);
    });

    test('yanlış şık seçilse de submit doğru sayar, kurtarma kartı çıkmaz', () {
      final h = _Harness.create()
        ..notifier.start()
        ..notifier.usePower(DemoPower.timeExtend);
      final wrong = (h.correctIndex + 1) % 3;

      h.notifier.selectAnswer(wrong);
      final correct = h.notifier.submit();

      expect(correct, isTrue);
      expect(h.state.phase, PowerDemoPhase.awaitingPower);
      expect(h.state.wrongAnswers, 0);
      expect(h.state.stepIndex, 1);
    });

    test('skip: her an çalışır, atlanılan adım korunur', () {
      final h = _Harness.create()
        ..notifier.start()
        ..notifier.skip();

      expect(h.state.phase, PowerDemoPhase.skipped);
      expect(h.state.stepIndex, 0);
    });

    test('uçtan uca: 7 soru doğru oynanır, Hepsini Geç → kutlama', () {
      final h = _Harness.create()..notifier.start();

      for (var moves = 0; h.state.phase != PowerDemoPhase.finale; moves++) {
        if (moves > 30) fail('demo bitmedi (takıldı: ${h.state.phase})');
        h.passCurrentStep();
      }

      expect(h.state.stepIndex, h.scenario.length - 1);
      expect(h.state.wrongAnswers, 0);
      expect(h.state.skipToken, 1);
      expect(h.state.extraSecondsToken, 1);
    });
  });

  group('yok sayılan eylem', () {
    test('güç adımında cevap: submit false, durum AYNI, bildirim yok', () {
      final h = _Harness.create()..notifier.start();
      final before = h.state;
      final notified = h.notifications.length;

      h.notifier.selectAnswer(0);
      final correct = h.notifier.submit();

      expect(correct, isFalse);
      expect(h.state, same(before));
      expect(h.notifications.length, notified);
    });

    test('yok sayılan submit yanlış cevap sayılmaz (wrongAnswers artmaz)', () {
      final h = _Harness.create()
        ..notifier.start()
        ..notifier.usePower(DemoPower.timeExtend);

      // Hiç şık seçilmedi: submit yok sayılır.
      final correct = h.notifier.submit();

      expect(correct, isFalse);
      expect(h.state.wrongAnswers, 0);
      expect(h.state.phase, PowerDemoPhase.awaitingAnswer);
    });

    test('hızlı çift dokunuş: aynı gücü iki kez kullanmak adımı/jetonu bir kez işler', () {
      final h = _Harness.create()..notifier.start();

      h.notifier.usePower(DemoPower.timeExtend);
      final afterFirst = h.state;
      final notified = h.notifications.length;
      h.notifier.usePower(DemoPower.timeExtend);

      expect(h.state, same(afterFirst));
      expect(h.state.extraSecondsToken, 1);
      expect(h.notifications.length, notified);
    });

    test('yanlış güç yok sayılır', () {
      final h = _Harness.create()..notifier.start();
      final before = h.state;

      h.notifier.usePower(DemoPower.skipAll);

      expect(h.state, same(before));
    });
  });

  group('aile / ömür', () {
    test('giriş noktası başına bağımsız demo durumu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
        ..listen(powerDemoProvider(PowerDemoEntryPoint.onboarding), (_, __) {})
        ..listen(powerDemoProvider(PowerDemoEntryPoint.market), (_, __) {});

      container
          .read(powerDemoProvider(PowerDemoEntryPoint.onboarding).notifier)
          .start();

      expect(
        container.read(powerDemoProvider(PowerDemoEntryPoint.onboarding)).phase,
        PowerDemoPhase.awaitingPower,
      );
      expect(
        container.read(powerDemoProvider(PowerDemoEntryPoint.market)).phase,
        PowerDemoPhase.intro,
      );
    });

    test('dinleyici kalmayınca (ekran kapanınca) demo sıfırlanır', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(powerDemoProvider(_entry), (_, __) {});
      container.read(powerDemoProvider(_entry).notifier).start();
      expect(sub.read().phase, PowerDemoPhase.awaitingPower);

      sub.close();
      await container.pump();

      expect(
        container.read(powerDemoProvider(_entry)).phase,
        PowerDemoPhase.intro,
      );
    });
  });

  group('yalıtım', () {
    test(
      'yalıtım: quizRepository/exchangeRepository override\'ları her çağrıda fail eder, '
      'demo uçtan uca biter, hiçbir çağrı yapılmaz',
      () {
        final tripwire = _Tripwire();
        final recorder = _InitRecorder();
        final h = _Harness.create(
          observers: [recorder],
          extra: [
            quizRepositoryProvider.overrideWith((ref) {
              tripwire.providerReads++;
              return _TripwireQuizRepository(tripwire);
            }),
            exchangeRepositoryProvider.overrideWith((ref) {
              tripwire.providerReads++;
              return _TripwireExchangeRepository(tripwire);
            }),
          ],
        )..notifier.start();

        // Yanlış şık da doğru sayılır: demo'nun her dalı sunucusuz biter.
        h.notifier.usePower(DemoPower.timeExtend);
        h.notifier.selectAnswer((h.correctIndex + 1) % 3);
        expect(h.notifier.submit(), isTrue);
        for (var moves = 0; h.state.phase != PowerDemoPhase.finale; moves++) {
          if (moves > 30) fail('demo bitmedi (takıldı: ${h.state.phase})');
          h.passCurrentStep();
        }

        expect(h.state.phase, PowerDemoPhase.finale);
        expect(tripwire.repositoryCalls, 0);
        expect(tripwire.providerReads, 0);
        // Demo yalnız kendi provider'ını ve ekonomi config'i başlatır; quiz/exchange/user/
        // diamond zincirinden hiçbiri ayağa kalkmaz.
        expect(
          recorder.added.toSet(),
          {economyConfigProvider, powerDemoProvider(_entry)},
        );
      },
    );
  });
}
