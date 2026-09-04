import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/chat/widgets/chat_day_separator.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

/// Gün ayracı eskiden ham Türkçe `Bugun`/`Dun` ve `d.MM.yyyy` yazıyordu.
void main() {
  setUp(() => FormatManager.instance.configure(const Locale('en')));

  testWidgets('bugün ve dün çevrilir, eski gün ay adıyla', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(_wrap(Column(children: [
      ChatDaySeparator(day: today),
      ChatDaySeparator(day: today.subtract(const Duration(days: 1))),
      ChatDaySeparator(day: DateTime(2026, 1, 15)),
    ])));
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Jan 15, 2026'), findsOneWidget);
    expect(find.text('Bugun'), findsNothing);
  });
}
