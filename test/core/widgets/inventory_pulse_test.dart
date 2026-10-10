import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/inventory_pulse.dart';

Widget _app(int count) => MaterialApp(
      home: Center(
        child: InventoryPulse(count: count, glowColor: Colors.purple, child: const SizedBox.square(dimension: 20)),
      ),
    );

double _scaleOf(WidgetTester tester) => tester
    .widget<Transform>(find.descendant(of: find.byType(InventoryPulse), matching: find.byType(Transform)))
    .transform
    .getMaxScaleOnAxis();

bool _glowing(WidgetTester tester) {
  final box = tester.widget<Container>(
    find.descendant(of: find.byType(InventoryPulse), matching: find.byType(Container)).first,
  );
  return (box.decoration! as BoxDecoration).boxShadow != null;
}

void main() {
  testWidgets('ilk çizimde oynamaz', (tester) async {
    await tester.pumpWidget(_app(2));
    expect(_scaleOf(tester), 1.0);
    expect(_glowing(tester), isFalse);
  });

  testWidgets('sayı artınca büyüyüp ışır, süre sonunda eski haline döner', (tester) async {
    await tester.pumpWidget(_app(2));
    await tester.pumpWidget(_app(3));
    await tester.pump(InventoryPulse.duration * 0.4);

    expect(_scaleOf(tester), greaterThan(1.0));
    expect(_glowing(tester), isTrue);

    await tester.pumpAndSettle();
    expect(_scaleOf(tester), 1.0);
    expect(_glowing(tester), isFalse);
  });

  testWidgets('sayı azalınca ya da aynı kalınca oynamaz', (tester) async {
    await tester.pumpWidget(_app(3));
    await tester.pumpWidget(_app(2));
    await tester.pump(InventoryPulse.duration * 0.4);
    expect(_glowing(tester), isFalse);

    await tester.pumpWidget(_app(2));
    await tester.pump(InventoryPulse.duration * 0.4);
    expect(_glowing(tester), isFalse);
    expect(_scaleOf(tester), 1.0);
  });
}
