import 'package:qulo_v2/data/models/referral_model.dart';

/// Bos Discover'daki davet girisinin sunum-disi logic'i.
///
/// Widget'tan ayri durmasinin sebebi test: uc karar da sessizce yanlis
/// olabilir ve ucu de kullaniciya yalan soyler ya da ozelligi olu birakir.
mixin DiscoverInviteHintMixin {
  /// Paylasilabilir kod — yoksa `null`, ve giris hic cizilmez.
  ///
  /// `bool` yerine kodun kendisini dondurmesi bilincli: cagri yerinde `code!`
  /// gerekmiyor, yani "kod var" garantisi ile onu kullanan satir tipce bagli.
  /// Kosul bir gun gevsetilirse derleyici uyarir, `build()` runtime'da patlamaz.
  ///
  /// Kota dolduysa (`remaining <= 0`) giris gizlenir: sunucu 11. daveti
  /// odullendirmiyor (`maxCompletedReferrals = 10`), dolayisiyla "ikinize de
  /// @reward mor elmas" demek yalan olur.
  ///
  /// `stats` henuz yuklenmemisse gosterilir: kod geldiyse davet hakki
  /// neredeyse kesin vardir, kotayi sunucu da ayrica uyguluyor ve girisi
  /// gizlemek yuklenme sirasinda ekrani sebepsiz bosaltir.
  String? shareableInviteCode({
    required String? code,
    required ReferralStats? stats,
  }) {
    if (code == null || code.isEmpty) return null;
    final remaining = stats?.remaining;
    if (remaining != null && remaining <= 0) return null;
    return code;
  }

  /// Etiketteki `@reward` yer tutucusunu doldurur.
  ///
  /// `context.tr` args almadigi icin degisim cagri yerinde yapiliyordu;
  /// formatlama widget'in isi degil ve burada test edilebiliyor.
  String inviteLabel({required String template, required int reward}) {
    return template.replaceAll('@reward', '$reward');
  }
}
