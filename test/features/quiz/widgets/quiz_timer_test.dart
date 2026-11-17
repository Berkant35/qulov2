import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

/// Yeniden açılışta sayaç sunucunun kalan süresinden başlar; çubuk sorunun
/// tam süresine göre dolu görünür (12/30 → %40), "taze 12 sn" gibi değil.
///
/// Süre etiketi `FormatManager.seconds` ile yerelleşir (`12s`, ja `12秒`);
/// eskiden her dilde sabit `'12 s'` yazıyordu.
void main() {
  testWidgets('kalan süreden başlar, ilerleme tam süreye oranlanır', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: QuizTimer(seconds: 12, totalSeconds: 30, questionId: 'q1', onTimeout: () {}),
      ),
    ));

    expect(find.text('12s'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(0.4, 0.001));
  });

  testWidgets('totalSeconds yoksa eski davranış: tam dolu başlar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: QuizTimer(seconds: 30, questionId: 'q1', onTimeout: () {})),
    ));

    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, 1.0);
  });

  group('medya için sayaç tutma (holdSeconds)', () {
    final timerKey = GlobalKey<QuizTimerState>();

    Widget timer({
      required int seconds,
      int holdSeconds = 0,
      String questionId = 'q1',
      required VoidCallback onTimeout,
    }) =>
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: QuizTimer(
              key: timerKey,
              seconds: seconds,
              totalSeconds: seconds,
              holdSeconds: holdSeconds,
              questionId: questionId,
              onTimeout: onTimeout,
            ),
          ),
        );

    /// Sayaç bitene kadar saniye saniye ilerletir; bitişin GET'ten kaçıncı saniyede olduğunu döner.
    Future<int> runUntilTimeout(WidgetTester tester, bool Function() timedOut, int elapsed) async {
      while (!timedOut() && elapsed < 120) {
        await tester.pump(const Duration(seconds: 1));
        elapsed++;
      }
      return elapsed;
    }

    testWidgets('tutma boyunca taban süre görünür ve azalmaz, sonra sayar', (tester) async {
      await tester.pumpWidget(timer(seconds: 10, holdSeconds: 5, onTimeout: () {}));

      await tester.pump(const Duration(seconds: 5));
      expect(find.text('10s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('9s'), findsOneWidget);
    });

    testWidgets('release() tutmayı erken bitirir: bir sonraki saniyede sayar', (tester) async {
      await tester.pumpWidget(timer(seconds: 10, holdSeconds: 5, onTimeout: () {}));

      await tester.pump(const Duration(seconds: 2));
      timerKey.currentState!.release();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('9s'), findsOneWidget);
    });

    testWidgets('holdSeconds 0 iken release() etkisiz (eski davranış)', (tester) async {
      await tester.pumpWidget(timer(seconds: 10, onTimeout: () {}));

      await tester.pump(const Duration(seconds: 1));
      timerKey.currentState!.release();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('8s'), findsOneWidget);
    });

    // Değişmez (sunucu son anı): R = L + E iken medya t (≤ E) anında hazırsa sayaç t + L'de,
    // hiç hazır olmazsa E + L'de biter — ikisi de ≤ R. Model + sayaç birlikte (gerçek bağlantı).
    for (final readyAt in [null, 0, 3, 5]) {
      testWidgets('R = L + E, medya hazır: $readyAt → sayaç R içinde biter', (tester) async {
        final q = QuizQuestionModel.fromJson(const {
          'session_id': 's1',
          'question_number': 1,
          'total_questions': 1,
          'question_id': 'q1',
          'question_text': 'Soru',
          'answers': [],
          'time_limit_seconds': 10,
          'remaining_seconds': 15,
          'media_extra_seconds': 5,
          'voice_url': 'https://x/v.m4a',
        });
        var timedOut = false;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: QuizTimer(
              key: timerKey,
              seconds: q.startSeconds,
              totalSeconds: q.timeLimitSeconds,
              holdSeconds: q.mediaHoldSeconds,
              questionId: q.questionId,
              onTimeout: () => timedOut = true,
            ),
          ),
        ));

        var elapsed = 0;
        if (readyAt != null) {
          await tester.pump(Duration(seconds: readyAt));
          elapsed = readyAt;
          timerKey.currentState!.release();
        }
        final endedAt = await runUntilTimeout(tester, () => timedOut, elapsed);

        expect(endedAt, (readyAt ?? 5) + 10);
        expect(endedAt, lessThanOrEqualTo(15));
      });
    }

    testWidgets('pause() tutma sırasında: tutma bitse de duraklı kalır; resume() sayar', (tester) async {
      await tester.pumpWidget(timer(seconds: 10, holdSeconds: 3, onTimeout: () {}));

      timerKey.currentState!.pause();
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('10s'), findsOneWidget);

      timerKey.currentState!.resume();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('9s'), findsOneWidget);
    });

    testWidgets('resume() tutmayı bitirmez (güç/paywall dönüşü)', (tester) async {
      await tester.pumpWidget(timer(seconds: 10, holdSeconds: 5, onTimeout: () {}));

      timerKey.currentState!.pause();
      await tester.pump(const Duration(seconds: 1));
      timerKey.currentState!.resume();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('10s'), findsOneWidget);
    });

    testWidgets('addSeconds() tutma sırasında eklenir, sayım release sonrası', (tester) async {
      await tester.pumpWidget(timer(seconds: 10, holdSeconds: 5, onTimeout: () {}));

      timerKey.currentState!.addSeconds(5);
      await tester.pump();
      expect(find.text('15s'), findsOneWidget);

      timerKey.currentState!.release();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('14s'), findsOneWidget);
    });

    testWidgets('soru değişince yeni sorunun tutması baştan kurulur', (tester) async {
      await tester.pumpWidget(timer(seconds: 10, holdSeconds: 2, onTimeout: () {}));
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('8s'), findsOneWidget);

      await tester.pumpWidget(
        timer(seconds: 10, holdSeconds: 3, questionId: 'q2', onTimeout: () {}),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('10s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('9s'), findsOneWidget);
    });

    // Review fix 1: Q1 tutulurken cevaplanır, Q2'de tutma yok; Q2 medyasının geç `release()`'ı
    // ikinci bir periyodik sayaç kurmamalı (çift hız + dispose sonrası sızan onTimeout).
    testWidgets('tutmalı sorudan tutmasız soruya geçişte release() ikinci sayaç kurmaz', (tester) async {
      var timeouts = 0;
      await tester.pumpWidget(timer(seconds: 10, holdSeconds: 5, onTimeout: () => timeouts++));
      await tester.pump(const Duration(seconds: 1));

      await tester.pumpWidget(timer(seconds: 4, questionId: 'q2', onTimeout: () => timeouts++));
      timerKey.currentState!.release();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('3s'), findsOneWidget, reason: 'saniyede tek azalma');
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(timeouts, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      expect(timeouts, 1, reason: 'dispose sonrası sızan sayaç onTimeout atmaz');
    });

    testWidgets('sayım başladıktan sonra release() etkisiz (tek sayaç)', (tester) async {
      await tester.pumpWidget(timer(seconds: 10, holdSeconds: 1, onTimeout: () {}));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('9s'), findsOneWidget);

      timerKey.currentState!.release();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('8s'), findsOneWidget);
    });

    testWidgets('dispose tutma zamanlayıcısını iptal eder (bekleyen timer kalmaz)', (tester) async {
      await tester.pumpWidget(timer(seconds: 10, holdSeconds: 5, onTimeout: () {}));
      await tester.pumpWidget(const SizedBox());
      // Bekleyen Timer kalsaydı test çerçevesi "A Timer is still pending" ile düşerdi.
    });
  });
}
