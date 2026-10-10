import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_body.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_item_card.dart';
import 'package:visibility_detector/visibility_detector.dart';

const _grab = MarketItem(id: 'i1', brandKey: 'GRAB', countryCode: 'TH', currency: 'THB', faceValue: 50, rainbowPrice: 51);

// Aynı öne çıkan kart (aynı kimlik + ürün, Equatable ile eşit) iki bölümde.
const _featured = FeaturedItemView(id: 'fi', item: _grab);
const _first = FeaturedItemsSectionView(id: 'f1', heading: 'Picks', isDraft: false, items: [_featured]);
const _second = FeaturedItemsSectionView(id: 'f2', heading: 'Deals', isDraft: false, items: [_featured]);

void main() {
  setUpAll(() => FormatManager.instance.configure(const Locale('en', 'US')));
  setUp(() => VisibilityDetectorController.instance.updateInterval = Duration.zero);

  testWidgets('aynı ürün iki bölümdeyse tıklama dokunulan kartın bölümüne yazılır', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: MarketBody(
          view: const MarketView(balance: 0, items: [], monthlyCap: null, usedThisMonth: 0, sections: [_first, _second]),
          previewCountry: null,
          onCountrySelected: (_) {},
          onRefresh: () async {},
          onItemTap: (_) {},
          onBannerShown: (_, __) {},
          onBannerTap: (_, __) {},
          onFeaturedShown: (_, __) {},
          onFeaturedTap: (item, section) => taps.add('${section.id}/${item.id}'),
        ),
      ),
    ));
    // DiamondIcon parlaması sonsuz: sınırlı pump (bkz. market_screen_test.dart).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    Finder cardIn(String sectionId) =>
        find.descendant(of: find.byKey(ValueKey(sectionId)), matching: find.byType(MarketItemCard));

    await tester.tap(cardIn('f2'));
    await tester.tap(cardIn('f1'));

    expect(taps, ['f2/fi', 'f1/fi']);
  });
}
