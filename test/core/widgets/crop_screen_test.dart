import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/crop_screen.dart';

/// Kirpma ekraninin kendi bayt kapisi (secici kapisina ek savunma).
/// Crashlytics iOS 2.0.17: bos bayt editore verildi, ayristirici coktu, editor
/// "yukleniyor"da kaldi; "Tamam" `_parsedImageDetail!` ile fatal.
void main() {
  Future<({Future<Uint8List?> result, BuildContext context})> open(
    WidgetTester tester,
    Uint8List bytes,
  ) async {
    late BuildContext hostContext;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: Builder(builder: (context) {
        hostContext = context;
        return const SizedBox();
      })),
    ));
    await tester.pump(); // yerellestirme delegesi yuklenir
    final result = Navigator.of(hostContext).push<Uint8List>(
      MaterialPageRoute(builder: (_) => CropScreen(imageBytes: bytes)),
    );
    await tester.pump();
    return (result: result, context: hostContext);
  }

  testWidgets('0 bayt: editor kurulmaz, ekran null ile kapanir, "baska fotograf sec"', (tester) async {
    final opened = await open(tester, Uint8List(0));
    await tester.pumpAndSettle();

    expect(await opened.result, isNull);
    expect(find.byType(CropScreen), findsNothing);
    expect(find.text(opened.context.tr('photo_invalid_pick_again')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gecerli gorsel: editor hazir olmadan "Tamam" kapali (null check fatal\'i)', (tester) async {
    final png = Uint8List.fromList(img.encodePng(img.Image(width: 30, height: 40)));
    final opened = await open(tester, png);
    await tester.pump();

    final ok = tester.widget<TextButton>(
      find.widgetWithText(TextButton, opened.context.tr('ok')),
    );
    expect(ok.onPressed, isNull);
    expect(find.byType(CropScreen), findsOneWidget);
  });
}
