import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_body.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_item_card.dart';
import 'package:visibility_detector/visibility_detector.dart';

const _dana = MarketItem(
  id: 'i1', brandKey: 'DANA', countryCode: 'ID', currency: 'IDR', faceValue: 1000000, rainbowPrice: 1500,
);

const _view = MarketView(balance: 0, items: [_dana], monthlyCap: null, usedThisMonth: 0, sections: [
  FeaturedItemsSectionView(id: 'f', heading: 'Picks', isDraft: false, items: [FeaturedItemView(id: 'fi', item: _dana)]),
]);

/// Kart yatay listede sabit yükseklikte durur: büyük sistem yazısında (erişilebilirlik) içerik taşmamalı.
Future<void> _pump(WidgetTester tester, double textScale) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: MarketBody(
        view: _view,
        previewCountry: null,
        onCountrySelected: (_) {},
        onRefresh: () async {},
        onItemTap: (_) {},
        onBannerShown: (_, __) {},
        onBannerTap: (_, __) {},
        onFeaturedShown: (_, __) {},
        onFeaturedTap: (_, __) {},
      ),
    ),
  ));
  // DiamondIcon parlaması kapalı olsa da sınırlı pump (bkz. market_screen_test.dart).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() => FormatManager.instance.configure(const Locale('en', 'US')));
  setUp(() => VisibilityDetectorController.instance.updateInterval = Duration.zero);

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('metin ölçeği $scale + uzun kupür (IDR 1,000,000): öne çıkan + katalog kartı taşmaz',
        (tester) async {
      await _pump(tester, scale);
      expect(tester.takeException(), isNull);
      expect(find.byType(MarketItemCard), findsNWidgets(2));
    });
  }

  testWidgets('liste yüksekliği sıkıştırılmış ölçekle büyür; 1.3 üstünde sabit kalır', (tester) async {
    late double at1;
    late double at13;
    late double at2;
    for (final (scale, assign) in [
      (1.0, (double v) => at1 = v),
      (1.3, (double v) => at13 = v),
      (2.0, (double v) => at2 = v),
    ]) {
      await _pump(tester, scale);
      assign(MarketItemCard.extentOf(tester.element(find.byType(MarketBody))));
    }
    expect(at1, MarketItemCard.baseExtent);
    expect(at13, greaterThan(at1));
    expect(at2, at13, reason: 'kart metni en fazla ${MarketItemCard.maxTextScale}x büyür');
  });
}
