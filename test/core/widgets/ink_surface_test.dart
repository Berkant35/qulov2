import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/widgets/ink_surface.dart';

/// Renkli `Container(decoration:)` içindeki ListTile'ın dokunma dalgası
/// görünmüyordu (Flutter 3.47 bunu assertion ile yakalar). InkSurface rengi
/// mürekkebin çizildiği Material'a taşır.
void main() {
  const surfaceColor = Color(0xFF123456);

  testWidgets('ListTile mürekkebi InkSurface rengini taşıyan Material üzerine çizilir',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InkSurface(
          color: surfaceColor,
          child: ListTile(title: const Text('satır'), onTap: () {}),
        ),
      ),
    ));
    await tester.tap(find.text('satır'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final inkMaterial = tester.widget<Material>(
      find.ancestor(of: find.byType(ListTile), matching: find.byType(Material)).first,
    );
    expect(inkMaterial.color, surfaceColor);
    expect(inkMaterial.clipBehavior, Clip.antiAlias);
  });
}
