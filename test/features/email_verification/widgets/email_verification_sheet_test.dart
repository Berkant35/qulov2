import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/auth_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/email_verification/widgets/email_verification_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../fakes.dart';

/// "Mesaj atmak için e-postanı doğrula" sayfası: adres görünür, "Doğruladım"
/// yalnız sunucu doğrulanmış derse kapatır, tekrar gönder sonucu yazılır.
void main() {
  final en = AppLocalizations(const Locale('en'));

  Future<({bool? Function() result, ScriptedUserNotifier user})> open(
    WidgetTester tester, {
    UserModel? afterFetch,
    Result<ResendVerificationResponse> resend = const Success(ResendVerificationResponse(sent: true)),
  }) async {
    bool? result;
    final user = ScriptedUserNotifier(unverified, afterFetch: afterFetch);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        userProvider.overrideWith(() => user),
        authRepositoryProvider.overrideWithValue(FakeResendAuthRepository(resend)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const EmailVerificationSheet(trigger: 'message'),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (result: () => result, user: user);
  }

  testWidgets('kullanıcının e-posta adresi gösterilir', (tester) async {
    await open(tester);

    expect(find.text(en.get('email_verify_title')), findsOneWidget);
    expect(find.text('ada@qulo.test'), findsOneWidget);
  });

  testWidgets('"Doğruladım" + sunucu doğrulanmış → true ile kapanır', (tester) async {
    final h = await open(tester, afterFetch: verified);

    await tester.tap(find.text(en.get('email_verify_done')));
    await tester.pumpAndSettle();

    expect(h.result(), isTrue);
    expect(h.user.fetchCalls, 1);
    expect(find.text(en.get('email_verify_success')), findsOneWidget);
  });

  testWidgets('"Doğruladım" + hâlâ doğrulanmamış → açık kalır, uyarı', (tester) async {
    final h = await open(tester, afterFetch: unverified);

    await tester.tap(find.text(en.get('email_verify_done')));
    await tester.pumpAndSettle();

    expect(h.result(), isNull);
    expect(find.text(en.get('email_verify_not_yet')), findsOneWidget);
  });

  testWidgets('tekrar gönder: gönderildi / hız sınırı metni', (tester) async {
    await open(tester);
    await tester.tap(find.text(en.get('email_verify_resend')));
    await tester.pumpAndSettle();
    expect(find.text(en.get('email_verify_sent')), findsOneWidget);
  });

  testWidgets('tekrar gönder 429 → "biraz sonra dene"', (tester) async {
    await open(tester,
        resend: const Failure(ServerFailure(code: 'RATE_LIMITED', statusCode: 429)));
    await tester.tap(find.text(en.get('email_verify_resend')));
    await tester.pumpAndSettle();
    expect(find.text(en.get('email_verify_rate_limited')), findsOneWidget);
  });

  testWidgets('"Şimdi değil" → false', (tester) async {
    final h = await open(tester);

    await tester.tap(find.text(en.get('email_verify_later')));
    await tester.pumpAndSettle();

    expect(h.result(), isFalse);
  });
}
