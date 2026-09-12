import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/utils/age_utils.dart';

/// Yas siniri — yasal gereklilik ve sunucu 18 alti hesabi SILER
/// (`user.service.ts` `completeProfile` → `UNDERAGE_USER`). Istemci ile sunucu
/// ayni sonucu vermezse kullanici ya haksiz reddedilir ya da hesabini kaybeder.
void main() {
  final birthday = DateTime(2008, 9, 12);

  group('ageOn — sunucuyla ayni algoritma', () {
    test('18. dogum gunu → 18', () {
      expect(ageOn(birthday: birthday, today: DateTime(2026, 9, 12)), 18);
    });

    test('dogum gunune bir gun kala → 17', () {
      expect(ageOn(birthday: birthday, today: DateTime(2026, 9, 11)), 17);
    });

    test('ay henuz gelmediyse bir eksik', () {
      expect(ageOn(birthday: birthday, today: DateTime(2026, 8, 30)), 17);
    });

    test('gelecek tarih → 0', () {
      expect(ageOn(birthday: DateTime(2030, 1, 1), today: DateTime(2026, 9, 12)), 0);
    });

    test('29 Subat dogumlu artik olmayan yilda 28 Subat\'ta henuz buyumez, 1 Mart\'ta buyur', () {
      final leap = DateTime(2008, 2, 29);

      expect(ageOn(birthday: leap, today: DateTime(2026, 2, 28)), 17);
      expect(ageOn(birthday: leap, today: DateTime(2026, 3, 1)), 18);
    });
  });

  group('serverCalendarToday — sunucunun takvimi (UTC)', () {
    test('ayni an, cihaz hangi saat diliminde olursa olsun UTC gunune cevrilir', () {
      // 12 Eylul 01:00 Turkiye = 11 Eylul 22:00 UTC. `toLocal` ile makinenin
      // saat diliminden bagimsiz ayni ani kuruyoruz.
      final deviceNow = DateTime.utc(2026, 9, 11, 22).toLocal();

      expect(serverCalendarToday(deviceNow), DateTime.utc(2026, 9, 11));
    });

    test('dogu yarimkurede 18. dogum gununun ilk saatlerinde istemci de 17 der — silinmez', () {
      // Eskiden cihaz yerel gunu (12 Eylul) kullaniliyordu → 18 → sunucuya
      // gidiyor, sunucu UTC ile 17 hesaplayip hesabi siliyordu.
      final deviceNow = DateTime.utc(2026, 9, 11, 22).toLocal();

      expect(ageOn(birthday: birthday, today: serverCalendarToday(deviceNow)), 17);
    });

    test('UTC gunu da geldiyse 18', () {
      final deviceNow = DateTime.utc(2026, 9, 12, 0, 30).toLocal();

      expect(ageOn(birthday: birthday, today: serverCalendarToday(deviceNow)), 18);
    });
  });

  group('birthdayPayload — sunucu completeProfileSchema /^\\d{4}-\\d{2}-\\d{2}\$/', () {
    test('tek haneli ay ve gun sifirla doldurulur', () {
      expect(birthdayPayload(DateTime(2008, 3, 5)), '2008-03-05');
    });

    test('cift haneli degerler oldugu gibi', () {
      expect(birthdayPayload(DateTime(1999, 12, 31)), '1999-12-31');
    });

    test('her cikti sunucu regex\'ine uyar', () {
      final serverPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      for (final d in [DateTime(2008, 1, 1), DateTime(2008, 10, 9), DateTime(1970, 7, 30)]) {
        expect(serverPattern.hasMatch(birthdayPayload(d)), isTrue, reason: '$d');
      }
    });
  });

  test('yas siniri sunucuyla ayni (auth.validator age min 18)', () {
    expect(AppConstants.minUserAge, 18);
  });
}
