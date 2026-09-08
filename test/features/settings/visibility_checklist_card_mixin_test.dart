import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/features/settings/mixins/visibility_checklist_card_mixin.dart';

/// Dil dağılımı satırı: `{ 'tr': 3, 'en': 1 }` → `"🇹🇷 3 · 🇬🇧 1"`.
///
/// Bayrakları test içinde yeniden yazmıyoruz — `AppConstants.localeFlagEmojis`
/// üzerinden okunuyor, yani sabit değişirse test onunla birlikte hareket eder.
class _Subject with VisibilityChecklistCardMixin {}

void main() {
  final subject = _Subject();
  String flag(String locale) => AppConstants.localeFlagEmojis[locale]!;

  group('questionLocaleSummary', () {
    test('null ise satır çizilmez — sunucu bilgiyi vermedi', () {
      // Uydurma bir "0 soru" göstermektense hiçbir şey gösterme.
      expect(subject.questionLocaleSummary(null), isNull);
    });

    test('boş harita da satır çizdirmez — sorusu olmayanın derdi listede', () {
      expect(subject.questionLocaleSummary(const {}), isNull);
    });

    test('tek dil: bayrak ve sayı', () {
      expect(
        subject.questionLocaleSummary(const {'tr': 3}),
        '${flag('tr')} 3',
      );
    });

    test('çoktan aza sıralar', () {
      expect(
        subject.questionLocaleSummary(const {'en': 1, 'tr': 3, 'de': 2}),
        '${flag('tr')} 3 · ${flag('de')} 2 · ${flag('en')} 1',
      );
    });

    test('eşit sayıda soruda sıra dil koduna göre — her açılışta aynı', () {
      // Map sırası kaynağa göre değişebilir; kullanıcı her açtığında farklı
      // sıra görmemeli.
      final a = subject.questionLocaleSummary(const {'tr': 2, 'en': 2});
      final b = subject.questionLocaleSummary(const {'en': 2, 'tr': 2});
      expect(a, b);
      expect(a, '${flag('en')} 2 · ${flag('tr')} 2');
    });

    test('bilinmeyen dil kodu bayrak yerine kodun kendisini gösterir', () {
      // Sunucu yeni bir dil eklerse boş bayrak yerine okunur bir şey kalsın.
      expect(
        subject.questionLocaleSummary(const {'xx': 2}),
        'XX 2',
      );
    });

    test('desteklenen 16 dilin hepsinde bayrak var — kod fallback\'e düşmez', () {
      for (final locale in AppConstants.supportedQuestionLocales) {
        final summary = subject.questionLocaleSummary({locale: 1});
        expect(
          summary,
          '${flag(locale)} 1',
          reason: '$locale için bayrak eksik, kod fallback\'ine düşüyor',
        );
      }
    });
  });
}
