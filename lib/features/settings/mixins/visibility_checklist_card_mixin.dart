import 'package:qulo_v2/core/constants/app_constants.dart';

/// `VisibilityChecklistCard` için sunum-dışı logic.
///
/// Widget yalnızca UI orchestration yapar; dil dağılımını okunur bir satıra
/// çevirmek bir eşleme/biçimleme işi ve CLAUDE.md'nin "Widget Logic → Mixin"
/// kuralı gereği burada duruyor. Stateless widget olduğu için `on` kısıtı yok.
mixin VisibilityChecklistCardMixin {
  /// `{ 'tr': 3, 'en': 1 }` → `"🇹🇷 3 · 🇬🇧 1"`, çoktan aza sıralı.
  ///
  /// Bayrak kullanmak bilinçli: dil adlarını göstermek 16 dil × 16 arayüz dili
  /// çeviri gerektirirdi ve satır telefon kartına sığmazdı. Bayrak + sayı
  /// çevirisiz okunuyor.
  ///
  /// `null` döner ve satır hiç çizilmez şu iki durumda:
  /// - `locales == null` — sunucu bilgiyi vermedi (eski sürüm ya da sorgu
  ///   hatası). Uydurma bir "0 soru" göstermektense hiçbir şey gösterme.
  /// - `locales` boş — sorusu olmayan kullanıcı. Onun sorunu zaten kontrol
  ///   listesinde, dil satırı gürültü olurdu.
  String? questionLocaleSummary(Map<String, int>? locales) {
    if (locales == null || locales.isEmpty) return null;

    final entries = locales.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        // Eşit sayıda soru varsa dil koduna göre — sıra her açılışta aynı olsun.
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    return entries
        .map((e) {
          // Bilinmeyen bir kod gelirse (sunucu yeni bir dil eklediyse) kodun
          // kendisi gösterilir; boş bayrak yerine okunur bir şey kalsın.
          final flag = AppConstants.localeFlagEmojis[e.key] ?? e.key.toUpperCase();
          return '$flag ${e.value}';
        })
        .join(' · ');
  }
}
