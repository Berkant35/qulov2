import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/constants/identity_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';
import 'package:qulo_v2/features/identity/widgets/identity_chips.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_basic_info.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

PublicProfileModel _profile({
  String? city,
  double? distanceKm,
  VisibleIdentityModel? identity,
}) =>
    PublicProfileModel(
      userId: 'u2',
      name: 'Ada',
      age: 27,
      city: city,
      distanceKm: distanceKm,
      identity: identity,
    );

/// Mesafe "çok önemli bilgi": şehir alanı boş olsa da görünmeli; bilinmiyorsa
/// (null) "yakında" gibi yanıltıcı bir şey yazılmamalı.
void main() {
  setUp(() => FormatManager.instance.configure(const Locale('en')));

  testWidgets('şehir yokken mesafe yine görünür', (tester) async {
    await tester.pumpWidget(_wrap(
      ProfileBasicInfo(profile: _profile(city: null, distanceKm: 3.2)),
    ));
    await tester.pump();

    expect(find.text('3.2 km'), findsOneWidget);
  });

  testWidgets('şehir ve mesafe birlikte', (tester) async {
    await tester.pumpWidget(_wrap(
      ProfileBasicInfo(profile: _profile(city: 'İstanbul', distanceKm: 3.2)),
    ));
    await tester.pump();

    expect(find.text('İstanbul • 3.2 km'), findsOneWidget);
  });

  testWidgets('showDistance kapalıysa mesafe olsa da sadece şehir', (tester) async {
    await tester.pumpWidget(_wrap(
      ProfileBasicInfo(
        profile: _profile(city: 'İstanbul', distanceKm: 3.2),
        showDistance: false,
      ),
    ));
    await tester.pump();

    expect(find.text('İstanbul'), findsOneWidget);
    expect(find.textContaining('km'), findsNothing);
  });

  testWidgets('mesafe bilinmiyorsa sadece şehir, "yakında" yazmaz', (tester) async {
    await tester.pumpWidget(_wrap(
      ProfileBasicInfo(profile: _profile(city: 'İstanbul', distanceKm: null)),
    ));
    await tester.pump();

    expect(find.text('İstanbul'), findsOneWidget);
    expect(find.textContaining('km'), findsNothing);
    expect(
      find.text(AppLocalizations(const Locale('en')).get('nearby')),
      findsNothing,
    );
  });

  testWidgets('imperial bölgede km yerine mil', (tester) async {
    await FormatManager.instance.configure(const Locale('en', 'US'));
    addTearDown(() => FormatManager.instance.configure(const Locale('en')));

    await tester.pumpWidget(_wrap(ProfileBasicInfo(profile: _profile(city: 'Boston', distanceKm: 3.2))));
    await tester.pump();

    expect(find.text('Boston • 2.0 mi'), findsOneWidget);
  });

  testWidgets('görünür etiketler çip olarak çizilir', (tester) async {
    await tester.pumpWidget(_wrap(
      ProfileBasicInfo(
        profile: _profile(
          identity: const VisibleIdentityModel(
            genderLabels: ['non_binary'],
            orientationLabels: ['gay'],
          ),
        ),
      ),
    ));
    await tester.pump();
    final ctx = tester.element(find.byType(ProfileBasicInfo));

    expect(find.text(ctx.tr(IdentityLabels.orientationKey('gay'))), findsOneWidget);
    expect(find.text(ctx.tr(IdentityLabels.genderKey('non_binary'))), findsOneWidget);
  });

  testWidgets('etiket yoksa (null ya da boş) çip alanı çizilmez', (tester) async {
    for (final identity in [null, const VisibleIdentityModel()]) {
      await tester.pumpWidget(_wrap(
        ProfileBasicInfo(profile: _profile(identity: identity)),
      ));
      await tester.pump();
      expect(find.byType(IdentityChips), findsNothing);
    }
  });
}
