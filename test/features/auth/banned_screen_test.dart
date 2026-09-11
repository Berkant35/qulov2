import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/auth/screens/banned_screen.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

/// Banlanan kullanicinin tek itiraz yolu destek adresi. Adres bilincli olarak
/// LITERAL sinanir: sunucu (`config/env.ts`) ve web (210 yerde) ayni kanonik
/// adresi kullaniyor; sabite referans vermek testi tautolojiye cevirirdi.
void main() {
  testWidgets('destek adresi gorunur', (tester) async {
    await tester.pumpWidget(_wrap(_RecordingAuth()));
    await tester.pump();

    expect(find.text('info@socrepho.com'), findsOneWidget);
  });

  testWidgets('cikis butonu oturumu kapatir', (tester) async {
    final auth = _RecordingAuth();
    await tester.pumpWidget(_wrap(auth));
    await tester.pump();

    await tester.tap(find.byType(FilledButton));

    expect(auth.logouts, 1);
  });
}

Widget _wrap(_RecordingAuth auth) => ProviderScope(
      overrides: [authProvider.overrideWith(() => auth)],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const BannedScreen(),
      ),
    );

class _RecordingAuth extends AuthNotifier {
  int logouts = 0;

  @override
  AuthState build() => const AuthState(status: AuthStatus.banned);

  @override
  Future<void> logout() async => logouts++;
}
