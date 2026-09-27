/// Davet metnini kuran tek yer.
///
/// `referral_share_message` iki yer tutucu tasir: `@reward` (odul miktari) ve
/// `@code` (kullanicinin davet kodu — biri metinde, biri `quloapp.com/invite/`
/// adresinin icinde). Kodu yerine koymayi atlayan bir sablon, ise yaramaz bir
/// paylasim uretir: arkadas linke tiklar, acilan sayfa "bu kodu gir" der ve
/// girecek kod yoktur.
///
/// Bu yuzden metin, cagri yerinde `replaceAll` zincirleriyle degil burada
/// kurulur; `referral_share_test.dart` hem donusumu hem 18 dilin sablonunu
/// dogrular.
String buildReferralShareMessage({
  required String template,
  required int reward,
  required String code,
}) {
  return template.replaceAll('@reward', '$reward').replaceAll('@code', code);
}
