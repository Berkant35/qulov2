import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_network_svg.dart';
import 'package:qulo_v2/features/rewards_market/widgets/brand_logo.dart';

Future<void> _pump(WidgetTester tester, String? logoUrl) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(body: BrandLogo(brandKey: 'GRAB', logoUrl: logoUrl)),
  ));
  await tester.pump();
}

/// Ağdan SVG kuralı: SVG logo resim yükleyiciye verilmez (çözemez, hata widget'ına düşer) ve
/// ham `SvgPicture.network` kullanılmaz (hata Crashlytics'e fatal düşer) — `AppNetworkSvg`.
void main() {
  testWidgets('.svg logo AppNetworkSvg ile çizilir, resim yükleyiciyle değil', (tester) async {
    await _pump(tester, 'https://cdn.example/logos/grab.svg');
    expect(find.byType(AppNetworkSvg), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('resim logo önbellekli resimle çizilir', (tester) async {
    await _pump(tester, 'https://cdn.example/logos/grab.png');
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(find.byType(AppNetworkSvg), findsNothing);
  });

  testWidgets('logo yoksa baş harf rozeti', (tester) async {
    await _pump(tester, null);
    expect(find.text('G'), findsOneWidget);
    expect(find.byType(AppNetworkSvg), findsNothing);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });
}
