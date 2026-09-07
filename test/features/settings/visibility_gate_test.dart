import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/settings/models/deletion_reason.dart';
import 'package:qulo_v2/features/settings/models/visibility_gate.dart';

/// Görünürlük kapıları — silme ekranında "eşleşme yok" diyen kullanıcıya
/// gösterilecek eksik listesi ve dil notu kuralı.
///
/// Bu testler üretim fonksiyonlarını **import edip çağırıyor**; kuralı burada
/// yeniden tanımlamıyor. Sunucu eşiği değişip `AppConstants` güncellenirse
/// testler onunla birlikte hareket eder.
void main() {
  /// Bütün kapıları geçen profil. Testler bunun tek bir alanını bozar, böylece
  /// her assertion'ın hangi kapıya baktığı belirsiz kalmaz.
  UserModel visibleUser({
    double? lat = 41.0,
    double? lng = 29.0,
    int questionCount = 2,
    List<String>? photos = const ['https://example.test/1.jpg'],
  }) {
    return UserModel(
      id: 'u1',
      email: 'a@b.test',
      emailVerified: true,
      lat: lat,
      lng: lng,
      questionCount: questionCount,
      photos: photos,
    );
  }

  group('missingVisibilityGates', () {
    test('bütün kapıları geçen profilde eksik yok', () {
      expect(missingVisibilityGates(visibleUser()), isEmpty);
    });

    test('enlem ya da boylamdan biri eksikse konum kapısı düşer', () {
      // Sunucu ikisini ayrı ayrı kontrol ediyor (`.not("lat"...).not("lng"...)`),
      // yani tek eksik koordinat da profili havuzdan çıkarır.
      expect(
        missingVisibilityGates(visibleUser(lat: null)),
        [VisibilityGate.noLocation],
      );
      expect(
        missingVisibilityGates(visibleUser(lng: null)),
        [VisibilityGate.noLocation],
      );
    });

    test('eşiğin altındaki soru sayısı kapı, eşik değeri değil', () {
      expect(
        missingVisibilityGates(
          visibleUser(questionCount: AppConstants.minQuestions - 1),
        ),
        [VisibilityGate.tooFewQuestions],
      );
      expect(
        missingVisibilityGates(
          visibleUser(questionCount: AppConstants.minQuestions),
        ),
        isEmpty,
      );
    });

    test('fotoğraf listesi hem null hem boşken kapı düşer', () {
      // İki ayrı "fotoğraf yok" hâli var ve ikisi de aynı sonucu vermeli.
      expect(
        missingVisibilityGates(visibleUser(photos: null)),
        [VisibilityGate.noPhoto],
      );
      expect(
        missingVisibilityGates(visibleUser(photos: const [])),
        [VisibilityGate.noPhoto],
      );
    });

    test('birden fazla eksik, sunucudaki sırayla döner', () {
      final gates = missingVisibilityGates(
        visibleUser(lat: null, lng: null, questionCount: 0, photos: null),
      );
      expect(gates, [
        VisibilityGate.noLocation,
        VisibilityGate.tooFewQuestions,
        VisibilityGate.noPhoto,
      ]);
    });

    test('doğrulanmamış e-posta kapı DEĞİL', () {
      // Sunucu aday sorgusunda `email_verified` ariyor ama giris yapmis
      // kullanicida bu alan hicbir zaman false olamaz: `login` dogrulanmamis
      // kullaniciyi reddediyor, sosyal giris `true` yaziyor, ve alani tekrar
      // false'a ceken yol yok. Kapi olarak eklenirse listede olu satir olur.
      expect(missingVisibilityGates(visibleUser()), isEmpty);
      expect(
        VisibilityGate.values.map((g) => g.labelKey),
        isNot(contains('visibility_gate_email')),
      );
    });

    test('her kapının l10n anahtarı benzersiz ve dolu', () {
      final keys = VisibilityGate.values.map((g) => g.labelKey).toList();
      expect(keys.toSet().length, keys.length);
      expect(keys.every((k) => k.isNotEmpty), isTrue);
    });
  });

  group('gatesForDeletionReason', () {
    test('yalnızca görünürlükle ilgili sebeplerde kapı döner', () {
      final user = visibleUser(photos: null);
      for (final reason in kVisibilityRelevantReasons) {
        expect(
          gatesForDeletionReason(reason, user),
          [VisibilityGate.noPhoto],
          reason: '$reason görünürlükle ilgili sayılmalı',
        );
      }
    });

    test('ilgisiz sebeplerde boş döner — eksiği olsa bile', () {
      final user = visibleUser(photos: null, questionCount: 0);
      final unrelated = DeletionReason.values
          .where((r) => !kVisibilityRelevantReasons.contains(r));
      expect(unrelated, isNotEmpty);
      for (final reason in unrelated) {
        expect(
          gatesForDeletionReason(reason, user),
          isEmpty,
          reason: '$reason görünürlük sorunu değil, liste gösterilmemeli',
        );
      }
    });

    test('sebep seçilmemişse ya da kullanıcı yoksa boş döner', () {
      expect(gatesForDeletionReason(null, visibleUser(photos: null)), isEmpty);
      expect(gatesForDeletionReason(DeletionReason.fewMatches, null), isEmpty);
    });
  });

  group('shouldShowLanguageNote', () {
    test('profil görünürken gösterilir', () {
      expect(
        shouldShowLanguageNote(DeletionReason.fewMatches, visibleUser()),
        isTrue,
      );
    });

    test('eksik kapı varken gösterilmez — sorunu zaten listede', () {
      expect(
        shouldShowLanguageNote(
          DeletionReason.fewMatches,
          visibleUser(photos: null),
        ),
        isFalse,
      );
    });

    test('ilgisiz sebepte gösterilmez', () {
      expect(
        shouldShowLanguageNote(DeletionReason.tooExpensive, visibleUser()),
        isFalse,
      );
    });

    test('kullanıcı yoksa gösterilmez', () {
      expect(shouldShowLanguageNote(DeletionReason.fewMatches, null), isFalse);
    });

    test('kapı listesi ile birbirini dışlar', () {
      // Kart iki hâlden birini gosterir; ikisi ayni anda dogru olamaz.
      for (final user in [visibleUser(), visibleUser(photos: null)]) {
        const reason = DeletionReason.fewMatches;
        final hasGates = gatesForDeletionReason(reason, user).isNotEmpty;
        final hasNote = shouldShowLanguageNote(reason, user);
        expect(hasGates && hasNote, isFalse);
        expect(hasGates || hasNote, isTrue);
      }
    });
  });
}
