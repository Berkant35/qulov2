import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';

/// EditProfileNotifier.build() userProvider'i okur ama kullanici yoksa (test
/// ortaminda default) varsayilan state doner — bu yuzden dil testleri icin
/// ekstra override gerekmiyor, setLanguages ile taze durum kuruyoruz.
void main() {
  group('EditProfileNotifier dil secimi', () {
    test('selectAllLanguages tum 16 dili sirayla secer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editProfileProvider.notifier);

      notifier.selectAllLanguages();

      expect(
        container.read(editProfileProvider).selectedLanguages,
        AppConstants.supportedQuestionLocales,
      );
    });

    test('resetLanguages tek dile sifirlar', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editProfileProvider.notifier);
      notifier.selectAllLanguages();

      notifier.resetLanguages('de');

      expect(container.read(editProfileProvider).selectedLanguages, ['de']);
    });

    test('tek dil kalinca toggleLanguage o dili kaldirmaz (en az 1 dil kurali)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editProfileProvider.notifier);
      notifier.setLanguages(['tr']);

      notifier.toggleLanguage('tr');

      expect(container.read(editProfileProvider).selectedLanguages, ['tr']);
    });

    test('allLanguagesSelected sadece tum diller seciliyken true doner', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editProfileProvider.notifier);
      notifier.setLanguages(['tr']);

      expect(container.read(editProfileProvider).allLanguagesSelected, isFalse);

      notifier.selectAllLanguages();

      expect(container.read(editProfileProvider).allLanguagesSelected, isTrue);
    });
  });
}
