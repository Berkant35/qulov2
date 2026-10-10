import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/identity/identity_dialogs.dart';

import '../../helpers/fake_navigation.dart';

Future<({bool result, FakeNavigationService nav})> _confirm(
  WidgetTester tester, {
  required bool answer,
}) async {
  final nav = FakeNavigationService(confirmAnswer: answer);
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();
  final result = await IdentityDialogs.confirmClear(ctx, nav);
  return (result: result, nav: nav);
}

void main() {
  testWidgets('onaylanırsa true, diyalog identity_clear adıyla açılır', (tester) async {
    final r = await _confirm(tester, answer: true);
    expect(r.result, isTrue);
    expect(r.nav.dialogs, ['identity_clear']);
  });

  testWidgets('vazgeçilirse false', (tester) async {
    final r = await _confirm(tester, answer: false);
    expect(r.result, isFalse);
  });
}
