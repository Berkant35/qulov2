import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
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
  setUp(() => FormatManager.instance.configure(const Locale('en')));

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

  testWidgets('imperial bölgede mesafe mil', (tester) async {
    await FormatManager.instance.configure(const Locale('en', 'US'));
    addTearDown(() => FormatManager.instance.configure(const Locale('en')));

    await tester.pumpWidget(_wrap(const QuestionOwnerHeader(name: 'Ada', distanceKm: 3.2)));
    await tester.pump();

    expect(find.text('Ada • 2.0 mi'), findsOneWidget);
  });

  testWidgets('onReport verilirse şikâyet ikonu çıkar ve tıklanınca çağrılır', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(QuestionOwnerHeader(name: 'Ada', onReport: () => taps++)));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.flag_outlined));

    expect(taps, 1);
  });

  testWidgets('onReport yoksa (chat sorusu) şikâyet ikonu yok', (tester) async {
    await tester.pumpWidget(_wrap(const QuestionOwnerHeader(name: 'Ada')));
    await tester.pump();

    expect(find.byIcon(Icons.flag_outlined), findsNothing);
  });

  testWidgets('dar ekranda uzun isim + mesafe + onReport taşmaz, ikon tıklanır', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var taps = 0;
    await tester.pumpWidget(_wrap(QuestionOwnerHeader(
      name: 'Bir Cok Uzun Isimli Kullanici Adi Soyadi Ornek',
      distanceKm: 12.5,
      photoUrl: null,
      onReport: () => taps++,
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.flag_outlined));
    expect(taps, 1);
  });

  testWidgets('onReport yokken (chat) satır içeriği kadar daralır, ikon yok', (tester) async {
    await tester.pumpWidget(_wrap(const QuestionOwnerHeader(name: 'Ada', distanceKm: 3.2)));
    await tester.pump();

    final row = tester.getSize(find.byType(Row).first);
    final text = tester.getSize(find.text('Ada • 3.2 km'));
    expect(find.byIcon(Icons.flag_outlined), findsNothing);
    expect(tester.takeException(), isNull);
    expect(text.width, lessThan(row.width));
  });
}
