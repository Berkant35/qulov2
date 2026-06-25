import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_registry.dart';

void main() {
  test('keyFor returns the same GlobalKey for the same id', () {
    final a = CoachMarkRegistry.keyFor('discover_solve');
    final b = CoachMarkRegistry.keyFor('discover_solve');
    expect(identical(a, b), isTrue);
  });

  test('keyFor returns different keys for different ids', () {
    final a = CoachMarkRegistry.keyFor('x1');
    final b = CoachMarkRegistry.keyFor('x2');
    expect(identical(a, b), isFalse);
  });

  test('maybeKey returns null for unknown id', () {
    expect(CoachMarkRegistry.maybeKey('never_registered'), isNull);
  });

  test('maybeKey returns the key after keyFor', () {
    final k = CoachMarkRegistry.keyFor('y1');
    expect(CoachMarkRegistry.maybeKey('y1'), same(k));
  });
}
