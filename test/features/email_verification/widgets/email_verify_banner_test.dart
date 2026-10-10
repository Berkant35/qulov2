import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/email_verification/widgets/email_verify_banner.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../../helpers/fixed_user_notifier.dart';
import '../fakes.dart';

/// Eşleşmeler ekranındaki hatırlatma yalnız doğrulanmamış kullanıcıda görünür.
void main() {
  final en = AppLocalizations(const Locale('en'));

  Future<void> pump(WidgetTester tester, UserModel user) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [userProvider.overrideWith(() => FixedUserNotifier(user))],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const Scaffold(body: EmailVerifyBanner()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('doğrulanmamış → bant görünür', (tester) async {
    await pump(tester, unverified);
    expect(find.text(en.get('email_verify_banner_body')), findsOneWidget);
  });

  testWidgets('doğrulanmış → bant yok', (tester) async {
    await pump(tester, verified);
    expect(find.text(en.get('email_verify_banner_body')), findsNothing);
  });
}
