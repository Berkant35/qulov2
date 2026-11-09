import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/observers/route_change_notifier.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/power_effects/half_strike_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/hint_reveal_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/oracle_highlight.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_slide_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/time_extend_effect.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/quiz_repository.dart';
import 'package:qulo_v2/features/quiz/coach/quiz_power_coach_marks.dart';
import 'package:qulo_v2/features/quiz/screens/quiz_screen.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_bubble.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_button.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_confirm_button.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_question_content.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Gerçek quiz ekranı demodaki efektleri gösterir (spec §4.3, §5) — yalnız görsel:
/// güç mantığı, maliyet ve sunucu akışı aynı. Efektler yalnız sunucu BAŞARI dalında oynar
/// (spec §13.2/7); "?" baloncuğu gücü kullanmaz, `quiz_power_tap` atmaz, sayacı durdurmaz.
final _en = AppLocalizations(const Locale('en'));

const _q1 = QuizQuestionModel(
  sessionId: 's1',
  questionNumber: 1,
  totalQuestions: 3,
  questionId: 'q1',
  questionText: 'Q1?',
  answers: [
    QuizAnswerOption(index: 0, text: 'A'),
    QuizAnswerOption(index: 1, text: 'B'),
    QuizAnswerOption(index: 2, text: 'C'),
    QuizAnswerOption(index: 3, text: 'D'),
  ],
);

const _q2 = QuizQuestionModel(
  sessionId: 's1',
  questionNumber: 2,
  totalQuestions: 3,
  questionId: 'q2',
  questionText: 'Q2?',
  answers: [
    QuizAnswerOption(index: 0, text: 'E'),
    QuizAnswerOption(index: 1, text: 'F'),
    QuizAnswerOption(index: 2, text: 'G'),
    QuizAnswerOption(index: 3, text: 'H'),
  ],
);

String _oracleLabel(int percent) => _en
    .get('power_oracle_accuracy')
    .replaceAll('{percent}', FormatManager.instance.percent(percent));

Finder _helpButton(PowerType type) =>
    find.byWidgetPredicate((w) => w is PowerHelpButton && w.type == type);

Finder _powerButton(PowerType type) =>
    find.byWidgetPredicate((w) => w is PowerBarButton && w.type == type);

Widget _app(
  Widget home, {
  List<Override> overrides = const [],
  double textScale = 1,
}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.dark,
    navigatorObservers: [RouteChangeObserver()],
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  ),
);

/// `QuizQuestionContent`'i girdileriyle yeniden çizer (aynı eleman → efektler didUpdateWidget ile oynar).
class _Content {
  _Content(this.tester);

  final WidgetTester tester;
  final timerKey = GlobalKey<QuizTimerState>();
  final selected = <int>[];
  final powersUsed = <String>[];

  Future<void> pump({
    QuizQuestionModel question = _q1,
    List<int> removed = const [],
    int? oracle,
    String? hint,
    int? selectedIndex,
    int timeToken = 0,
    int skipToken = 0,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: QuizQuestionContent(
            question: question,
            timerKey: timerKey,
            sessionId: 's1',
            selectedAnswerIndex: selectedIndex,
            oracleSuggestedIndex: oracle,
            removedIndices: removed,
            hintText: hint,
            isSubmitting: false,
            timeExtendEffectToken: timeToken,
            skipEffectToken: skipToken,
            onTimeout: () {},
            onSelectAnswer: selected.add,
            onSubmitAnswer: () async {},
            onPowerUsed: (power) async => powersUsed.add(power),
          ),
        ),
        textScale: textScale,
      ),
    );
    // İlk çizimde çeviriler yüklenene kadar ağaç boştur.
    await tester.pump();
  }

  Finder halfFinder(String text) => find.ancestor(
    of: find.text(text),
    matching: find.byType(HalfStrikeEffect),
  );

  HalfStrikeEffect half(String text) =>
      tester.widget<HalfStrikeEffect>(halfFinder(text));

  OracleHighlight oracle(String text) => tester.widget<OracleHighlight>(
    find.ancestor(of: find.text(text), matching: find.byType(OracleHighlight)),
  );
}

