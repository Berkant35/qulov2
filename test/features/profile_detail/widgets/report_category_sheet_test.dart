import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/profile_detail/widgets/report_category_sheet.dart';

/// `INAPPROPRIATE_MEDIA` yalnız şikâyet edilen soruda medya varsa listelenir (2.0.19).
/// Sheet gerçekteki gibi `showModalBottomSheet` ile açılır (varsayılan 9/16 yükseklik sınırı):
/// küçük ekranda 11 satırın sonuncusu ("Diğer") kaydırılarak erişilebilir olmalı.
final _en = AppLocalizations(const Locale('en'));

Future<List<String>> _openSheet(
  WidgetTester tester, {
  bool? includeMedia,
}) async {
  final selected = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => includeMedia == null
                    ? ReportCategorySheet(onSelected: selected.add)
                    : ReportCategorySheet(
                        includeMediaCategory: includeMedia,
                        onSelected: selected.add,
                      ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // çeviriler yüklensin
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return selected;
}

void main() {
  testWidgets('medyalı soruda INAPPROPRIATE_MEDIA seçeneği var ve değeri döner', (tester) async {
    final selected = await _openSheet(tester, includeMedia: true);

    await tester.tap(find.text(_en.get('report_cat_inappropriate_media')));
    await tester.pumpAndSettle();

    expect(selected, ['INAPPROPRIATE_MEDIA']);
  });

  testWidgets('medyasız soruda INAPPROPRIATE_MEDIA seçeneği yok', (tester) async {
    await _openSheet(tester, includeMedia: false);

    expect(find.text(_en.get('report_cat_inappropriate_media')), findsNothing);
    expect(find.text(_en.get('report_cat_spam')), findsOneWidget);
  });

  testWidgets('varsayılan (profil şikâyeti) medya seçeneğini göstermez', (tester) async {
    await _openSheet(tester);

    expect(find.text(_en.get('report_cat_inappropriate_media')), findsNothing);
    expect(find.text(_en.get('report_cat_spam')), findsOneWidget);
  });

  testWidgets('küçük ekranda (320x568) 11 satırlı listede "Diğer" kaydırınca görünür ve seçilir', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selected = await _openSheet(tester, includeMedia: true);
    expect(tester.takeException(), isNull, reason: 'taşma (overflow) yok');

    final other = find.text(_en.get('report_cat_other'));
    // Liste kaydırılabilir olmalı: kaydırmadan önce "Diğer" sheet'in dışında kalıyor.
    final list = find.descendant(
      of: find.byType(ReportCategorySheet),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(other, 48, scrollable: list);
    await tester.ensureVisible(other);
    await tester.pumpAndSettle();
    await tester.tap(other);
    await tester.pumpAndSettle();

    expect(selected, ['OTHER']);
  });
}
