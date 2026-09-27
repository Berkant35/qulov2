/// Play Install Referrer dizesinden davet kodunu cikarir.
///
/// Zincirin baslangici web'de: `web/src/lib/constants/links.ts` davet
/// sayfasinin Play linkine `referrer=utm_source=...&utm_campaign=referral&
/// utm_content=KOD` koyuyor. Play bu dizeyi kuruluma bagli olarak saklar ve
/// Install Referrer API ile geri veriyor — yani kod, arkadas uygulamayi
/// kurdugunda cihazda hazir duruyor. Uygulama 2026-09-27'ye kadar onu hic
/// okumuyordu; davet kodunu elle yazmak gerekiyordu ve `referrals` tablosu
/// bostu.
///
/// Dogrulama sunucunun kuralini birebir yansitir
/// (`qulo-server/src/validators/referral.validator.ts`): 1-10 karakter,
/// `[A-Za-z0-9-]`, buyuk harfe cevrilir. Uymayan deger `null` doner ve hic
/// gonderilmez — cop veri sunucuya gitmez.
library;

/// Yalniz bu kampanyanin `utm_content`'i davet kodu sayilir.
///
/// `storeLinks()` baska kampanyalar icin de link uretiyor (`web-questions`,
/// `web-quiz-create`); bugun onlar `utm_content` koymuyor ama yarin bir pazarlama
/// kampanyasi `utm_content=summer2026` koyarsa o deger davet kodu olarak
/// gonderilmemeli.
const String _referralCampaign = 'referral';

final RegExp _codePattern = RegExp(r'^[A-Z0-9-]{1,10}$');

/// Referrer dizesinden davet kodu; yoksa ya da gecersizse `null`.
String? referralCodeFromInstallReferrer(String? referrer) {
  if (referrer == null || referrer.isEmpty) return null;

  final params = Uri.splitQueryString(referrer);
  if (params['utm_campaign'] != _referralCampaign) return null;

  final raw = params['utm_content']?.trim().toUpperCase();
  if (raw == null || raw.isEmpty) return null;
  return _codePattern.hasMatch(raw) ? raw : null;
}

/// Basarisiz `applyCode` sonrasi bekleyen kod silinsin mi?
///
/// Ag hatasinda silinmez — kullanici cevrimici olunca tekrar denenir. Kalici
/// redlerde silinir, yoksa her acilista bosuna istek atilir.
bool shouldDropPendingReferral(String errorCode) {
  return const {
    'SELF_REFERRAL',
    'ALREADY_REFERRED',
    'INVALID_REFERRAL_CODE',
    'VALIDATION_ERROR',
  }.contains(errorCode);
}

/// Referrer okumasinin sonucu: ne isaretlenecek, ne saklanacak.
class InstallReferrerCapture {
  const InstallReferrerCapture({required this.markRead, required this.code});

  /// "Referrer okundu" bayragi yazilsin mi.
  final bool markRead;

  /// Saklanacak davet kodu; yoksa `null`.
  final String? code;
}

/// Yakalama karari — `app.dart`'taki dallanmayi buraya tasir.
///
/// [wasRead] daha once basariyla okunduysa hicbir sey yapilmaz: Play ayni
/// referrer'i her acilista donuyor, tekrar okumak kullanicinin uyguladiktan
/// sonra silinen kodunu geri getirirdi.
///
/// [raw] `null` ise (iOS, Play Services yok, gecici hata) bayrak YAZILMAZ.
/// Once "okumaya basladim" anlaminda yaziliyordu ve gecici bir hatada gercek
/// bir davet kurulumunun odulu kalici olarak kayboluyordu. Organik kurulumda
/// Play bos olmayan bir referrer donduruyor, yani bu sonsuz yeniden deneme
/// degil.
InstallReferrerCapture captureInstallReferrer({
  required bool wasRead,
  required String? raw,
}) {
  if (wasRead) return const InstallReferrerCapture(markRead: false, code: null);
  if (raw == null) {
    return const InstallReferrerCapture(markRead: false, code: null);
  }
  return InstallReferrerCapture(
    markRead: true,
    code: referralCodeFromInstallReferrer(raw),
  );
}
