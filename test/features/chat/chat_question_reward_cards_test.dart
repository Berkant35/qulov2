import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_reward_cards.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../helpers/fixed_user_notifier.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool rainbowEnabled,
  required List<PowerUsageRecord> usages,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      userProvider.overrideWith(() => FixedUserNotifier(
            UserModel(id: 'u1', email: 'u1@qulo.test', rainbowEnabled: rainbowEnabled),
          )),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: ChatQuestionRewardCards(powerUsages: usages))),
    ),
  ));
  // Tek `pump()` yetmiyor: `AppLocalizationsDelegate.load()` + `userProvider`
  // (AsyncNotifier) ikisi de ayrı microtask turlarında çözülüyor — ilk pump
  // rainbowEnabled'ı hâlâ varsayılan `false` ile görüyor (kanıt: task-7
  // teşhisi). Gerçek ekranda userProvider zaten yüklenmiş halde mount olur;
  // bu sadece izole widget testinin başlangıç durumu.
  await tester.pumpAndSettle();
}

const _paid = [
  PowerUsageRecord(powerName: 'HALF', purpleSpent: 10, greenEarned: 2, rainbowEarned: 5),
];

void main() {
  testWidgets('rainbow kapalıyken Rainbow kartı yok; yeşil ve mor kartlar var', (tester) async {
    await _pump(tester, rainbowEnabled: false, usages: _paid);

    expect(find.byKey(ChatQuestionRewardCards.rainbowCardKey), findsNothing);
    expect(find.byKey(ChatQuestionRewardCards.greenCardKey), findsOneWidget);
    expect(find.byKey(ChatQuestionRewardCards.purpleCardKey), findsOneWidget);
  });

  testWidgets('rainbow açıkken Rainbow kartı toplamla', (tester) async {
    await _pump(tester, rainbowEnabled: true, usages: _paid);

    expect(find.byKey(ChatQuestionRewardCards.rainbowCardKey), findsOneWidget);
    expect(find.text('+5 Rainbow Diamonds'), findsOneWidget);
  });

  testWidgets('Rainbow kartı kendi alt metnini gösterir, yeşilin metnini değil', (tester) async {
    await _pump(tester, rainbowEnabled: true, usages: _paid);

    Finder inRainbow(Finder matching) => find.descendant(of: find.byKey(ChatQuestionRewardCards.rainbowCardKey), matching: matching);
    expect(inRainbow(find.text('Earned for the question owner from purchased diamonds')), findsOneWidget);
    expect(inRainbow(find.text('Earned for the question owner')), findsNothing);
  });

  testWidgets('tek satırlı kart açılmaz: ok yok, dokununca döküm çıkmaz', (tester) async {
    await _pump(tester, rainbowEnabled: false, usages: const [
      PowerUsageRecord(powerName: 'HALF', purpleSpent: 10, greenEarned: 2),
    ]);

    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    await tester.tap(find.text('+2 Green Diamonds'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(ChatQuestionRewardCards.greenCardKey), matching: find.text('+2')), findsNothing);
  });

  testWidgets('Rainbow payı 0 ise açıkken de kart yok', (tester) async {
    await _pump(tester, rainbowEnabled: true, usages: const [
      PowerUsageRecord(powerName: 'HALF', purpleSpent: 10, greenEarned: 2),
    ]);

    expect(find.byKey(ChatQuestionRewardCards.rainbowCardKey), findsNothing);
  });

  testWidgets('kayıt yoksa hiçbir kart yok', (tester) async {
    await _pump(tester, rainbowEnabled: true, usages: const []);

    expect(find.byKey(ChatQuestionRewardCards.greenCardKey), findsNothing);
    expect(find.byKey(ChatQuestionRewardCards.rainbowCardKey), findsNothing);
    expect(find.byKey(ChatQuestionRewardCards.purpleCardKey), findsNothing);
  });

  group('güç adları çevrilir, ham kod (HALF) gösterilmez', () {
    Finder inCard(Key card, Finder matching) => find.descendant(of: find.byKey(card), matching: matching);

    testWidgets('yeşil kart açılınca satırlar çevrili: güç etiketi + doğru cevap', (tester) async {
      await _pump(tester, rainbowEnabled: false, usages: const [
        PowerUsageRecord(powerName: 'HALF', purpleSpent: 10, greenEarned: 2),
        PowerUsageRecord(powerName: 'ANSWER', purpleSpent: 0, greenEarned: 5),
      ]);

      await tester.tap(find.text('+7 Green Diamonds'));
      await tester.pumpAndSettle();

      expect(inCard(ChatQuestionRewardCards.greenCardKey, find.text('50/50')), findsOneWidget);
      expect(inCard(ChatQuestionRewardCards.greenCardKey, find.text('Correct answer')), findsOneWidget);
      expect(inCard(ChatQuestionRewardCards.greenCardKey, find.textContaining('HALF')), findsNothing);
      expect(inCard(ChatQuestionRewardCards.greenCardKey, find.textContaining('ANSWER')), findsNothing);
    });

    testWidgets('mor kart tek güçte alt başlıkta çevrili etiket', (tester) async {
      await _pump(tester, rainbowEnabled: false, usages: const [
        PowerUsageRecord(powerName: 'HALF', purpleSpent: 10, greenEarned: 0),
      ]);

      expect(inCard(ChatQuestionRewardCards.purpleCardKey, find.text('Spent for 50/50')), findsOneWidget);
      expect(inCard(ChatQuestionRewardCards.purpleCardKey, find.textContaining('HALF')), findsNothing);
    });

    testWidgets('mor kart birden çok güçte açılınca satırlar çevrili', (tester) async {
      await _pump(tester, rainbowEnabled: false, usages: const [
        PowerUsageRecord(powerName: 'HALF', purpleSpent: 10, greenEarned: 0),
        PowerUsageRecord(powerName: 'SKIP', purpleSpent: 20, greenEarned: 0),
      ]);

      await tester.tap(find.text('-30 Purple Diamonds'));
      await tester.pumpAndSettle();

      expect(inCard(ChatQuestionRewardCards.purpleCardKey, find.text('50/50')), findsOneWidget);
      expect(inCard(ChatQuestionRewardCards.purpleCardKey, find.text('Mark Correct')), findsOneWidget);
      expect(inCard(ChatQuestionRewardCards.purpleCardKey, find.textContaining('HALF')), findsNothing);
      expect(inCard(ChatQuestionRewardCards.purpleCardKey, find.textContaining('SKIP')), findsNothing);
    });
  });
}
