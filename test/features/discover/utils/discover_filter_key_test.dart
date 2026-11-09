import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/discover/utils/discover_filter_key.dart';

/// Desteyi yeniden yükleten anahtar: yalnız sunucuda adayı ELEYEN tercihler
/// değişince farklılaşmalı (DiscoverNotifier bu anahtarı dinler).
void main() {
  UserModel user({
    String? genderPref = 'WOMAN',
    String? consent,
    List<String> languages = const ['tr', 'en'],
    int? ageMin = 25,
    int? ageMax = 35,
    int radiusKm = 50,
    String? bio,
  }) =>
      UserModel(
        id: 'u1',
        email: 'u1@qulo.test',
        genderPref: genderPref,
        genderPrefSetAt: genderPref == null ? null : DateTime(2026, 10, 3),
        prefConsentStatus: consent,
        preferredLanguages: languages,
        agePrefMin: ageMin,
        agePrefMax: ageMax,
        matchRadiusKm: radiusKm,
        bio: bio,
      );

  test('kullanıcı yoksa anahtar yok', () {
    expect(discoverFilterKey(null), isNull);
  });

  test('aynı tercihler eşit anahtar verir (yeni liste örneği olsa da)', () {
    expect(discoverFilterKey(user()), discoverFilterKey(user(languages: ['tr', 'en'])));
  });

  test('dil sırası anahtarı değiştirmez', () {
    expect(discoverFilterKey(user(languages: ['en', 'tr'])), discoverFilterKey(user()));
  });

  test('dil kümesi, yaş aralığı ve cinsiyet tercihi anahtarı değiştirir', () {
    final base = discoverFilterKey(user());
    expect(discoverFilterKey(user(languages: ['tr'])), isNot(base));
    expect(discoverFilterKey(user(ageMin: 18)), isNot(base));
    expect(discoverFilterKey(user(ageMax: 50)), isNot(base));
    expect(discoverFilterKey(user(genderPref: 'MAN')), isNot(base));
  });

  test('tercihsiz ile rızayı reddeden ("Herkes") farklı anahtardır', () {
    expect(
      discoverFilterKey(user(genderPref: null)),
      isNot(discoverFilterKey(user(genderPref: null, consent: PrefConsent.declined))),
    );
  });

  test('yarıçap ve eleme dışı alanlar anahtarı değiştirmez', () {
    expect(discoverFilterKey(user(radiusKm: 120, bio: 'yeni bio')), discoverFilterKey(user()));
  });
}
