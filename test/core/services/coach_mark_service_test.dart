import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('isSeen is false by default, true after markSeen', () async {
    final s = CoachMarkService.instance;
    expect(await s.isSeen('discover'), isFalse);
    await s.markSeen('discover');
    expect(await s.isSeen('discover'), isTrue);
  });

  test('markSeen writes the coach_<tour>_seen flag', () async {
    await CoachMarkService.instance.markSeen('quiz_powers');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('coach_quiz_powers_seen'), isTrue);
  });

  test('isTourActive is false when no overlay is shown', () {
    expect(CoachMarkService.instance.isTourActive, isFalse);
  });
}
