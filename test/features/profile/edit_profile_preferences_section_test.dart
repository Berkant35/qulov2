import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_preferences_section.dart';

/// EditProfileNotifier.build() kullanicisiz (test ortaminda) varsayilan state
/// doner — override gerekmiyor, widget direkt provider'in gercek durumuyla calisir.
Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('tumu secili degilken "Select all" gosterilir, dokununca tumu secilir', (tester) async {
    await tester.pumpWidget(_wrap(
      const EditProfilePreferencesSection(completionText: '0/4'),
    ));
    await tester.pump();

    expect(find.text('Select all'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);

    await tester.tap(find.text('Select all'));
    await tester.pump();

    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Select all'), findsNothing);
  });
}
