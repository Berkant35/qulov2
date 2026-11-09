import 'package:qulo_v2/data/models/user_model.dart';

/// Desteyi belirleyen (adayı sunucuda ELEYEN) kullanıcı tercihleri. Record
/// eşitliği yapısal olduğu için `select` yalnız gerçek değişimde bildirir.
///
/// Ayna: qulo-server `matching.service.ts` discover() kullanıcı filtreleri.
/// Kendi cinsiyet anahtarda yok — istemcide kilitli (destek talebiyle değişir).
/// Yarıçap yok — sunucuda sert mesafe filtresi yok, yalnız sıralamayı etkiler
/// ve "tekrar ara" akışı desteyi zaten kendisi çeker.
typedef DiscoverFilterKey = ({String genderPref, String languages, int? ageMin, int? ageMax});

/// [user] için filtre anahtarı; kullanıcı yoksa null.
DiscoverFilterKey? discoverFilterKey(UserModel? user) {
  if (user == null) return null;
  return (
    genderPref: user.hasGenderPref ? 'set:${user.genderPref}' : 'unset',
    // Sıra filtreyi değiştirmez; yalnız küme farkı yeniden yükletir.
    languages: ([...user.preferredLanguages]..sort()).join(','),
    ageMin: user.agePrefMin,
    ageMax: user.agePrefMax,
  );
}
