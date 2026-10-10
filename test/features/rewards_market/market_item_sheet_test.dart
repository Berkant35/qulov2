import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/rewards_market/mixins/market_item_sheet_mixin.dart';
import 'package:qulo_v2/features/rewards_market/providers/market_provider.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_item_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fixed_user_notifier.dart';

const _item = MarketItem(id: 'i1', brandKey: 'GRAB', countryCode: 'TH', currency: 'THB', faceValue: 50, rainbowPrice: 51);

const _success = RedeemResult(
  redemption: Redemption(
    id: 'r1',
    status: RedemptionStatus.pending,
    brandKey: 'GRAB',
    countryCode: 'TH',
    currency: 'THB',
    faceValue: 50,
    rainbowPrice: 51,
  ),
  balance: 898,
);

/// Başarı testi: gerçek `NavigationService` router/rootNavigatorKey ister — burada
/// yalnız "`closeOverlay` çağrıldı mı" sorusu sınanır (bkz. power_purchase_sheet_test.dart
/// `_RecordingNavigationService` kalıbı).
class _RecordingNavigationService implements NavigationService {
  int closeOverlayCalls = 0;

  @override
  void closeOverlay<T>([T? result]) => closeOverlayCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_RecordingNavigationService.${invocation.memberName}');
}

// NOT: RedeemSummary/SummaryRow icindeki DiamondIcon.rainbow kendi parlama
// animasyonunu sonsuz `repeat()` ile calistirir (bkz. market_screen_test.dart) —
// bu yuzden agacta DiamondIcon varken pumpAndSettle() hicbir zaman "sakinlesmez"
// ve timeout atar. Sinirli pump() ile ayni niyeti (async islerin cozulmesini
// beklemek) koruyoruz.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeRewardsRepository repo, {
  int balance = 1000,
  List<Override> extraOverrides = const [],
}) async {
  repo.market ??= MarketView(balance: balance, items: const [_item], monthlyCap: 150, usedThisMonth: 20);
  final container = ProviderContainer(overrides: [
    rewardsRepositoryProvider.overrideWithValue(repo),
    userProvider.overrideWith(() => FixedUserNotifier(
          UserModel(id: 'u1', email: 'u1@qulo.test', rainbowEnabled: true, rainbowDiamonds: balance),
        )),
    ...extraOverrides,
  ]);
  addTearDown(container.dispose);
  await container.read(userProvider.future);
  await container.read(marketProvider.notifier).load();
  await tester.pumpWidget(_app(container, const MarketItemSheet(item: _item, sourceItemId: 'b1')));
  await _settle(tester);
  return container;
}

/// Aynı MaterialApp (kök ScaffoldMessenger korunur); `body` değişince sayfa ağaçtan çıkar.
Widget _app(ProviderContainer container, Widget body) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: body),
      ),
    );

