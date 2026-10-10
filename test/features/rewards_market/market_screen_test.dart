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
import 'package:qulo_v2/core/widgets/draft_badge.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/mixins/market_screen_mixin.dart';
import 'package:qulo_v2/features/rewards_market/screens/market_screen.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_body.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/fake_repositories.dart';

const _grabTh = MarketItem(id: 'i1', brandKey: 'GRAB', countryCode: 'TH', currency: 'THB', faceValue: 50, rainbowPrice: 51);
const _danaId = MarketItem(id: 'i2', brandKey: 'DANA', countryCode: 'ID', currency: 'IDR', faceValue: 10000, rainbowPrice: 20);

// NOT: RainbowBalanceChip/MarketItemCard icindeki DiamondIcon kendi parlama
// animasyonunu sonsuz `repeat()` ile calistirir (bkz. test/features/diamonds/
// purchase_grid_test.dart) — bu yuzden agacta DiamondIcon varken
// pumpAndSettle() hicbir zaman "sakinlesmez" ve timeout atar. Ayni niyeti
// (marketProvider.load()'un cozulmesini beklemek) sinirli pump() ile koruyoruz.
/// Ürün sayfası açılışını kaydeder (gerçek servis router/rootNavigatorKey ister).
class _RecordingNavigationService implements NavigationService {
  final sheets = <AppBottomSheet>[];

  @override
  Future<T?> showAppBottomSheet<T>(AppBottomSheet sheet) async {
    sheets.add(sheet);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_RecordingNavigationService.${invocation.memberName}');
}

Future<FakeRewardsRepository> _pump(
  WidgetTester tester,
  FakeRewardsRepository repo, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [rewardsRepositoryProvider.overrideWithValue(repo), ...overrides],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: const MarketScreen(),
    ),
  ));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return repo;
}

