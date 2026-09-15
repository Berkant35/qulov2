import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/profile/widgets/pref_chip.dart';

/// Profil > Tercihler'deki dil çipi 18 kodu tek etikette birleştirir
/// ("TR, EN, DE, …, TH, ID"). Çip, Wrap'ın verdiği satır genişliğine sığmalı:
/// 2026-09-15'te 375px ekranda 102px sağa taşıyordu (RenderFlex overflow).
Widget _host(Widget child, {double width = 375}) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: Wrap(children: [child]),
      ),
    ),
  ),
);

void main() {
  const longLabel =
      'TR, EN, DE, FR, ES, AR, RU, PT, IT, JA, KO, ZH, NL, PL, SV, HI, TH, ID';

  testWidgets('uzun etiket çipi taşırmaz, tamamı görünür kalır', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const PrefChip(iconPath: QIcons.globe, label: longLabel)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull, reason: 'RenderFlex taşmamalı');
    final chip = tester.getSize(find.byType(PrefChip));
    expect(chip.width, lessThanOrEqualTo(375));
    // Kırpma yok: metin satır atlayarak tamamını gösterir.
    final text = tester.widget<Text>(find.text(longLabel));
    expect(text.overflow ?? TextOverflow.clip, isNot(TextOverflow.ellipsis));
    expect(text.softWrap ?? true, isTrue);
  });

  testWidgets('kısa etiket çipi içerik kadar kalır (Wrap içinde şişmez)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const PrefChip(iconPath: QIcons.globe, label: 'TR, EN')),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PrefChip)).width, lessThan(200));
  });
}
