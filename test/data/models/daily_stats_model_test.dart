import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';

/// Gunluk kullanim limitleri (keşif, geri alma, soru slotu).
///
/// Sozlesme qulo-server `subscription.service.ts` → `getDailyStats`: camelCase;
/// sinirsiz limit (config'te ≥ 999999) **-1** olarak gelir. -1'i 0 ile
/// karistirmak Premium kullaniciya "hakkin bitti" dedirtirdi.
void main() {
  test('sunucu yaniti eksiksiz parse edilir', () {
    final s = DailyStats.fromJson({
      'dailyDiscoversUsed': 12,
      'dailyDiscoversLimit': 50,
      'dailyUndosUsed': 1,
      'dailyUndosLimit': 3,
      'questionsCreated': 2,
      'questionsLimit': 6,
      'monthlyPurpleBonus': 500,
      'passportMode': false,
      'hasAds': false,
    });

    expect((s.dailyDiscoversUsed, s.dailyDiscoversLimit), (12, 50));
    expect((s.dailyUndosUsed, s.dailyUndosLimit), (1, 3));
    expect((s.questionsCreated, s.questionsLimit), (2, 6));
    expect(s.monthlyPurpleBonus, 500);
    expect(s.passportMode, isFalse);
    expect(s.hasAds, isFalse);
  });

  test('-1 sinirsiz demektir — kesif ve geri alma ayri ayri', () {
    final premium = DailyStats.fromJson({'dailyDiscoversLimit': -1, 'dailyUndosLimit': -1});
    final plus = DailyStats.fromJson({'dailyDiscoversLimit': -1, 'dailyUndosLimit': 3});

    expect(premium.isDiscoverUnlimited, isTrue);
    expect(premium.isUndoUnlimited, isTrue);
    expect(plus.isDiscoverUnlimited, isTrue);
    expect(plus.isUndoUnlimited, isFalse);
  });

  test('limit 0 sinirsiz SAYILMAZ — ucretsiz kullanicinin geri alma hakki yok', () {
    final free = DailyStats.fromJson({'dailyDiscoversLimit': 50, 'dailyUndosLimit': 0});

    expect(free.isDiscoverUnlimited, isFalse);
    expect(free.isUndoUnlimited, isFalse);
    expect(free.dailyUndosLimit, 0);
  });

  test('bos yanit ucretsiz plan varsayilanlarina duser — cokmez', () {
    final s = DailyStats.fromJson(const {});

    expect(s.dailyDiscoversLimit, 50);
    expect(s.dailyUndosLimit, 0);
    expect(s.questionsLimit, 4);
    expect(s.hasAds, isTrue);
    expect(s.passportMode, isFalse);
    expect(s.dailyDiscoversUsed, 0);
  });
}
