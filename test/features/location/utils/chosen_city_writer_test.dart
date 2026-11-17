import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';
import 'package:qulo_v2/features/location/utils/chosen_city_writer.dart';

class _Cities implements ICityRepository {
  _Cities({this.result = const Success(null), this.throws = false});

  final Result<void> result;
  final bool throws;
  final saved = <String>[];

  @override
  Future<Result<void>> setCity(String cityId) async {
    saved.add(cityId);
    if (throws) throw StateError('boom');
    return result;
  }

  @override
  Future<Result<CityListResponse>> search({String? country, String query = '', int limit = 100}) =>
      throw UnimplementedError();
}

void main() {
  late List<Map<String, Object?>> events;

  setUp(() {
    events = [];
    AnalyticsManager.debugEventSink = (name, params) => events.add({'event': name, ...?params});
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  test('başarılı yazım: şehir id sunucuya gider, true döner, hata olayı yok', () async {
    final cities = _Cities();

    final ok = await ChosenCityWriter.write(cities, 'TR-istanbul', source: AnalyticsEvents.sourceRegister);

    expect(ok, isTrue);
    expect(cities.saved, ['TR-istanbul']);
    expect(events, isEmpty);
  });

  test('sunucu hatası: false döner, fırlatmaz, hata olayı source ile atılır', () async {
    final cities = _Cities(result: const Failure(NetworkFailure()));

    final ok = await ChosenCityWriter.write(cities, 'TR-izmir', source: AnalyticsEvents.sourceRegister);

    expect(ok, isFalse);
    expect(events, [
      {'event': AnalyticsEvents.onboardingCitySaveFail, AnalyticsEvents.paramSource: 'register'},
    ]);
  });

  test('istisna (ör. ağ katmanı patlaması) da yutulur: kullanıcı kilitlenmez', () async {
    final cities = _Cities(throws: true);

    final ok = await ChosenCityWriter.write(cities, 'IT-rome', source: AnalyticsEvents.sourceProfileCompletion);

    expect(ok, isFalse);
    expect(events.single['event'], AnalyticsEvents.onboardingCitySaveFail);
    expect(events.single[AnalyticsEvents.paramSource], 'profile_completion');
  });
}
