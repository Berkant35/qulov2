import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';
import 'package:qulo_v2/features/profile_detail/mixins/profile_details_grid_mixin.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_details_grid.dart';

class _Subject with ProfileDetailsGridWidgetMixin {}

/// Başkasının profilindeki detay chip'leri (`ProfileDetailsGrid`).
///
/// Liste kurma ve evet/hayır eşlemesi widget'tan (`List<Widget> _buildItems`)
/// mixin'e taşındı; sıra, boş alan atlama ve etiketler aynı kalmalı.
Future<BuildContext> _context(WidgetTester tester, {Widget? child}) async {
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(
      body: Builder(builder: (context) {
        captured = context;
        return child ?? const SizedBox.shrink();
      }),
    ),
  ));
  await tester.pump(); // AppLocalizationsDelegate.load asenkron
  return captured;
}

void main() {
  setUp(() => FormatManager.instance.configure(const Locale('en')));

  final subject = _Subject();

  testWidgets('dolu alanlar sabit sırayla, boş/null alanlar atlanır', (tester) async {
    final context = await _context(tester);
    final chips = subject.detailChips(
      context,
      const UserDetailsModel(
        height: 175,
        zodiac: 'leo',
        job: '',
        school: 'ODTÜ',
        smoking: 'YES',
        alcohol: 'sometimes',
        pets: 'Kedi',
        personality: 'Sakin',
      ),
    );

    expect(chips.map((c) => (c.iconAsset, c.label)).toList(), [
      (QIcons.icHeight, '175 cm'),
      (QIcons.icZodiac, 'leo'),
      (QIcons.icSchool, 'ODTÜ'),
      (QIcons.icSmoke, 'Yes'),
      (QIcons.icUseAlcohol, 'Sometimes'),
      (QIcons.icPets, 'Kedi'),
      (QIcons.icPersonality, 'Sakin'),
    ]);
  });

  testWidgets('hiçbir alan dolu değilse liste boş', (tester) async {
    final context = await _context(tester);

    expect(subject.detailChips(context, const UserDetailsModel()), isEmpty);
    expect(subject.detailChips(context, const UserDetailsModel(job: '', smoking: '')), isEmpty);
  });

  testWidgets('frekans: NO çevrilir, bilinmeyen değer olduğu gibi kalır', (tester) async {
    final context = await _context(tester);

    expect(subject.frequencyLabel(context, 'NO'), 'No');
    expect(subject.frequencyLabel(context, 'socially'), 'socially');
    expect(subject.frequencyLabel(context, null), isNull);
    expect(subject.frequencyLabel(context, ''), isNull);
  });

  testWidgets('grid boşken başlık dahil hiçbir şey çizilmez', (tester) async {
    await _context(tester, child: const ProfileDetailsGrid(details: UserDetailsModel()));

    expect(find.text('Details'), findsNothing);
  });

  testWidgets('grid dolu alanları chip olarak çizer', (tester) async {
    await _context(
      tester,
      child: const ProfileDetailsGrid(details: UserDetailsModel(job: 'Mimar', smoking: 'NO')),
    );

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Mimar'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
  });
}
