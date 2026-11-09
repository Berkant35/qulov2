import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/questions/widgets/question_step_settings.dart';

/// Süre seçenekleri 4 etiketi aşınca (economy config) fazladan kart sürenin
/// kendisini gösterir. Eskiden sabit `'150 sn'` yazıyordu — Türkçe kısaltma
/// her dilde görünüyordu; artık `FormatManager.seconds` ile yerelleşir.
Future<void> _pump(WidgetTester tester, Locale formatLocale) async {
  await FormatManager.instance.configure(formatLocale);
  addTearDown(() => FormatManager.instance.configure(const Locale('en')));
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(
      body: QuestionStepSettings(
        selectedTimeLimit: 15,
        timePresets: const [15, 30, 60, 90, 150],
        onTimeLimitChanged: (_) {},
      ),
    ),
  ));
  await tester.pump(); // AppLocalizationsDelegate.load asenkron
}

void main() {
  testWidgets('etiketi olmayan beşinci süre yerel biçimle yazılır', (tester) async {
    await _pump(tester, const Locale('ja'));

    // Kartın başlığı (TimePresetCard) + etiket yedeği aynı yerel biçim.
    expect(find.text('150秒'), findsNWidgets(2));
    expect(find.text('150 sn'), findsNothing);
  });

  testWidgets('İngilizcede "150s", Türkçe "sn" değil', (tester) async {
    await _pump(tester, const Locale('en'));

    expect(find.text('150s'), findsNWidgets(2));
    expect(find.text('150 sn'), findsNothing);
  });
}
