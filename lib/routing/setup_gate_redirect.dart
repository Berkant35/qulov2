import 'package:qulo_v2/data/models/user_model.dart';

/// Oturum acmis kullanici icin profil tamamlama + kurulum kapisi
/// (`app_router.dart` redirect'inin 6-8. adimlari).
///
/// Doner: gidilecek yol; `null` = bu kapi karar vermiyor, router sonraki
/// kurala gecer. Profil henuz yuklenmediyse (`user == null`) kapi kimseyi
/// yonlendirmez — yanlis ekrana atmaktansa bir sonraki refresh'i bekler.
///
/// Sira onemli: once yas (sosyal giris profili tamamlanmamis), sonra kurulum
/// (foto + soru, `UserModel.setupComplete`). Kurulumu bitmemis kullanici
/// `/profile` altindaki her yere gidebilir — kurulum ekraninin kendi akislari
/// (`/profile/questions`, `/profile/questions/create`, `/profile/edit`) orada.
/// Onek eslesmesi `/profile-detail/...` ve `/profile/preview`'i de kapsar:
/// profil gorulebilir, quiz (`/quiz/...`) yine kapida durur.
String? setupGateRedirect({required String location, required UserModel? user}) {
  if (user == null) return null;

  if (location == '/profile-completion') {
    return user.age != null ? '/discover' : null;
  }
  if (user.age == null) return '/profile-completion';

  if (location == '/profile-setup') {
    return user.setupComplete ? '/discover' : null;
  }
  if (!user.setupComplete && !location.startsWith('/profile')) {
    return '/profile-setup';
  }
  return null;
}
