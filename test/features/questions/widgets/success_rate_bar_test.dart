import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/questions/mixins/success_rate_color_mixin.dart';
import 'package:qulo_v2/features/questions/widgets/success_rate_bar.dart';

class _Subject with SuccessRateColorMixin {}

Future<BuildContext> _pump(WidgetTester tester, Locale formatLocale, {int rate = 45}) async {
  await FormatManager.instance.configure(formatLocale);
  addTearDown(() => FormatManager.instance.configure(const Locale('en')));
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(
      body: Builder(builder: (context) {
        captured = context;
        return SuccessRateBar(successRate: rate);
      }),
    ),
  ));
  await tester.pump(); // AppLocalizationsDelegate.load asenkron
  return captured;
}

/// Soru analitiğindeki başarı oranı çubuğu.
///
/// Oran eskiden her dilde Türkçe biçimle (`'%45'`) yazılıyordu; artık
/// `FormatManager.percent` ile yerelleşir. Eşik → renk eşlemesi
/// `SuccessRateColorMixin`'de (AnalyticsTotalsSection ile ortak).
void main() {
  testWidgets('İngilizcede "45%", Türkçede "%45"', (tester) async {
    await _pump(tester, const Locale('en'));
    expect(find.text('45%'), findsOneWidget);

    await _pump(tester, const Locale('tr'));
    expect(find.text('%45'), findsOneWidget);
  });

  testWidgets('eşikler: ≥70 başarı, 40–69 uyarı, <40 hata', (tester) async {
    final context = await _pump(tester, const Locale('en'));
    final colors = context.appColors;
    final subject = _Subject();

    expect(subject.successRateColor(context, 100), colors.success);
    expect(subject.successRateColor(context, 70), colors.success);
    expect(subject.successRateColor(context, 69), colors.warning);
    expect(subject.successRateColor(context, 40), colors.warning);
    expect(subject.successRateColor(context, 39), colors.error);
    expect(subject.successRateColor(context, 0), colors.error);
  });
}
