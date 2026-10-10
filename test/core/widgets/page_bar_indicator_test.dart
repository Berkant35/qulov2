import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/page_bar_indicator.dart';

void main() {
  testWidgets('tek sayfada çizilmez, çok sayfada sayfa başına bir çubuk', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: PageBarIndicator(count: 1, current: 0),
    ));
    expect(find.byType(Expanded), findsNothing);
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: PageBarIndicator(count: 3, current: 1),
    ));
    expect(find.byType(Expanded), findsNWidgets(3));
  });
}
