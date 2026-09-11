import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/data/models/user_model.dart';

/// Kurulum kapisinin uc parcasi tek kaynaktan: router `setupComplete`'e,
/// kurulum ekraninin kartlari ve "Bitir" butonu ayni getter'lara bakar.
///
/// Eskiden ekran esigi kendi hesapliyordu (`questionCount >= 2`, sabit 2);
/// `AppConstants.minQuestions` degisseydi ekran "Bitir" gosterir, kapi
/// kullaniciyi geri `/profile-setup`'a atardi. Bugun iki esik esitti —
/// saha semptomu yok, gerekce sozlesme dogrulugu.
UserModel _u({int? photos = 1, int questions = 2, bool pref = true}) => UserModel(
      id: 'u1',
      email: 'u1@qulo.test',
      age: 27,
      photos: photos == null ? null : List.generate(photos, (i) => 'https://cdn.example/p$i.jpg'),
      questionCount: questions,
      genderPrefSetAt: pref ? DateTime.utc(2026, 9, 1) : null,
    );

void main() {
  group('hasSetupPhoto', () {
    test('foto listesi yok ya da bos → false', () {
      expect(_u(photos: null).hasSetupPhoto, isFalse);
      expect(_u(photos: 0).hasSetupPhoto, isFalse);
    });

    test('esik kadar foto → true', () {
      expect(_u(photos: AppConstants.minPhotos).hasSetupPhoto, isTrue);
    });
  });

  group('hasSetupQuestions', () {
    test('esigin bir alti → false, esik → true', () {
      expect(_u(questions: AppConstants.minQuestions - 1).hasSetupQuestions, isFalse);
      expect(_u(questions: AppConstants.minQuestions).hasSetupQuestions, isTrue);
    });

    test('bugunku esik: 1 soru yetmez, 2 soru yeter', () {
      expect(_u(questions: 1).hasSetupQuestions, isFalse);
      expect(_u(questions: 2).hasSetupQuestions, isTrue);
    });
  });

  group('hasGenderPref', () {
    test('tercih zamani yoksa false, varsa true', () {
      expect(_u(pref: false).hasGenderPref, isFalse);
      expect(_u(pref: true).hasGenderPref, isTrue);
    });
  });

  group('setupComplete — uc kapinin tamami', () {
    // (foto, soru, tercih) → beklenen; tablo acik yazildi, formul tekrarlanmadi.
    const table = [
      (0, 0, false, false),
      (1, 0, false, false),
      (0, 2, false, false),
      (0, 0, true, false),
      (1, 2, false, false),
      (1, 0, true, false),
      (0, 2, true, false),
      (1, 2, true, true),
    ];

    for (final (photos, questions, pref, expected) in table) {
      test('foto=$photos soru=$questions tercih=$pref → $expected', () {
        expect(_u(photos: photos, questions: questions, pref: pref).setupComplete, expected);
      });
    }
  });
}
