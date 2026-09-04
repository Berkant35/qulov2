import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/question_owner_header.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

/// Soru çözerken karşı kişinin kimliği: chat ve quiz ekranları aynı satırı kullanır.
void main() {
  testWidgets('isim ve mesafe tek satırda, fotoğraf yoksa kişi ikonu', (tester) async {
    await tester.pumpWidget(_wrap(
      const QuestionOwnerHeader(name: 'Ada', distanceKm: 3.2),
    ));
    await tester.pump();

    expect(find.text('Ada • 3.2 km'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('1 km altında "yakında" çevirisi', (tester) async {
    await tester.pumpWidget(_wrap(
      const QuestionOwnerHeader(name: 'Ada', distanceKm: 0.4),
    ));
    await tester.pump();

    final nearby = AppLocalizations(const Locale('en')).get('nearby');
    expect(find.text('Ada • $nearby'), findsOneWidget);
  });

  testWidgets('mesafe yoksa sadece isim', (tester) async {
    await tester.pumpWidget(_wrap(const QuestionOwnerHeader(name: 'Ada')));
    await tester.pump();

    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('isim yoksa hiç çizilmez', (tester) async {
    await tester.pumpWidget(_wrap(const QuestionOwnerHeader(name: null)));
    await tester.pump();

    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byType(Text), findsNothing);
  });
}
