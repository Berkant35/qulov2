import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/power_effects/half_strike_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/hint_reveal_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/oracle_highlight.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_answer_option.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_all_counter_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_slide_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/time_extend_effect.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_power_bar.dart';
import 'package:qulo_v2/features/chat/widgets/solve_question_body.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/power_banner.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_bubble.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_button.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

/// Sohbete sızmama (spec §13.2, §13.6/17): sohbet sorusu quiz'in yaprak bileşenlerini
/// (`AnswerButton`, `PowerBanner`, `QuizTimer`) paylaşır. Güç efektleri ve "?" yalnız
/// quiz'e özel sarmalayıcılarda; sohbet ekranı bugünkü gibi kalır.
final _en = AppLocalizations(const Locale('en'));

const _question = ChatQuestionModel(
  id: 'q1',
  matchId: 'm1',
  senderId: 'other',
  questionText: 'Favourite city?',
  optionA: 'Izmir',
  optionB: 'Ankara',
  optionC: 'Bursa',
  optionD: 'Mersin',
  optionCount: 4,
  hintText: 'sea',
  createdAt: '2026-10-12T10:00:00Z',
);

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

const _quizOnlyTypes = <Type>[
  PowerHelpButton,
  PowerHelpBubble,
  PowerEffectAnswerOption,
  OracleHighlight,
  HalfStrikeEffect,
  HintRevealEffect,
  SkipSlideEffect,
  TimeExtendEffect,
  SkipAllCounterEffect,
];

void main() {
  testWidgets('SolveQuestionBody ve ChatQuestionPowerBar PowerHelpButton / power_effects render etmez',
      (tester) async {
    // Sohbet sorusu ekranı kaydırmasız: tüm şıklar + iki banner sığsın.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final taps = <String>[];
    await tester.pumpWidget(_host(SolveQuestionBody(
      question: _question,
      timerKey: GlobalKey<QuizTimerState>(),
      selectedOption: null,
      isSubmitting: false,
      removedOptions: const {'B', 'C'},
      suggestedOption: 'A',
      hintVisible: true,
      hintText: 'sea',
      powerBlockActive: false,
      onTimeout: () {},
      onOptionSelected: (_) {},
      onSubmit: () async {},
      onPowerTap: (power) async => taps.add(power),
    )));
    await tester.pump();

    expect(find.byType(ChatQuestionPowerBar), findsOneWidget);
    for (final type in _quizOnlyTypes) {
      expect(find.byType(type), findsNothing, reason: '$type sohbete sızmamalı');
    }

    // Sohbet davranışı aynı: Kâhin + ipucu banner'ı, Kâhin şıkkı eski nabızla, elenenler gri.
    expect(find.byType(PowerBanner), findsNWidgets(2));
    expect(find.text(_en.get('power_oracle_desc')), findsOneWidget);
    AnswerButton answer(String text) =>
        tester.widget<AnswerButton>(find.ancestor(of: find.text(text), matching: find.byType(AnswerButton)));
    expect(answer('Izmir').isOracleSuggested, isTrue);
    expect(answer('Ankara').isDisabled, isTrue);
    expect(answer('Bursa').isDisabled, isTrue);

    // Güç dokunuşu sohbette doğrudan gücü kullanır (araya "?" girmez).
    await tester.tap(find.text(_en.get('power_bar_time')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(taps, ['TIME_EXTEND']);
  });

  testWidgets('ChatQuestionPowerBar tek başına da "?" çizmez', (tester) async {
    await tester.pumpWidget(_host(ChatQuestionPowerBar(
      optionCount: 4,
      isPowerBlocked: false,
      hasHint: true,
      onPowerTap: (_) async {},
    )));
    await tester.pump();

    expect(find.byType(PowerHelpButton), findsNothing);
    expect(find.byType(PowerHelpBubble), findsNothing);
  });
}