void main() {
  group('QuizQuestionContent efektleri', () {
    testWidgets('removedIndices gelince iki şık HalfStrikeEffect ile kapanır', (
      tester,
    ) async {
      final c = _Content(tester);
      await c.pump();
      expect(
        ['A', 'B', 'C', 'D'].map((t) => c.half(t).removed).toList(),
        everyElement(isFalse),
      );

      await c.pump(removed: [0, 2]);
      await tester.pump(PowerEffectTiming.enter);

      expect(c.half('A').removed, isTrue);
      expect(c.half('C').removed, isTrue);
      expect(c.half('B').removed, isFalse);
      expect(c.half('D').removed, isFalse);
      expect(
        tester.getSize(c.halfFinder('A')).height,
        0,
        reason: 'elenen şıkkın yüksekliği kapanır',
      );
      expect(tester.getSize(c.halfFinder('B')).height, greaterThan(0));

      final answerA = find.ancestor(
        of: find.text('A'),
        matching: find.byType(AnswerButton),
      );
      expect(
        tester.widget<AnswerButton>(answerA).isDisabled,
        isTrue,
        reason: 'elenen şık seçilemez',
      );
      await tester.tap(find.text('B'));
      expect(c.selected, [1]);
    });

    testWidgets('oracleSuggestedIndex gelince %70 etiketi', (tester) async {
      final c = _Content(tester);
      await c.pump();
      expect(find.byKey(OracleHighlight.labelKey), findsNothing);

      await c.pump(oracle: 1);
      await tester.pump(PowerEffectTiming.enter);

      // EconomyConfig.fallback → oracleAccuracy 0.7.
      expect(find.text(_oracleLabel(70)), findsOneWidget);
      expect(c.oracle('B').active, isTrue);
      expect(c.oracle('A').active, isFalse);
      // Sonsuz nabız yerine tek giriş animasyonu (spec §5); eski banner da yok.
      expect(
        tester
            .widgetList<AnswerButton>(find.byType(AnswerButton))
            .where((b) => b.isOracleSuggested),
        isEmpty,
      );
      expect(find.text(_en.get('power_oracle_desc')), findsNothing);
    });

    testWidgets(
      'Ek Süre jetonu "+N" çipini oynatır; çip sonraki soruya taşınmaz',
      (tester) async {
        final c = _Content(tester);
        await c.pump();
        expect(find.byKey(TimeExtendEffect.chipKey), findsNothing);

        await c.pump(timeToken: 1);
        await tester.pump(PowerEffectTiming.enter);
        expect(find.byKey(TimeExtendEffect.chipKey), findsOneWidget);
        // N config'den (`timing.timeExtendSeconds`, yedek 15), sabit "+15sn" metni değil.
        expect(
          find.text('+${FormatManager.instance.integer(15)}'),
          findsOneWidget,
        );

        await c.pump(timeToken: 1, question: _q2);
        await tester.pump();
        expect(find.byKey(TimeExtendEffect.chipKey), findsNothing);
      },
    );

    testWidgets(
      'Doğru Say jetonu soru kartını kaydırır; sıradaki soru taze kartla gelir',
      (tester) async {
        final c = _Content(tester);
        await c.pump();
        expect(find.byKey(SkipSlideEffect.badgeKey), findsNothing);

        await c.pump(skipToken: 1);
        await tester.pump(PowerEffectTiming.enter);
        expect(find.byKey(SkipSlideEffect.badgeKey), findsOneWidget);

        await c.pump(skipToken: 1, question: _q2);
        await tester.pump();
        expect(find.byKey(SkipSlideEffect.badgeKey), findsNothing);
        await tester.tap(find.text('F'));
        expect(c.selected, [1], reason: 'yeni kart dokunuş alır');
      },
    );

    testWidgets('ipucu gelince soru altında ipucu kartı açılır', (
      tester,
    ) async {
      final c = _Content(tester);
      await c.pump();
      expect(find.text('sand'), findsNothing);

      await c.pump(hint: 'sand');
      await tester.pump(PowerEffectTiming.enter);

      expect(
        find.descendant(
          of: find.byType(HintRevealEffect),
          matching: find.text('sand'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'küçük ekran + büyük yazı: taşma yok, güç çubuğu ve baloncuk şıkları/sayacı örtmez',
      (tester) async {
        tester.view.physicalSize = const Size(375, 591);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final c = _Content(tester);

        await c.pump(oracle: 1, hint: 'sand', selectedIndex: 1, textScale: 1.3);
        await tester.pump(PowerEffectTiming.enter);
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byType(PowerBar)).bottom,
          lessThanOrEqualTo(591),
        );

        await tester.tap(_helpButton(PowerType.half));
        await tester.pump();
        await tester.pump(PowerEffectTiming.enter);
        expect(tester.takeException(), isNull);

        final bubble = tester.getRect(find.byType(PowerHelpBubble));
        final questionArea = tester.getRect(find.byType(SingleChildScrollView));
        expect(
          bubble.top,
          greaterThanOrEqualTo(questionArea.bottom),
          reason: 'şıklar soru alanında kalır',
        );
        expect(
          bubble.top,
          greaterThan(tester.getRect(find.byType(QuizTimer)).bottom),
        );
        expect(bubble.bottom, lessThanOrEqualTo(591));
      },
    );

    for (final (size, scale) in const [
      (Size(375, 591), 1.0),
      (Size(375, 591), 1.3),
      (Size(390, 707), 1.0),
      (Size(390, 707), 1.3),
    ]) {
      testWidgets(
        'Cevapla her zaman görünür: ${size.width.toInt()}×${size.height.toInt()} textScale $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final c = _Content(tester);

          await c.pump(
            oracle: 1,
            hint: 'sand',
            selectedIndex: 1,
            textScale: scale,
          );
          await tester.pump(PowerEffectTiming.enter);

          final confirm = find.byType(QuizConfirmButton);
          final viewport = tester.getRect(find.byType(SingleChildScrollView));
          expect(
            find.descendant(
              of: find.byType(SingleChildScrollView),
              matching: confirm,
            ),
            findsNothing,
            reason: 'Cevapla kaydırma alanının dışında',
          );
          expect(
            tester.getRect(confirm).top,
            greaterThanOrEqualTo(viewport.bottom),
          );
          expect(
            tester.getRect(confirm).bottom,
            lessThanOrEqualTo(size.height),
          );
          expect(
            confirm.hitTestable(),
            findsOneWidget,
            reason: 'ekranda ve dokunulabilir',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    // Cevapla belirince soru alanı daralır: alt kenardaki seçili şık kırpılmasın (demo ile ortak
    // `KeepVisibleOnSelect`). Kullanıcı önce sona kaydırıp son şıkkı (D) seçer.
    testWidgets(
      '375×591: alt kenardaki son şık seçilince Cevapla belirir, şık görünür kalır',
      (tester) async {
        tester.view.physicalSize = const Size(375, 591);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final c = _Content(tester);
        await c.pump(oracle: 1, hint: 'sand');
        await tester.pump(PowerEffectTiming.enter);
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();

        Rect optionD() => tester.getRect(
          find.ancestor(
            of: find.text('D'),
            matching: find.byType(AnswerButton),
          ),
        );
        Rect viewport() => tester.getRect(find.byType(SingleChildScrollView));

        await c.pump(oracle: 1, hint: 'sand', selectedIndex: 3);
        expect(
          optionD().bottom,
          greaterThan(viewport().bottom),
          reason: 'ön koşul: Cevapla alanı daralttı, D kırpıldı',
        );

        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          optionD().bottom,
          lessThanOrEqualTo(viewport().bottom + 0.5),
          reason: 'seçilen şık tam görünür',
        );
        expect(optionD().top, greaterThanOrEqualTo(viewport().top - 0.5));
        expect(find.byType(QuizConfirmButton).hitTestable(), findsOneWidget);
      },
    );

    testWidgets('görünür şık seçilince soru alanı kaymaz', (tester) async {
      final c = _Content(tester);
      await c.pump();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final before = position.pixels;

      await c.pump(selectedIndex: 0);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(position.pixels, before);
    });

    testWidgets('? ile güç butonu ayrı: ?\'ye dokunmak onPowerUsed çağırmaz', (
      tester,
    ) async {
      final c = _Content(tester);
      await c.pump();

      await tester.tap(_helpButton(PowerType.half));
      await tester.pump();
      expect(c.powersUsed, isEmpty);
      expect(find.byType(PowerHelpBubble), findsOneWidget);

      await tester.tap(_powerButton(PowerType.half));
      await tester.pump();
      expect(c.powersUsed, ['HALF']);
      expect(
        find.byType(PowerHelpBubble),
        findsNothing,
        reason: 'güce dokunmak baloncuğun dışı',
      );
    });

    testWidgets(
      'baloncuk açıkken şıkka dokunmak hem kapatır hem seçer (modal değil)',
      (tester) async {
        final c = _Content(tester);
        await c.pump();
        await tester.tap(_helpButton(PowerType.oracle));
        await tester.pump();

        await tester.tap(find.text('C'));
        await tester.pump();

        expect(c.selected, [2]);
        expect(find.byType(PowerHelpBubble), findsNothing);
      },
    );

    testWidgets('açık baloncuk sonraki soruya taşınmaz', (tester) async {
      final c = _Content(tester);
      await c.pump();
      await tester.tap(_helpButton(PowerType.skip));
      await tester.pump();
      expect(find.byType(PowerHelpBubble), findsOneWidget);

      await c.pump(question: _q2);
      await tester.pump();
      expect(find.byType(PowerHelpBubble), findsNothing);
    });
  });

  group('gerçek quiz ekranı (QuizPowerMixin → içerik)', () {
    late List<({String name, Map<String, Object>? params})> events;

    setUp(() {
      events = [];
      AnalyticsManager.debugEventSink = (name, params) =>
          events.add((name: name, params: params));
      AnalyticsForwarder.debugTrackSink = (_, __, ___) {};
      // logAuthed AnalyticsForwarder'a da yazar (15 sn'lik zamanlayıcı kurar).
      AnalyticsForwarder.instance.setEnabled(false);
      HapticManager.instance.setEnabled(false);
    });

    tearDown(() {
      HapticManager.instance.setEnabled(true);
      AnalyticsManager.debugEventSink = null;
      AnalyticsForwarder.debugTrackSink = null;
      AnalyticsForwarder.instance.setEnabled(true);
      CoachMarkService.instance.forceClose();
    });

    List<String> names() => events.map((e) => e.name).toList();

    testWidgets(
      '? dokunuşu baloncuk açar, quiz_power_tap atılmaz, quiz_power_help_open atılır, sayaç durmaz',
      (tester) async {
        final q = await _pumpQuizScreen(tester);
        events.clear();
        final before = tester
            .state<QuizTimerState>(find.byType(QuizTimer))
            .remainingSeconds;

        await tester.tap(_helpButton(PowerType.half));
        await tester.pump();

        expect(find.byType(PowerHelpBubble), findsOneWidget);
        expect(find.text(_en.get('power_half_desc')), findsOneWidget);
        expect(names(), [AnalyticsEvents.quizPowerHelpOpen]);
        expect(events.single.params, {AnalyticsEvents.paramPower: 'HALF'});
        expect(
          q.repo.answerCalls,
          0,
          reason: 'güç kullanılmadı, sunucuya gidilmedi',
        );

        await tester.pump(const Duration(seconds: 2));
        expect(
          tester.state<QuizTimerState>(find.byType(QuizTimer)).remainingSeconds,
          before - 2,
          reason: 'baloncuk sayacı durdurmaz',
        );
        expect(names(), isNot(contains(AnalyticsEvents.quizPowerTap)));
      },
    );

    testWidgets('güç hatasında (INSUFFICIENT_DIAMONDS) efekt oynamaz', (
      tester,
    ) async {
      final q = await _pumpQuizScreen(tester);
      q.repo.answerResult = const Failure(
        ServerFailure(code: 'INSUFFICIENT_DIAMONDS'),
      );

      await tester.tap(_powerButton(PowerType.timeExtend));
      await tester.pump();
      await tester.pump(PowerEffectTiming.enter);

      expect(q.nav.sheets, ['paywall'], reason: 'hata dalı: paywall açıldı');
      expect(find.byKey(TimeExtendEffect.chipKey), findsNothing);
      // Paywall sonrası 1.5 sn tampon + bakiye tazeleme biter.
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump();

      q.repo.answerResult = const Failure(
        ServerFailure(code: 'INSUFFICIENT_DIAMONDS'),
      );
      await tester.tap(_powerButton(PowerType.half));
      await tester.pump();
      await tester.pump(PowerEffectTiming.enter);
      expect(
        tester
            .widgetList<HalfStrikeEffect>(find.byType(HalfStrikeEffect))
            .where((h) => h.removed),
        isEmpty,
      );
      expect(find.byKey(SkipSlideEffect.badgeKey), findsNothing);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump();
    });

    testWidgets(
      'sunucu başarısında efekt oynar: Ek Süre çipi, Yarıla iki şık',
      (tester) async {
        final q = await _pumpQuizScreen(tester);
        q.repo.answerResult = const Success(
          QuizAnswerResponse(
            awaitingAnswer: true,
            powerResult: {'extra_seconds': 15},
          ),
        );
        final before = tester
            .state<QuizTimerState>(find.byType(QuizTimer))
            .remainingSeconds;

        await tester.tap(_powerButton(PowerType.timeExtend));
        await tester.pump();
        await tester.pump(PowerEffectTiming.enter);

        expect(find.byKey(TimeExtendEffect.chipKey), findsOneWidget);
        expect(
          tester.state<QuizTimerState>(find.byType(QuizTimer)).remainingSeconds,
          before + 15,
        );

        q.repo.answerResult = const Success(
          QuizAnswerResponse(
            awaitingAnswer: true,
            powerResult: {
              'removed_indices': [0, 2],
            },
          ),
        );
        await tester.tap(_powerButton(PowerType.half));
        await tester.pump();
        await tester.pump(PowerEffectTiming.enter);
        final removed = tester
            .widgetList<HalfStrikeEffect>(find.byType(HalfStrikeEffect))
            .where((h) => h.removed);
        expect(removed, hasLength(2));
      },
    );

    testWidgets('Yarıla seçili şıkkı elerse seçim temizlenir, Cevapla kalkar', (
      tester,
    ) async {
      final q = await _pumpQuizScreen(tester);
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(find.byType(QuizConfirmButton), findsOneWidget);

      q.repo.answerResult = const Success(
        QuizAnswerResponse(
          awaitingAnswer: true,
          powerResult: {
            'removed_indices': [0, 2],
          },
        ),
      );
      await tester.tap(_powerButton(PowerType.half));
      await tester.pump();
      await tester.pump(PowerEffectTiming.enter);

      expect(
        find.byType(QuizConfirmButton),
        findsNothing,
        reason: 'görünmeyen şık gönderilemez',
      );
      expect(
        tester
            .widgetList<AnswerButton>(find.byType(AnswerButton))
            .where((b) => b.isSelected),
        isEmpty,
      );
    });

    testWidgets('Yarıla seçili olmayan şıkları elerse seçim korunur', (
      tester,
    ) async {
      final q = await _pumpQuizScreen(tester);
      await tester.tap(find.text('B'));
      await tester.pump();

      q.repo.answerResult = const Success(
        QuizAnswerResponse(
          awaitingAnswer: true,
          powerResult: {
            'removed_indices': [0, 2],
          },
        ),
      );
      await tester.tap(_powerButton(PowerType.half));
      await tester.pump();
      await tester.pump(PowerEffectTiming.enter);

      expect(find.byType(QuizConfirmButton), findsOneWidget);
      final b = tester.widget<AnswerButton>(
        find.ancestor(of: find.text('B'), matching: find.byType(AnswerButton)),
      );
      expect(b.isSelected, isTrue);
    });

    testWidgets(
      'Doğru Say başarısında kart kayar; sıradaki soru efekti beklemeden istenir',
      (tester) async {
        final q = await _pumpQuizScreen(tester);
        // Kapı test gövdesinde kurulur (setUp'taki Completer pump ile ilerlemiyor).
        final gate = Completer<void>();
        q.repo.nextQuestionGate = gate;
        q.repo.answerResult = const Success(
          QuizAnswerResponse(isCorrect: true, sessionStatus: 'IN_PROGRESS'),
        );

        await tester.tap(_powerButton(PowerType.skip));
        await tester.pump();
        expect(
          q.repo.questionCalls,
          2,
          reason: 'geçiş efekti beklemez, sıradaki soru hemen istenir',
        );

        await tester.pump(PowerEffectTiming.enter);
        expect(
          find.byKey(SkipSlideEffect.badgeKey),
          findsOneWidget,
          reason: 'soru yüklenirken kart kaydı',
        );

        gate.complete();
        await tester.pump();
        await tester.pump();
        expect(find.text('Q2?'), findsOneWidget);
        expect(
          find.byKey(SkipSlideEffect.badgeKey),
          findsNothing,
          reason: 'yeni soru taze kartla',
        );
      },
    );

    testWidgets('Doğru Say hatasında kart kaymaz', (tester) async {
      final q = await _pumpQuizScreen(tester);
      q.repo.answerResult = const Failure(
        ServerFailure(code: 'INSUFFICIENT_DIAMONDS'),
      );

      await tester.tap(_powerButton(PowerType.skip));
      await tester.pump();
      await tester.pump(PowerEffectTiming.enter);

      expect(find.byKey(SkipSlideEffect.badgeKey), findsNothing);
      expect(find.text('Q1?'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump();
    });
  });
}

// ─── Gerçek QuizScreen harness ─────────────────────────────────────────────

typedef _Screen = ({_FakeQuizRepository repo, FakeNavigationService nav});

Future<_Screen> _pumpQuizScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await CoachMarkService.instance.markSeen(quizPowersTourId);
  final repo = _FakeQuizRepository();
  final nav = FakeNavigationService();
  await tester.pumpWidget(
    _app(
      const QuizScreen(targetId: 'target-1'),
      overrides: [
        quizRepositoryProvider.overrideWithValue(repo),
        exchangeRepositoryProvider.overrideWithValue(FakeExchangeRepository()),
        diamondRepositoryProvider.overrideWithValue(FakeDiamondRepository()),
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository(const UserModel(id: 'u1', email: 'u1@qulo.test')),
        ),
        navigationServiceProvider.overrideWithValue(nav),
      ],
    ),
  );
  await tester.pumpAndSettle();
  expect(
    find.text('Q1?'),
    findsOneWidget,
    reason: 'oturum açıldı, ilk soru çizildi',
  );
  return (repo: repo, nav: nav);
}

class _FakeQuizRepository implements QuizRepository {
  Result<QuizAnswerResponse> answerResult = const Success(
    QuizAnswerResponse(awaitingAnswer: true),
  );
  int answerCalls = 0;
  int questionCalls = 0;

  /// Doluysa ikinci soru bu tamamlanana kadar gelmez (geçiş sırasında kart görünür kalsın).
  Completer<void>? nextQuestionGate;

  @override
  Future<Result<QuizStartResponse>> startSession(String targetId) async =>
      const Success(
        QuizStartResponse(
          sessionId: 's1',
          totalQuestions: 3,
          powerCosts: {
            'HALF': SessionPowerCost(purple: 40, green: 0),
            'TIME_EXTEND': SessionPowerCost(purple: 20, green: 0),
            'SKIP': SessionPowerCost(purple: 60, green: 0),
          },
        ),
      );

  @override
  Future<Result<QuizQuestionModel>> getCurrentQuestion(String sessionId) async {
    if (questionCalls++ == 0) return const Success(_q1);
    await nextQuestionGate?.future;
    return const Success(_q2);
  }

  @override
  Future<Result<QuizAnswerResponse>> answerQuestion(
    String sessionId, {
    int? selectedAnswer,
    String? powerUsed,
    int? timeSpent,
  }) async {
    answerCalls++;
    return answerResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeQuizRepository.${invocation.memberName}');
}