void main() {
  setUpAll(() => FormatManager.instance.configure(const Locale('en', 'US')));
  setUp(() => VisibilityDetectorController.instance.updateInterval = Duration.zero);

  testWidgets('katalog marka gruplarıyla; bakiye çipi; önizleme çipi yoksa ülke seçici yok', (tester) async {
    await _pump(tester, FakeRewardsRepository(
      market: const MarketView(balance: 1000, items: [_grabTh, _danaId], monthlyCap: 150, usedThisMonth: 0),
    ));
    // R1: marka etiketi hem grup başlığında hem MarketItemCard'da çizilir.
    expect(find.text('Grab'), findsWidgets);
    expect(find.text('DANA'), findsWidgets);
    expect(find.text('1000'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('test admin: çipler; ülke seçimi istek parametresi olur', (tester) async {
    final repo = await _pump(tester, FakeRewardsRepository(
      market: const MarketView(balance: 1, items: [_grabTh], monthlyCap: null, usedThisMonth: 0,
          previewCountries: ['TH', 'ID', 'MY']),
    ));
    expect(find.byType(ChoiceChip), findsNWidgets(4));
    await tester.tap(find.text('TH'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.marketCountries, [null, 'TH']);
  });

  testWidgets('taslak bölüm rozeti + boş katalog mesajı', (tester) async {
    await _pump(tester, FakeRewardsRepository(
      market: const MarketView(balance: 0, items: [], monthlyCap: null, usedThisMonth: 0, sections: [
        FeaturedItemsSectionView(id: 'f', heading: 'Picks', isDraft: true, items: [FeaturedItemView(id: 'fi', item: _grabTh)]),
      ]),
    ));
    expect(find.byType(DraftBadge), findsOneWidget);
    expect(find.text('No gift cards in this country yet'), findsOneWidget);
  });

  testWidgets('erişim kapalı: yeniden dene olmadan Rainbow mesajı', (tester) async {
    await _pump(tester, FakeRewardsRepository(
      marketFailure: const ServerFailure(code: 'RAINBOW_NOT_AVAILABLE', statusCode: 403),
    ));
    expect(find.text('Rainbow Diamonds are not available for your account right now.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('yükleme sürerken ekran kapanırsa mounted kontrolü sayesinde hata fırlatmaz', (tester) async {
    final gate = Completer<void>();
    final repo = FakeRewardsRepository(
      market: const MarketView(balance: 5, items: [_grabTh], monthlyCap: null, usedThisMonth: 0),
    )..marketGate = gate;

    Widget app(Widget home) => ProviderScope(
          overrides: [rewardsRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: const [AppLocalizationsDelegate()],
            supportedLocales: const [Locale('en')],
            locale: const Locale('en'),
            home: home,
          ),
        );

    await tester.pumpWidget(app(const MarketScreen()));
    await tester.pump(); // initMixin() -> Future.microtask -> getMarket() çağrıldı, gate'te bekliyor

    // Ekran kapanır (aynı ProviderScope/container hayatta kalır, yalnız MarketScreen State'i dispose olur) —
    // yükleme hâlâ gate'te bekliyor.
    await tester.pumpWidget(app(const SizedBox()));
    await tester.pump();

    // Gate'i şimdi aç: load() tamamlanır; mounted artık false → mounted kontrolü olmasaydı
    // dispose olmuş State üzerinde ref kullanımı Riverpod'u fırlatırdı.
    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });

  group('GA4', () {
    late List<Map<String, Object?>> events;

    setUp(() {
      events = [];
      AnalyticsManager.debugEventSink = (name, params) => events.add({'event': name, ...?params});
    });
    tearDown(() => AnalyticsManager.debugEventSink = null);

    Iterable<Map<String, Object?>> named(String event) => events.where((e) => e['event'] == event);

    testWidgets('market_view başarılı yüklemeden sonra; ülke = ilk katalog ürününün ülkesi', (tester) async {
      await _pump(tester, FakeRewardsRepository(
        market: const MarketView(balance: 1, items: [_grabTh, _danaId], monthlyCap: null, usedThisMonth: 0),
      ));
      expect(named(AnalyticsEvents.marketView).single[AnalyticsEvents.paramCountry], 'TH');
    });

    testWidgets('market_view boş katalogda NONE', (tester) async {
      await _pump(tester, FakeRewardsRepository());
      expect(named(AnalyticsEvents.marketView).single[AnalyticsEvents.paramCountry], 'NONE');
    });

    testWidgets('yükleme hatasında market_view ATILMAZ', (tester) async {
      await _pump(tester, FakeRewardsRepository(marketFailure: const NetworkFailure()));
      expect(named(AnalyticsEvents.marketView), isEmpty);
    });

    testWidgets('taslak bölüm tıklamaları GA4\'e gitmez; yayındaki gider; ürün sayfası uzun açılır',
        (tester) async {
      final nav = _RecordingNavigationService();
      await _pump(
        tester,
        FakeRewardsRepository(market: const MarketView(balance: 1, items: [_grabTh], monthlyCap: null, usedThisMonth: 0)),
        overrides: [navigationServiceProvider.overrideWithValue(nav)],
      );
      final screen = tester.state<MarketScreenMixin>(find.byType(MarketScreen));
      const featured = FeaturedItemView(id: 'fi', item: _grabTh);
      const banner = BannerItemView(id: 'b1', imageUrl: 'https://cdn.example/b.png', title: 'T');
      FeaturedItemsSectionView featuredSection({required bool draft}) =>
          FeaturedItemsSectionView(id: 'f', heading: null, isDraft: draft, items: const [featured]);
      BannerCarouselSectionView bannerSection({required bool draft}) =>
          BannerCarouselSectionView(id: 'b', heading: null, isDraft: draft, autoplaySeconds: 0, items: const [banner]);

      screen.onFeaturedTap(featured, featuredSection(draft: true));
      screen.onBannerTap(banner, bannerSection(draft: true));
      expect(named(AnalyticsEvents.marketFeaturedClick), isEmpty);
      expect(named(AnalyticsEvents.marketBannerClick), isEmpty);
      expect(nav.sheets, hasLength(1), reason: 'taslakta da ürün sayfası açılır (önizleme)');
      expect(nav.sheets.single.maxHeightFactor, AppBottomSheet.tallHeightFactor);

      screen.onFeaturedTap(featured, featuredSection(draft: false));
      screen.onBannerTap(banner, bannerSection(draft: false));
      expect(named(AnalyticsEvents.marketFeaturedClick), hasLength(1));
      expect(named(AnalyticsEvents.marketBannerClick), hasLength(1));
    });
  });

  testWidgets('pull-to-refresh hatası: liste kalır + hata snackbar\'ı', (tester) async {
    final repo = await _pump(tester, FakeRewardsRepository(
      market: const MarketView(balance: 5, items: [_grabTh], monthlyCap: null, usedThisMonth: 0),
    ));
    repo.marketFailure = const NetworkFailure();

    await tester.state<MarketScreenMixin>(find.byType(MarketScreen)).refresh();
    await tester.pump();

    expect(find.byType(MarketBody), findsOneWidget, reason: 'önceki veri korunur');
    expect(find.text('No internet connection. Please try again.'), findsOneWidget);
  });

  testWidgets('ilk yükleme hatasında yeniden dene snackbar göstermez (hata görünümü zaten ekranda)',
      (tester) async {
    await _pump(tester, FakeRewardsRepository(marketFailure: const NetworkFailure()));

    await tester.state<MarketScreenMixin>(find.byType(MarketScreen)).refresh();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}
