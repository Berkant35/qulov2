import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/draft_badge.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/page_sections/widgets/page_section_list.dart';
import 'package:visibility_detector/visibility_detector.dart';

const _item = MarketItem(id: 'i1', brandKey: 'GRAB', countryCode: 'TH', currency: 'THB', faceValue: 50, rainbowPrice: 51);

Future<void> _pump(WidgetTester tester, List<PageSectionView> sections, {List<String>? shown, List<String>? taps}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(
      body: SingleChildScrollView(
        child: PageSectionList(
          sections: sections,
          featuredItemExtent: 80,
          featuredItemBuilder: (_, f, __) => SizedBox(width: 100, child: Text('card ${f.item.id}')),
          onBannerShown: (item, _) => shown?.add(item.id),
          onBannerTap: (item, _) => taps?.add(item.id),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  setUp(() => VisibilityDetectorController.instance.updateInterval = Duration.zero);

  testWidgets('bölümler sunucu sırasıyla; taslakta rozet; başlık çizilir', (tester) async {
    await _pump(tester, const [
      FeaturedItemsSectionView(id: 'f', heading: 'Featured', isDraft: true,
          items: [FeaturedItemView(id: 'fi', item: _item)]),
      BannerCarouselSectionView(id: 'b', heading: null, isDraft: false, autoplaySeconds: 0,
          items: [BannerItemView(id: 'b1', imageUrl: 'https://x/b1.jpg', title: 'Hello', ctaLabel: 'Go')]),
    ]);
    expect(find.text('Featured'), findsOneWidget);
    expect(find.byType(DraftBadge), findsOneWidget);
    expect(find.text('DRAFT'), findsOneWidget);
    expect(find.text('card i1'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Go'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Featured')).dy, lessThan(tester.getTopLeft(find.text('Hello')).dy));
  });

  testWidgets('banner görünür olunca gösterim, dokununca tıklama', (tester) async {
    final shown = <String>[];
    final taps = <String>[];
    await _pump(tester, const [
      BannerCarouselSectionView(id: 'b', heading: null, isDraft: false, autoplaySeconds: 0,
          items: [BannerItemView(id: 'b1', imageUrl: 'https://x/b1.jpg', title: 'Hello')]),
    ], shown: shown, taps: taps);
    await tester.pump();
    expect(shown, ['b1']);
    await tester.tap(find.text('Hello'));
    expect(taps, ['b1']);
  });

  testWidgets('öne çıkan kart kendi bölümüyle kurulur (aynı ürün iki bölümde olsa da)', (tester) async {
    const featured = FeaturedItemView(id: 'fi', item: _item);
    final built = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PageSectionList(
            sections: const [
              FeaturedItemsSectionView(id: 'f1', heading: null, isDraft: false, items: [featured]),
              FeaturedItemsSectionView(id: 'f2', heading: null, isDraft: false, items: [featured]),
            ],
            featuredItemExtent: 80,
            featuredItemBuilder: (_, item, section) {
              built.add('${section.id}/${item.id}');
              return const SizedBox(width: 100);
            },
            onBannerShown: (_, __) {},
            onBannerTap: (_, __) {},
          ),
        ),
      ),
    ));
    expect(built, ['f1/fi', 'f2/fi']);
  });
}
