import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/one_time_flag_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('isSet bayrak yokken false doner', () async {
    expect(await OneTimeFlagStore.isSet('flag_a'), isFalse);
  });

  test('mark sonrasi isSet true doner', () async {
    await OneTimeFlagStore.mark('flag_a');
    expect(await OneTimeFlagStore.isSet('flag_a'), isTrue);
  });

  test('markIfUnset ilk cagride true, ikincide false doner', () async {
    expect(await OneTimeFlagStore.markIfUnset('flag_b'), isTrue);
    expect(await OneTimeFlagStore.markIfUnset('flag_b'), isFalse);
    expect(await OneTimeFlagStore.isSet('flag_b'), isTrue);
  });

  test('markIfUnset onceden set edilmis bayrak icin false doner ve bozmaz', () async {
    SharedPreferences.setMockInitialValues({'flag_c': true});
    expect(await OneTimeFlagStore.markIfUnset('flag_c'), isFalse);
    expect(await OneTimeFlagStore.isSet('flag_c'), isTrue);
  });

  test('clear bayragi siler', () async {
    await OneTimeFlagStore.mark('flag_d');
    await OneTimeFlagStore.clear('flag_d');
    expect(await OneTimeFlagStore.isSet('flag_d'), isFalse);
  });

  test('bayraklar birbirinden bagimsiz', () async {
    await OneTimeFlagStore.mark('flag_e');
    expect(await OneTimeFlagStore.isSet('flag_f'), isFalse);
  });
}
