/// Tam yil yas: dogum gunu bu yil henuz gelmediyse bir eksik; gelecek tarih → 0.
///
/// Sunucuyla ayni algoritma (qulo-server `user.service.ts` `completeProfile`):
/// yil farki, ay/gun karsilastirmasi. 29 Subat dogumlu kisi artik olmayan
/// yilda 1 Mart'ta bir yas buyur — iki taraf da boyle hesaplar.
int ageOn({required DateTime birthday, required DateTime today}) {
  if (birthday.isAfter(today)) return 0;
  var age = today.year - birthday.year;
  if (today.month < birthday.month ||
      (today.month == birthday.month && today.day < birthday.day)) {
    age--;
  }
  return age < 0 ? 0 : age;
}

/// Sunucunun yas kontrolunun kullandigi takvim gunu: UTC (Railway UTC calisir).
///
/// Profil tamamlamada sunucu 18 alti hesabi SILER. Istemci cihazin yerel
/// tarihine bakarsa, UTC'nin dogusundaki kullanici 18. dogum gununun ilk
/// saatlerinde (Turkiye'de 00:00–03:00) istemciden gecer ama sunucuda 17
/// hesaplanip silinir. Istemci ayni takvimle bakinca bu pencerede kullanici
/// "18 yasinda olmalisin" gorur, hesabini kaybetmez.
DateTime serverCalendarToday(DateTime now) {
  final utc = now.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

/// Sunucu `completeProfileSchema` bicimi: `YYYY-MM-DD` (sifir dolgulu).
String birthdayPayload(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
