import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';

Future<void> _pump(WidgetTester tester, Widget child, {ThemeData? theme}) async {
  await tester.pumpWidget(MaterialApp(
    theme: theme ?? AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  ));
}

String? _assetOf(WidgetTester tester) {
  final loader = tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader;
  return loader is SvgAssetLoader ? loader.assetName : null;
}

void main() {
  test('apiName sunucu diamond_type değerleriyle aynı (exchange.validator)', () {
    expect(DiamondType.values.map((t) => t.apiName), ['PURPLE', 'GREEN', 'RAINBOW']);
  });

  test('Prizma SVG varyantları pakette var', () {
    for (final path in [
      AppAssets.rainbowDiamond,
      AppAssets.rainbowDiamondSlideLeft,
      AppAssets.rainbowDiamondSlideRight,
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(file.readAsStringSync(), contains('<svg'), reason: path);
    }
  });

  testWidgets('DiamondIcon.rainbow Prizma SVG\'sini çizer', (tester) async {
    await _pump(tester, const DiamondIcon.rainbow(size: 24, showGlow: false));
    expect(_assetOf(tester), AppAssets.rainbowDiamond);
  });

  testWidgets('mor ve yeşil varlıkları değişmez', (tester) async {
    await _pump(tester, const DiamondIcon.purple(size: 24, showGlow: false));
    expect(_assetOf(tester), AppAssets.purpleDiamond);
    await _pump(tester, const DiamondIcon.green(size: 24, showGlow: false));
    expect(_assetOf(tester), AppAssets.greenDiamond);
  });

  testWidgets('ışımalı rainbow koyu ve açık temada hatasız çizilir', (tester) async {
    for (final theme in [AppTheme.dark, AppTheme.light]) {
      await _pump(tester, const DiamondIcon.rainbow(size: 32), theme: theme);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mor ışıma temaya uyar: açık temada koyu mor, koyu temada neon mor', (tester) async {
    int ambientRgb() {
      final glow = tester
          .widgetList<Container>(find.descendant(of: find.byType(DiamondIcon), matching: find.byType(Container)))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.gradient is RadialGradient);
      return (glow.gradient! as RadialGradient).colors.first.toARGB32() & 0x00FFFFFF;
    }

    await _pump(tester, const DiamondIcon.purple(size: 32), theme: AppTheme.light);
    await tester.pump(const Duration(milliseconds: 100));
    expect(ambientRgb(), AppColorsResolved.light.primary.toARGB32() & 0x00FFFFFF);

    await _pump(tester, const DiamondIcon.purple(size: 32), theme: AppTheme.dark);
    await tester.pump(const Duration(milliseconds: 100));
    expect(ambientRgb(), AppColorsResolved.dark.primary.toARGB32() & 0x00FFFFFF);

    await tester.pumpWidget(const SizedBox());
  });

  test('diamondTypeFromApi: sunucu değerleri, küçük harf, bilinmeyen → purple', () {
    expect(diamondTypeFromApi('PURPLE'), DiamondType.purple);
    expect(diamondTypeFromApi('GREEN'), DiamondType.green);
    expect(diamondTypeFromApi('RAINBOW'), DiamondType.rainbow);
    expect(diamondTypeFromApi('rainbow'), DiamondType.rainbow);
    expect(diamondTypeFromApi('SOMETHING'), DiamondType.purple);
  });
}
