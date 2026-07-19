/// Profil düzenleme input'larının maksimum karakter limitleri.
///
/// Tek yerden değiştirilebilir — değerler [DetailChips] tasarımının bozulmayacağı
/// (chip taşmayacak) şekilde ayarlanmıştır. Yeni bir profil input'u eklenirken
/// limiti buraya ekle, widget'ta hardcode etme.
abstract final class ProfileFieldLimits {
  // Serbest metin (DetailChips'e dönüşen) — chip taşmasın diye kısa tutulur.
  static const int city = 40;
  static const int job = 40;
  static const int school = 40;
  static const int pets = 30;
  static const int music = 40;
  static const int personality = 60;

  // Uzun metin.
  static const int bio = 300;
  static const int name = 50;

  // Sayısal (rakam) alanlar.
  static const int height = 3;
  static const int weight = 3;

  /// "Son X karakter kaldı" uyarısının görüneceği kalan-karakter eşiği.
  /// Kalan karakter bu değerin altına inince uyarı gösterilir.
  static const int remainingWarningThreshold = 5;
}
