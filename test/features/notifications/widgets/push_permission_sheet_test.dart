import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/notifications/widgets/push_permission_sheet.dart';

/// Açıklama ekranının iki butonu sonucu doğru döndürmeli: yalnız "evet"
/// sistem istemini açar.
void main() {
  final en = AppLocalizations(const Locale('en'));

  Future<bool?> openAndTap(WidgetTester tester, String label) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showModalBottomSheet<bool>(
              context: context,
              builder: (_) => const PushPermissionSheet(),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(en.get('push_prompt_title')), findsOneWidget);
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('"Evet" true döner', (tester) async {
    expect(await openAndTap(tester, en.get('push_prompt_accept')), isTrue);
  });

  testWidgets('"Şimdi değil" false döner', (tester) async {
    expect(await openAndTap(tester, en.get('push_prompt_later')), isFalse);
  });
}