void main() {
  setUpAll(() => FormatManager.instance.configure(const Locale('en', 'US')));

  testWidgets('özet: fiyat, işlem sonrası bakiye, aylık kullanım, nasıl kullanılır', (tester) async {
    await _pump(tester, FakeRewardsRepository());
    expect(find.text('949'), findsOneWidget);
    expect(find.text('Used this month: 20 / 150'), findsOneWidget);
    expect(find.textContaining('Grab app'), findsOneWidget);
  });

  testWidgets('bakiye yetmezse buton kapalı + yetersiz mesajı + ipucu', (tester) async {
    final repo = FakeRewardsRepository();
    await _pump(tester, repo, balance: 10);
    expect(find.text("You don't have enough Rainbow"), findsOneWidget);
    expect(find.text('You earn Rainbow when others spend purchased purple diamonds on your questions.'), findsOneWidget);
    await tester.tap(find.text('Redeem'));
    await tester.pump();
    expect(repo.redeemCalls, isEmpty);
  });

  testWidgets('tavan hatası sayfada kalır; tekrar denemede aynı anahtar + kaynak kart', (tester) async {
    final repo = FakeRewardsRepository(
      redeemFailure: const ServerFailure(code: 'REWARD_MONTHLY_CAP', params: {'cap': 150, 'used': 140}),
    );
    await _pump(tester, repo);
    await tester.tap(find.text('Redeem'));
    await _settle(tester);
    expect(find.text("You've reached this month's limit (140/150)"), findsOneWidget);
    await tester.tap(find.text('Redeem'));
    await _settle(tester);
    expect(repo.redeemCalls, hasLength(2));
    expect(repo.redeemCalls[0].idempotencyKey, repo.redeemCalls[1].idempotencyKey);
    expect(repo.redeemCalls.every((c) => c.sourceItemId == 'b1'), isTrue);
  });

  testWidgets('istek sürerken ikinci dokunuş istek atmaz; ikinci submit başlangıç olayı da atmaz', (tester) async {
    final events = <String>[];
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
    addTearDown(() => AnalyticsManager.debugEventSink = null);
    final repo = FakeRewardsRepository(redeemFailure: const NetworkFailure())..redeemGate = Completer<void>();
    await _pump(tester, repo);
    await tester.tap(find.text('Redeem'));
    await tester.pump();
    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    await tester.state<MarketItemSheetMixin>(find.byType(MarketItemSheet)).submit();
    await tester.pump();
    expect(repo.redeemCalls, hasLength(1));
    expect(events.where((e) => e == AnalyticsEvents.marketRedeemStart), hasLength(1));
    repo.redeemGate!.complete();
    await _settle(tester);
  });

  testWidgets('sunucu yetersiz derse satır içi hata + market zorla yenilenir (yerel bakiye bayattı)',
      (tester) async {
    final repo = FakeRewardsRepository(redeemFailure: const ServerFailure(code: 'INSUFFICIENT_DIAMONDS'));
    await _pump(tester, repo);
    await tester.tap(find.text('Redeem'));
    await _settle(tester);
    expect(find.text("You don't have enough Rainbow"), findsOneWidget);
    expect(repo.marketCountries, hasLength(2));
  });

  testWidgets('RAINBOW_NOT_AVAILABLE: kullanıcı + market yenilenir, sayfa kapanır', (tester) async {
    final users = FakeUserRepository(const UserModel(id: 'u1', email: 'u1@qulo.test', rainbowEnabled: false));
    final repo = FakeRewardsRepository(
      redeemFailure: const ServerFailure(code: 'RAINBOW_NOT_AVAILABLE', statusCode: 403),
    );
    final nav = _RecordingNavigationService();
    await _pump(tester, repo, extraOverrides: [
      navigationServiceProvider.overrideWithValue(nav),
      userRepositoryProvider.overrideWithValue(users),
    ]);
    repo.marketFailure = const ServerFailure(code: 'RAINBOW_NOT_AVAILABLE', statusCode: 403);
    await tester.tap(find.text('Redeem'));
    await _settle(tester);
    expect(users.getMeCallCount, 1);
    expect(repo.marketCountries, hasLength(2), reason: 'market de zorla yenilenir (eski katalog kalmasın)');
    expect(nav.closeOverlayCalls, 1);
    expect(find.text('Rainbow Diamonds are not available for your account right now.'), findsOneWidget);
  });

  testWidgets('409 DUPLICATE_REQUEST: sayfa kapanır, "işleniyor" + Görüntüle, market yenilenir', (tester) async {
    final repo = FakeRewardsRepository(
      redeemFailure: const ServerFailure(code: 'DUPLICATE_REQUEST', statusCode: 409),
    );
    final nav = _RecordingNavigationService();
    await _pump(tester, repo, extraOverrides: [navigationServiceProvider.overrideWithValue(nav)]);
    await tester.tap(find.text('Redeem'));
    await _settle(tester);
    expect(nav.closeOverlayCalls, 1);
    expect(find.text('Your request is being processed; it will appear in My gift cards shortly.'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(repo.marketCountries, hasLength(2));
  });

  testWidgets('istek sürerken sayfa kapanırsa: sonuç yine uygulanır, overlay KAPATILMAZ, snackbar gösterilir',
      (tester) async {
    final repo = FakeRewardsRepository(redeemResult: _success)..redeemGate = Completer<void>();
    final nav = _RecordingNavigationService();
    final container = await _pump(tester, repo, extraOverrides: [navigationServiceProvider.overrideWithValue(nav)]);
    repo.marketGate = Completer<void>();

    await tester.tap(find.text('Redeem'));
    await tester.pump();
    await tester.pumpWidget(_app(container, const SizedBox()));
    expect(find.byType(MarketItemSheet), findsNothing);

    repo.redeemGate!.complete();
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(container.read(userProvider).valueOrNull?.rainbowDiamonds, 898, reason: 'bakiye bayat-yüksek kalmaz');
    final market = container.read(marketProvider).valueOrNull!;
    expect(market.balance, 898);
    expect(market.usedThisMonth, 71);
    expect(repo.marketCountries, hasLength(2), reason: 'market zorla yenilenir');
    expect(nav.closeOverlayCalls, 0, reason: 'sayfa yokken closeOverlay kök yığındaki rotayı kapatırdı');
    expect(find.text('Request received'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);

    repo.marketGate!.complete();
    await _settle(tester);
  });

  testWidgets('başarı: bakiye Rainbow + market yerelde uygulanır, market zorla yenilenir, overlay kapanır + snackbar',
      (tester) async {
    final repo = FakeRewardsRepository(redeemResult: _success);
    final nav = _RecordingNavigationService();
    final container = await _pump(tester, repo, extraOverrides: [navigationServiceProvider.overrideWithValue(nav)]);

    expect(repo.marketCountries, hasLength(1), reason: '_pump içindeki ilk load()');
    // Yenileme yanıtı bekletilir: aşağıdaki değerler yerel uygulamadan gelmeli, yenilemeden değil.
    repo.marketGate = Completer<void>();

    await tester.tap(find.text('Redeem'));
    await _settle(tester);

    expect(container.read(userProvider).valueOrNull?.rainbowDiamonds, 898,
        reason: 'applyRainbow(result.balance)');
    final market = container.read(marketProvider).valueOrNull!;
    expect(market.balance, 898, reason: 'applyRedeem: tek bakiye kaynağı');
    expect(market.usedThisMonth, 71, reason: 'bu ay kullanım += fiyat');
    expect(repo.marketCountries, hasLength(2), reason: 'başarıda market.load(force: true) tekrar çağrılır');
    expect(nav.closeOverlayCalls, 1);
    expect(find.text('Request received'), findsOneWidget);

    // Sunucu gerçeği (itfa sonrası) gelince ikisi hâlâ aynı sayıyı gösterir.
    repo.market = const MarketView(balance: 898, items: [_item], monthlyCap: 150, usedThisMonth: 71);
    repo.marketGate!.complete();
    await _settle(tester);
    expect(container.read(userProvider).valueOrNull?.rainbowDiamonds, 898);
    expect(container.read(marketProvider).valueOrNull?.balance, 898);
  });
}
