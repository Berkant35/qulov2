/// Qulo'nun üç elmas türü. Rainbow yalnız gerçek parayla alınmış mor harcandığında karşı
/// tarafta doğar ve hediye kartına çevrilebilen tek elmastır (spec 2026-09-27). Görünürlüğü
/// sunucu belirler (`UserModel.rainbowEnabled`); istemci kendi karar vermez.
enum DiamondType { purple, green, rainbow }

extension DiamondTypeApi on DiamondType {
  /// Sunucu `diamond_type` değeri (qulo-server exchange.validator: GREEN | PURPLE | RAINBOW).
  String get apiName => switch (this) {
        DiamondType.purple => 'PURPLE',
        DiamondType.green => 'GREEN',
        DiamondType.rainbow => 'RAINBOW',
      };
}

/// Sunucu `diamond_transactions.type` / `diamond_type` dizesi → enum. Bilinmeyen değer
/// `purple`'a düşer (eski `diamondTypeKey` davranışı).
DiamondType diamondTypeFromApi(String type) => switch (type.toUpperCase()) {
      'GREEN' => DiamondType.green,
      'RAINBOW' => DiamondType.rainbow,
      _ => DiamondType.purple,
    };
