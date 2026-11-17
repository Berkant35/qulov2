import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/discover/widgets/profile_card_question_info.dart';

/// Discover kartı: sesli / görselli soru rozeti (2.0.19). Sunucu bayrakları yalnız kapı
/// açıkken gönderir; yoksa false → rozet çizilmez.
final _en = AppLocalizations(const Locale('en'));

ProfileCardModel _card({bool hasVoice = false, bool hasImage = false}) => ProfileCardModel(
      userId: 'u1',
      questionCount: 3,
      distanceKm: 5,
      distanceTier: 0,
      questionInfo: QuestionInfoModel(
        count: 3,
        hasVoice: hasVoice,
        hasImage: hasImage,
      ),
    );

Future<void> _pump(WidgetTester tester, ProfileCardModel card) async {
  await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: ProfileCardQuestionInfo(card: card)),
      ),
    );
  // Çeviriler bir mikro görev sonra yüklenir.
  await tester.pump();
}

void main() {
  testWidgets('hasVoice → 🎤 rozeti', (tester) async {
    await _pump(tester, _card(hasVoice: true));

    expect(find.text('🎤 ${_en.get('badge_voice_question')}'), findsOneWidget);
    expect(find.textContaining('📷'), findsNothing);
  });

  testWidgets('hasImage → 📷 rozeti', (tester) async {
    await _pump(tester, _card(hasImage: true));

    expect(find.text('📷 ${_en.get('badge_image_question')}'), findsOneWidget);
    expect(find.textContaining('🎤'), findsNothing);
  });

  testWidgets('ikisi de varsa iki rozet', (tester) async {
    await _pump(tester, _card(hasVoice: true, hasImage: true));

    expect(find.textContaining('🎤'), findsOneWidget);
    expect(find.textContaining('📷'), findsOneWidget);
  });

  testWidgets('medyasız soruda rozet yok', (tester) async {
    await _pump(tester, _card());

    expect(find.textContaining('🎤'), findsNothing);
    expect(find.textContaining('📷'), findsNothing);
  });
}
