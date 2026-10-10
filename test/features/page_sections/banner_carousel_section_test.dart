import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/page_sections/widgets/banner_carousel_section.dart';
import 'package:visibility_detector/visibility_detector.dart';

BannerCarouselSectionView _section({int autoplay = 5}) => BannerCarouselSectionView(
      id: 's', heading: null, isDraft: false, autoplaySeconds: autoplay,
      items: const [
        BannerItemView(id: 'b1', imageUrl: 'https://x/1.jpg', title: 'One'),
        BannerItemView(id: 'b2', imageUrl: 'https://x/2.jpg', title: 'Two'),
      ],
    );

/// Aynı `id` — sunucudan yeniden geldiğinde `PageSectionList`'in `ValueKey(section.id)`'i
/// sayesinde State korunur (`didUpdateWidget` tetiklenir); bu ikisi o senaryoyu simüle eder.
BannerCarouselSectionView _section3({int autoplay = 0}) => BannerCarouselSectionView(
      id: 's3', heading: null, isDraft: false, autoplaySeconds: autoplay,
      items: const [
        BannerItemView(id: 'c1', imageUrl: 'https://x/1.jpg', title: 'One'),
        BannerItemView(id: 'c2', imageUrl: 'https://x/2.jpg', title: 'Two'),
        BannerItemView(id: 'c3', imageUrl: 'https://x/3.jpg', title: 'Three'),
      ],
    );

BannerCarouselSectionView _section3Shrunk() => const BannerCarouselSectionView(
      id: 's3', heading: null, isDraft: false, autoplaySeconds: 0,
      items: [BannerItemView(id: 'c1', imageUrl: 'https://x/1.jpg', title: 'One')],
    );

Future<List<String>> _pump(WidgetTester tester, BannerCarouselSectionView section) async {
  final shown = <String>[];
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(
      body: BannerCarouselSection(section: section, onShown: (i) => shown.add(i.id), onTap: (_) {}),
    ),
  ));
  await tester.pump();
  await tester.pump();
  return shown;
}

void main() {
  setUp(() => VisibilityDetectorController.instance.updateInterval = Duration.zero);

  testWidgets('otomatik kayma: süre dolunca sonraki sayfa + gösterim', (tester) async {
    final shown = await _pump(tester, _section());
    expect(shown, ['b1']);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(shown, ['b1', 'b2']);
  });

  testWidgets('autoplay 0 ise kaymaz', (tester) async {
    final shown = await _pump(tester, _section(autoplay: 0));
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();
    expect(shown, ['b1']);
  });

  testWidgets('parmak ekrandayken kaymaz', (tester) async {
    final shown = await _pump(tester, _section());
    final gesture = await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await tester.pump(const Duration(seconds: 6));
    expect(shown, ['b1']);
    await gesture.up();
  });

  testWidgets('aynı id daha az öğeyle güncellenince eski sayfa kırpılır, hata fırlatmaz', (tester) async {
    final shown = <String>[];
    final scrollController = ScrollController();

    // Bölüm başta ekran dışında (2000px altta) — sunucudan tekrar geldiğinde State'in
    // korunduğu, `ValueKey(section.id)` ile aynı yuvada güncellendiği senaryoyu kurmak
    // için tek bir kaydırılabilir ağaç kullanılıyor (PageSectionList'teki gibi).
    Widget page(BannerCarouselSectionView section) => MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 2000),
                  BannerCarouselSection(section: section, onShown: (i) => shown.add(i.id), onTap: (_) {}),
                ],
              ),
            ),
          ),
        );

    await tester.pumpWidget(page(_section3()));
    await tester.pump();
    expect(shown, isEmpty); // henüz ekran dışında

    scrollController.jumpTo(2000);
    await tester.pump();
    await tester.pump();
    expect(shown, ['c1']);

    // Son sayfaya kaydır (currentPage = 2). Tek büyük sürükleme ara sayfalardan geçebilir;
    // önemli olan son durak — bu yüzden tam listeyi değil son öğeyi doğruluyoruz.
    await tester.drag(find.byType(PageView), const Offset(-3000, 0));
    await tester.pumpAndSettle();
    expect(shown.last, 'c3');

    // Ekran dışına kaydır — görünürlük kaybolur.
    scrollController.jumpTo(0);
    await tester.pump();
    await tester.pump();

    // Sunucudan aynı id, TEK öğeli bölüm geldi — currentPage (2) artık aralık dışı.
    await tester.pumpWidget(page(_section3Shrunk()));
    await tester.pump();

    // Yeniden görünür ol — düzeltme olmadan `items[currentPage]` RangeError fırlatırdı.
    scrollController.jumpTo(2000);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(shown.last, 'c1');
    expect(find.text('One'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('aynı id autoplay 0 ile güncellenince zamanlayıcı durur', (tester) async {
    final shown = <String>[];
    Widget page(BannerCarouselSectionView section) => MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Scaffold(
            body: BannerCarouselSection(section: section, onShown: (i) => shown.add(i.id), onTap: (_) {}),
          ),
        );

    await tester.pumpWidget(page(_section(autoplay: 5)));
    await tester.pump();
    expect(shown, ['b1']);

    // Aynı id, otomatik kayma kapatıldı — eski 5sn'lik zamanlayıcı iptal edilmeli.
    await tester.pumpWidget(page(_section(autoplay: 0)));
    await tester.pump();

    // Eski aralık (5sn) dolsa dahi artık kaymamalı; kalan bir zamanlayıcı da kalmamalı.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(shown, ['b1']);

    await tester.pumpWidget(const SizedBox());
  });
}
