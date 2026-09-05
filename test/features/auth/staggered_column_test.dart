import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/auth/widgets/staggered_column.dart';

/// Login formu videoya bağlı olarak açılıyordu; video yüklenemezse form hiç
/// görünmüyordu (siyah ekran). Emniyet süresi dolunca kolon kendini açmalı.
void main() {
  Widget host({Duration? autoForwardAfter}) => MaterialApp(
        home: Scaffold(
          body: StaggeredColumn(
            autoForwardAfter: autoForwardAfter,
            totalDuration: const Duration(milliseconds: 200),
            children: const [Text('logo'), Text('form')],
          ),
        ),
      );

  double firstOpacity(WidgetTester tester) =>
      tester.widgetList<FadeTransition>(find.byType(FadeTransition)).first.opacity.value;

  testWidgets('forward çağrılmazsa içerik gizli kalır', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(seconds: 3));
    expect(firstOpacity(tester), 0.0);
  });

  testWidgets('emniyet süresi dolunca içerik kendiliğinden görünür', (tester) async {
    await tester.pumpWidget(host(autoForwardAfter: const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 400));
    expect(firstOpacity(tester), 1.0);
  });
}
