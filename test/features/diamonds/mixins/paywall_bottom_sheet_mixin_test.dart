import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/purchase_outcome.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/features/diamonds/mixins/paywall_bottom_sheet_mixin.dart';
import 'package:qulo_v2/features/diamonds/models/diamond_tier.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

import '../../../helpers/fake_navigation.dart';

/// Paywall satın alması (para): ödeme sürerken sheet kapanırsa (401 çıkışı, deep
/// link) eskiden `if (!mounted) return;` abonelik / günlük hak / elmas tazelemesini
/// atlıyordu — satın alınan Plus hakları ve bakiye bayat kalıyordu.
class _HostPaywall extends PaywallBottomSheetContent {
  const _HostPaywall() : super(trigger: 'swipe_limit');

  @override
  ConsumerState<PaywallBottomSheetContent> createState() => _HostState();
}

class _HostState extends ConsumerState<PaywallBottomSheetContent> with PaywallBottomSheetMixin {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// Sağlayıcıların kaç kez kurulduğu: invalidate edilen sağlayıcı yeniden okununca artar.
final _builds = <String, int>{};
void _count(String name) => _builds[name] = (_builds[name] ?? 0) + 1;

class _GatedSubscription extends SubscriptionNotifier {
  Completer<void>? gate;
  PurchaseOutcome outcome = PurchaseOutcome.success;

  @override
  Future<SubscriptionInfo> build() async {
    _count('subscription');
    return const SubscriptionInfo();
  }

  @override
  Future<PurchaseOutcome> purchaseByProductId(String productId) async {
    await gate?.future;
    return outcome;
  }
}

class _GatedDiamonds extends DiamondNotifier {
  Completer<void>? gate;
  PurchaseOutcome outcome = PurchaseOutcome.success;

  @override
  Future<DiamondBalance> build() async {
    _count('diamond');
    return const DiamondBalance(green: 0, purple: 0);
  }

  @override
  Future<PurchaseOutcome> purchaseByProductId(String productId) async {
    await gate?.future;
    return outcome;
  }
}

class _CountingStats extends DailyStatsNotifier {
  @override
  Future<DailyStats> build() async {
    _count('stats');
    return const DailyStats(
      dailyDiscoversUsed: 0,
      dailyDiscoversLimit: 50,
      dailyUndosUsed: 0,
      dailyUndosLimit: 0,
      questionsCreated: 0,
      questionsLimit: 4,
      monthlyPurpleBonus: 0,
      passportMode: false,
      hasAds: true,
    );
  }
}

void main() {
  late _GatedSubscription subscription;
  late _GatedDiamonds diamonds;
  late ProviderContainer container;
  late FakeNavigationService nav;

  Widget app(Widget home) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Scaffold(body: home),
        ),
      );

  /// Üç sağlayıcı okunmuş (ilk kurulum), host sheet açık.
  Future<_HostState> pump(WidgetTester tester) async {
    await container.read(subscriptionProvider.future);
    await container.read(diamondProvider.future);
    await container.read(dailyStatsProvider.future);
    await tester.pumpWidget(app(const _HostPaywall()));
    await tester.pump();
    return tester.state<_HostState>(find.byType(_HostPaywall));
  }

  Future<void> readAll() async {
    await container.read(subscriptionProvider.future);
    await container.read(diamondProvider.future);
    await container.read(dailyStatsProvider.future);
  }

  setUp(() {
    _builds.clear();
    AnalyticsManager.debugEventSink = (_, __) {};
    subscription = _GatedSubscription();
    diamonds = _GatedDiamonds();
    nav = FakeNavigationService();
    container = ProviderContainer(overrides: [
      navigationServiceProvider.overrideWithValue(nav),
      subscriptionProvider.overrideWith(() => subscription),
      diamondProvider.overrideWith(() => diamonds),
      dailyStatsProvider.overrideWith(_CountingStats.new),
    ]);
    addTearDown(container.dispose);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  testWidgets('abonelik ödemesi sürerken sheet kapanırsa haklar, abonelik ve elmas yine tazelenir',
      (tester) async {
    final state = await pump(tester);
    subscription.gate = Completer<void>();

    final buying = state.handlePurchase('plus');
    await tester.pump();
    await tester.pumpWidget(app(const SizedBox()));
    subscription.gate!.complete();
    await buying;
    await readAll();

    expect(tester.takeException(), isNull);
    expect(_builds, {'subscription': 2, 'diamond': 2, 'stats': 2});
  });

  testWidgets('elmas ödemesi sürerken sheet kapanırsa bakiye yine tazelenir', (tester) async {
    final state = await pump(tester);
    diamonds.gate = Completer<void>();

    final buying = state.handleConsumablePurchase(const PurchasePackage(tier: DiamondTier.starter));
    await tester.pump();
    await tester.pumpWidget(app(const SizedBox()));
    diamonds.gate!.complete();
    await buying;
    await readAll();

    expect(tester.takeException(), isNull);
    expect(_builds['diamond'], 2);
    expect(_builds['stats'], 1, reason: 'elmas paketi günlük hakları değiştirmez');
  });

  /// 2.0.18: abonelikten vazgeçen "satın alma başarısız" görüyordu.
  group('vazgeçme sessiz, gerçek hata mesajlı', () {
    final failed = find.text('Purchase failed');

    testWidgets('abonelikten vazgeçme: hata mesajı yok, sheet açık, düğme yeniden açık', (tester) async {
      final state = await pump(tester);
      subscription.outcome = PurchaseOutcome.cancelled;

      await state.handlePurchase('plus');
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(_HostPaywall), findsOneWidget);
      expect(state.isPurchasing, isFalse);
      expect(_builds['subscription'], 1, reason: 'vazgeçmede haklar tazelenmez');
    });

    testWidgets('abonelikte gerçek hata: "satın alma başarısız" gösterilir', (tester) async {
      final state = await pump(tester);
      subscription.outcome = PurchaseOutcome.failed;

      await state.handlePurchase('premium');
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(failed, findsOneWidget);
      expect(state.isPurchasing, isFalse);
    });

    testWidgets('abonelik başarısı: sheet kapanır, kutlama kök navigator\'dan açılır', (tester) async {
      // Gerçekteki gibi sheet bir sayfanın üstünde: kapanınca altta sayfa kalır.
      await readAll();
      await tester.pumpWidget(app(const SizedBox()));
      await tester.pump();
      final navigator = Navigator.of(tester.element(find.byType(Scaffold)));
      unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => const _HostPaywall())));
      await tester.pumpAndSettle();
      final state = tester.state<_HostState>(find.byType(_HostPaywall));

      await state.handlePurchase('plus');
      await tester.pumpAndSettle();

      expect(find.byType(_HostPaywall), findsNothing);
      expect(nav.dialogs, ['subscription_celebration']);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('elmas paketinden vazgeçme de sessiz', (tester) async {
      final state = await pump(tester);
      diamonds.outcome = PurchaseOutcome.cancelled;

      await state.handleConsumablePurchase(const PurchasePackage(tier: DiamondTier.starter));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      expect(state.isPurchasing, isFalse);
    });

    testWidgets('elmas paketinde gerçek hata mesajlı', (tester) async {
      final state = await pump(tester);
      diamonds.outcome = PurchaseOutcome.failed;

      await state.handleConsumablePurchase(const PurchasePackage(tier: DiamondTier.starter));
      await tester.pump();

      expect(failed, findsOneWidget);
    });
  });
}
