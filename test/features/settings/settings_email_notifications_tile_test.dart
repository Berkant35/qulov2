import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/settings/widgets/settings_email_notifications_tile.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../helpers/fake_repositories.dart';

/// Eskiden anahtar kayit sonucunu yok sayiyordu: ag yokken dokunus hicbir sey
/// yapmiyor gibi gorunuyordu (anahtar yerinde, mesaj yok).
Future<FakeUserRepository> _pump(WidgetTester tester, {AppFailure? failure}) async {
  final repo = FakeUserRepository(const UserModel(id: 'u1', email: 'u1@qulo.test'),
      prefsFailure: failure);
  await tester.pumpWidget(ProviderScope(
    overrides: [userRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: const Scaffold(body: SettingsEmailNotificationsTile()),
    ),
  ));
  await tester.pump();
  return repo;
}

void main() {
  testWidgets('kayit basarisizsa kullanici yerel dilde sebebini gorur', (tester) async {
    final repo = await _pump(tester, failure: const NetworkFailure());

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();

    expect(repo.prefsCallCount, 1);
    expect(find.text('No internet connection. Please try again.'), findsOneWidget);
  });

  testWidgets('kayit basariliysa hata mesaji yok', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();

    expect(repo.lastPrefsBody, {'email_matches': false});
    expect(find.byType(SnackBar), findsNothing);
  });
}
