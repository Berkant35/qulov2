import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/features/power_demo/constants/power_demo_keys.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_question.dart';
import 'package:qulo_v2/features/power_demo/providers/power_demo_notifier.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_view.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_confirm_button.dart';

/// Ekrandaki güç demosunu kullanıcı gibi oynatır (carousel ve `power-demo` route testleri ortak).
///
/// Senaryo ve durum gerçek notifier'dan okunur; dokunuşlar ekrandaki gerçek düğmelere gider.
/// Hep doğru cevap verir. Cevapla'ya kaydırmadan dokunur — Cevapla soru alanının dışında,
/// güç çubuğunun üstünde sabit durmalı (küçük ekranda da).
class PowerDemoDriver {
  PowerDemoDriver(
    this.tester, {
    required this.entryPoint,
    this.texts = enTranslations,
  });

  final WidgetTester tester;
  final PowerDemoEntryPoint entryPoint;
  final Map<String, String> texts;

  ProviderContainer get _container =>
      ProviderScope.containerOf(tester.element(find.byType(PowerDemoView)));

  PowerDemoProgress get progress =>
      _container.read(powerDemoProvider(entryPoint));

  PowerDemoQuestion get question => _container
      .read(powerDemoProvider(entryPoint).notifier)
      .scenario
      .questions[progress.stepIndex];

  String t(String key) => texts[key]!;

  Finder get confirmButton => find.byType(QuizConfirmButton);

  /// Sonsuz dönen animasyonlar (sayaç nabzı, carousel arka planı) yüzünden `pumpAndSettle` yok.
  Future<void> settle([int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Demoyu bir eylem ilerletir: Başla / güce dokun / doğru şıkkı seç + Cevapla.
  /// [onAnswerReady] şık seçildikten sonra, Cevapla'ya dokunmadan ÖNCE çağrılır.
  Future<void> playOne({
    void Function(PowerDemoQuestion question)? onAnswerReady,
  }) async {
    switch (progress.phase) {
      case PowerDemoPhase.intro:
        await tester.tap(find.text(t('power_demo_start')));
      case PowerDemoPhase.awaitingPower:
        final power = question.power!;
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is PowerBarButton && w.type.apiName == power.apiName,
          ),
        );
      case PowerDemoPhase.awaitingAnswer:
        final q = question;
        await selectOption(q, q.correctIndex);
        onAnswerReady?.call(q);
        await tester.tap(confirmButton);
      case PowerDemoPhase.rescue:
      case PowerDemoPhase.skippingAll:
      case PowerDemoPhase.finale:
      case PowerDemoPhase.skipped:
        break;
    }
    await settle();
  }

  Future<void> playUntil(
    bool Function(PowerDemoProgress p) done, {
    void Function(PowerDemoQuestion question)? onAnswerReady,
  }) async {
    for (var guard = 0; !done(progress); guard++) {
      expect(
        guard,
        lessThan(40),
        reason: 'demo ilerlemiyor: ${progress.phase}',
      );
      await playOne(onAnswerReady: onAnswerReady);
    }
  }

  /// Kullanıcı gibi seçer: küçük ekranda önce soru alanının sonuna kaydırıp şıkları görür,
  /// sonra dokunur (son şık alanın tam alt kenarında — Cevapla belirince kırpılma riski).
  Future<void> selectOption(PowerDemoQuestion q, int index) async {
    final option = find.text(t(PowerDemoKeys.option(q, index)));
    final scroll = find
        .ancestor(of: option, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(scroll).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    if (option.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(option);
    }
    await tester.tap(option);
    // Seçilen şık bir kare sonra görünür alana kayar (`KeepVisibleOnSelect`, ~250 ms).
    await settle(6);
  }

  /// Şık seçili: Cevapla soru alanının dışında, [screen] içinde ve dokunulabilir; seçilen şık
  /// soru alanında tam görünür.
  void expectAnswerReachable(Rect screen, {String reason = ''}) {
    expect(confirmButton, findsOneWidget, reason: reason);
    expect(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: confirmButton,
      ),
      findsNothing,
      reason: '$reason: Cevapla kaydırma alanının dışında',
    );
    final confirm = tester.getRect(confirmButton);
    expect(
      confirm.top >= screen.top && confirm.bottom <= screen.bottom,
      isTrue,
      reason: '$reason: Cevapla ekranda ($confirm / $screen)',
    );
    expect(
      confirmButton.hitTestable(),
      findsOneWidget,
      reason: '$reason: Cevapla dokunulabilir',
    );

    final selected = find.byWidgetPredicate(
      (w) => w is AnswerButton && w.isSelected,
    );
    final viewport = tester.getRect(
      find
          .ancestor(of: selected, matching: find.byType(SingleChildScrollView))
          .first,
    );
    final option = tester.getRect(selected);
    expect(
      option.top >= viewport.top - 0.5 &&
          option.bottom <= viewport.bottom + 0.5,
      isTrue,
      reason:
          '$reason: seçilen şık soru alanında tam görünür ($option / $viewport)',
    );
  }
}
