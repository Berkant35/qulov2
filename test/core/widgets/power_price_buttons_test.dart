import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/diamond_buy_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_price_buttons.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../helpers/fixed_user_notifier.dart';

const _half = ExchangeRatePower(name: 'HALF', baseCost: 10, greenCost: 30, purpleCost: 10);

Future<void> _pump(
  WidgetTester tester, {
  required bool rainbowEnabled,
  required ValueChanged<DiamondType> onBuy,
  DiamondType? loadingType,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      userProvider.overrideWith(() => FixedUserNotifier(
            UserModel(id: 'u1', email: 'u1@qulo.test', rainbowEnabled: rainbowEnabled),
          )),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: PowerPriceButtons(
            power: _half,
            quantity: 2,
            loadingType: loadingType,
            onBuy: onBuy,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

Finder _button(DiamondType type) =>
    find.byWidgetPredicate((w) => w is DiamondBuyButton && w.type == type);

void main() {
  testWidgets('rainbow kapalıyken yalnız mor ve yeşil fiyat', (tester) async {
    await _pump(tester, rainbowEnabled: false, onBuy: (_) {});

    expect(find.byType(DiamondBuyButton), findsNWidgets(2));
    expect(_button(DiamondType.rainbow), findsNothing);
  });

  testWidgets('rainbow açıkken üçüncü buton, fiyatı yeşil × adet', (tester) async {
    await _pump(tester, rainbowEnabled: true, onBuy: (_) {});

    expect(find.byType(DiamondBuyButton), findsNWidgets(3));
    expect(tester.widget<DiamondBuyButton>(_button(DiamondType.rainbow)).cost, 60);
    expect(tester.widget<DiamondBuyButton>(_button(DiamondType.purple)).cost, 20);
  });

  testWidgets('Rainbow butonuna dokununca onBuy(rainbow)', (tester) async {
    DiamondType? bought;
    await _pump(tester, rainbowEnabled: true, onBuy: (t) => bought = t);

    await tester.tap(_button(DiamondType.rainbow));

    expect(bought, DiamondType.rainbow);
  });

  testWidgets('yalnız yüklenen türün butonu yükleniyor', (tester) async {
    await _pump(tester, rainbowEnabled: true, onBuy: (_) {}, loadingType: DiamondType.rainbow);

    expect(tester.widget<DiamondBuyButton>(_button(DiamondType.rainbow)).isLoading, isTrue);
    expect(tester.widget<DiamondBuyButton>(_button(DiamondType.green)).isLoading, isFalse);
  });
}
