import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/power_purchase.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/power_quantity_stepper.dart';

/// Adet seçici sunucunun kabul ettiği aralıkta kalmalı: eskiden üst sınır 99'du,
/// sunucu 50'nin üstünü 400 VALIDATION_ERROR ile reddediyordu.
Future<List<int>> _pump(WidgetTester tester, int quantity) async {
  final changes = <int>[];
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Center(
        child: PowerQuantityStepper(quantity: quantity, onChanged: changes.add),
      ),
    ),
  ));
  return changes;
}

Future<void> _tapIcon(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await tester.pump();
}

void main() {
  test('sınırlar sunucuyla aynı (exchange.validator.ts: min 1, max 50)', () {
    expect(powerPurchaseMinQuantity, 1);
    expect(powerPurchaseMaxQuantity, 50);
  });

  testWidgets('üst sınırda + onChanged çağırmaz', (tester) async {
    final changes = await _pump(tester, powerPurchaseMaxQuantity);

    await _tapIcon(tester, Icons.add);

    expect(changes, isEmpty);
  });

  testWidgets('alt sınırda − onChanged çağırmaz', (tester) async {
    final changes = await _pump(tester, powerPurchaseMinQuantity);

    await _tapIcon(tester, Icons.remove);

    expect(changes, isEmpty);
  });

  testWidgets('arada + ve − birer adım değiştirir', (tester) async {
    final changes = await _pump(tester, 10);

    await _tapIcon(tester, Icons.add);
    await _tapIcon(tester, Icons.remove);

    expect(changes, [11, 9]);
  });

  testWidgets('üst sınırın bir altında + hâlâ çalışır', (tester) async {
    final changes = await _pump(tester, powerPurchaseMaxQuantity - 1);

    await _tapIcon(tester, Icons.add);

    expect(changes, [powerPurchaseMaxQuantity]);
  });
}
