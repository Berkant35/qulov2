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
///
/// Guc demosu (`/power-demo`) da muaftir: market (`/profile/exchange`) ▶ kurulumu bitmemis
/// kullaniciya da acik; demo yalitilmis, hicbir sey harcamaz ve hicbir route'a gitmez.
///
/// Sehir secici (`/city-picker`) iki kapidan da muaftir: konum adiminin "sehir sec" yolu sosyal
/// giriste profil tamamlama SIRASINDA (yas henuz kayitli degil) acilir; yaprak ekrandir, secimle
/// geri doner. Muaf olmasaydi kullanici "Sehir sec"e basinca yine `/profile-completion`'a atilirdi.
String? setupGateRedirect({required String location, required UserModel? user}) {
  if (user == null) return null;
  if (location == cityPickerPath) return null;

  if (location == '/profile-completion') {
    return user.age != null ? '/discover' : null;
  }
  if (user.age == null) return '/profile-completion';

  if (location == '/profile-setup') {
    return user.setupComplete ? '/discover' : null;
  }
  if (!user.setupComplete && !_isSetupExempt(location)) {
    return '/profile-setup';
  }
  return null;
}

/// Sehir secici yolu (`RouteNames.cityPicker`).
const cityPickerPath = '/city-picker';

/// Oturum ACMAMIS kullanici sehir seciciye yalniz "secim" kipinde (`extra == true`) girebilir:
/// e-postali kayitta konum adimi hesap olusmadan once gelir. Bu kipte ekran aga yazmaz, secilen
/// sehri dondurur. Baska her durumda oturumsuz kullanici landing'e gider (router 5. adim).
bool isGuestCityPick({required String location, required Object? extra}) =>
    location == cityPickerPath && extra == true;

/// Tam eslesme: `/power-demo-x` gibi benzer yollar muaf degil.
const _powerDemoPath = '/power-demo';

bool _isSetupExempt(String location) =>
    location.startsWith('/profile') || location == _powerDemoPath;
