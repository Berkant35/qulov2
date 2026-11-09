import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

/// Yeniden açılışta sayaç sunucunun kalan süresinden başlar; çubuk sorunun
/// tam süresine göre dolu görünür (12/30 → %40), "taze 12 sn" gibi değil.
///
/// Süre etiketi `FormatManager.seconds` ile yerelleşir (`12s`, ja `12秒`);
/// eskiden her dilde sabit `'12 s'` yazıyordu.
void main() {
  testWidgets('kalan süreden başlar, ilerleme tam süreye oranlanır', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: QuizTimer(seconds: 12, totalSeconds: 30, questionId: 'q1', onTimeout: () {}),
      ),
    ));

    expect(find.text('12s'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(0.4, 0.001));
  });

  testWidgets('totalSeconds yoksa eski davranış: tam dolu başlar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: QuizTimer(seconds: 30, questionId: 'q1', onTimeout: () {})),
    ));

    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, 1.0);
  });
}
