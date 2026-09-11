import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';

/// Guc butonu — ne gosterildigi para kararini etkiler. Envanterde hak varsa
/// oradan duser (rozet), yoksa dogrudan mor elmastan (fiyat). Hakki varken
/// fiyat gostermek "para gidecek" yanilgisi yaratir; fiyat bilinmiyorsa (0)
/// yanlis fiyat yerine hic gosterilmez.
void main() {
  testWidgets('envanterde hak varsa rozet gorunur, fiyat GIZLI', (tester) async {
    await tester.pumpWidget(_wrap(_button(count: 2, purpleCost: 15)));

    expect(find.text('2'), findsOneWidget);
    expect(find.text('15'), findsNothing);
  });

  testWidgets('hak yoksa mor fiyat gorunur, rozet yok', (tester) async {
    await tester.pumpWidget(_wrap(_button(count: 0, purpleCost: 15)));

    expect(find.text('15'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('fiyat bilinmiyorsa (0) fiyat gosterilmez', (tester) async {
    await tester.pumpWidget(_wrap(_button(count: 0, purpleCost: 0)));

    expect(find.text('0'), findsNothing);
  });

  testWidgets('kullanilmis guc tik gosterir, fiyat ve rozet yok', (tester) async {
    await tester.pumpWidget(_wrap(_button(count: 2, purpleCost: 15, isUsed: true)));

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('15'), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('dokunus iletilir', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(_button(count: 0, purpleCost: 15, onTap: () async => taps++)));

    await tester.tap(find.byType(PowerBarButton));
    await tester.pump();

    expect(taps, 1);
  });
}

PowerBarButton _button({
  required int count,
  required int purpleCost,
  bool isUsed = false,
  Future<void> Function()? onTap,
}) =>
    PowerBarButton(
      type: PowerType.skip,
      count: count,
      isUsed: isUsed,
      purpleCost: purpleCost,
      label: 'Gec',
      onTap: onTap,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    );
