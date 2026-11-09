/// Reklam açısından kullanıcı sınıfı.
///
/// [unknown] (abonelik yükleniyor / alınamadı) reklam göstermez: fail-closed.
/// Aksi halde ağ hatası alan bir Plus/Premium abonesi reklam görürdü.
enum AdAudience {
  /// Aktif Plus/Premium aboneliği var → ASLA reklam gösterilmez/yüklenmez.
  vip,

  /// Aboneliği olmadığı sunucudan doğrulanmış kullanıcı.
  free,

  /// Abonelik durumu bilinmiyor.
  unknown,
}
