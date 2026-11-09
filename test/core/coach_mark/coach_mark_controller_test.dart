import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_controller.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';

void main() {
  List<String> log = [];
  CoachMarkStep step(String id) => CoachMarkStep(
        titleKey: 't_$id', bodyKey: 'b_$id', ctaKey: 'c_$id',
        onShow: () => log.add('show_$id'),
        onDismiss: () => log.add('dismiss_$id'),
      );

  setUp(() => log = []);

  test('start fires first onShow and sets index 0', () {
    final c = CoachMarkController(steps: [step('a'), step('b')]);
    c.start();
    expect(c.index, 0);
    expect(log, ['show_a']);
  });

  test('start is idempotent', () {
    final c = CoachMarkController(steps: [step('a')]);
    c.start();
    c.start();
    expect(log, ['show_a']);
  });

  test('next dismisses current and shows the next', () {
    final c = CoachMarkController(steps: [step('a'), step('b')]);
    c.start();
    c.next();
    expect(c.index, 1);
    expect(log, ['show_a', 'dismiss_a', 'show_b']);
  });

  test('next on last step finishes and fires onFinished', () {
    var finished = false;
    final c = CoachMarkController(steps: [step('a')])..onFinished = ({required skipped, required stepIndex}) => finished = true;
    c.start();
    c.next();
    expect(c.finished, isTrue);
    expect(finished, isTrue);
    expect(log, ['show_a', 'dismiss_a']);
  });

  test('skipAll dismisses current then finishes', () {
    var finished = false;
    final c = CoachMarkController(steps: [step('a'), step('b')])..onFinished = ({required skipped, required stepIndex}) => finished = true;
    c.start();
    c.skipAll();
    expect(c.finished, isTrue);
    expect(finished, isTrue);
    expect(log, ['show_a', 'dismiss_a']);
  });

  test('onFinished: son adımda next → skipped=false, stepIndex 1 tabanlı (= adım sayısı)', () {
    final results = <({bool skipped, int stepIndex})>[];
    final c = CoachMarkController(steps: [step('a'), step('b')])
      ..onFinished = ({required skipped, required stepIndex}) =>
          results.add((skipped: skipped, stepIndex: stepIndex));
    c.start();
    c.next();
    expect(results, isEmpty, reason: 'ara adımda bitiş sinyali yok');
    c.next();
    expect(results, [(skipped: false, stepIndex: 2)]);
  });

  test('onFinished: skipAll → skipped=true, stepIndex o anki adım (1 tabanlı)', () {
    final results = <({bool skipped, int stepIndex})>[];
    final c = CoachMarkController(steps: [step('a'), step('b'), step('c')])
      ..onFinished = ({required skipped, required stepIndex}) =>
          results.add((skipped: skipped, stepIndex: stepIndex));
    c.start();
    c.next();
    c.skipAll();
    expect(results, [(skipped: true, stepIndex: 2)]);
  });

  test('onFinished bir kez tetiklenir: bitişten sonra next/skipAll yok sayılır', () {
    var count = 0;
    final c = CoachMarkController(steps: [step('a')])
      ..onFinished = ({required skipped, required stepIndex}) => count++;
    c.start();
    c.next();
    c.next();
    c.skipAll();
    expect(count, 1);
  });
}
