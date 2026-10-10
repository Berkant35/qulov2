/// Hediye kartı markaları — sunucu `REWARD_BRANDS` (qulo-server `rewards.validator.ts`) ile aynı liste.
/// Marka adları özel isimdir, çevrilmez; yalnız OTHER yerelleştirilir (`reward_brand_other`).
const rewardBrandKeys = <String>[
  'GRAB', 'GOPAY', 'DANA', 'OVO', 'SHOPEEPAY', 'TRUEMONEY', 'LINEMAN', 'TNG', 'FOODPANDA', 'OTHER',
];

const _brandNames = <String, String>{
  'GRAB': 'Grab',
  'GOPAY': 'GoPay',
  'DANA': 'DANA',
  'OVO': 'OVO',
  'SHOPEEPAY': 'ShopeePay',
  'TRUEMONEY': 'TrueMoney',
  'LINEMAN': 'LINE MAN',
  'TNG': "Touch 'n Go",
  'FOODPANDA': 'foodpanda',
};

/// Marka adı; OTHER ya da bilinmeyen anahtar için null (çağıran `reward_brand_other` gösterir).
String? rewardBrandName(String brandKey) => _brandNames[brandKey];

/// "Nasıl kullanılır" metninin çeviri anahtarı; bilinmeyen marka OTHER metnine düşer.
String rewardHowtoKey(String brandKey) => rewardBrandKeys.contains(brandKey)
    ? 'reward_howto_${brandKey.toLowerCase()}'
    : 'reward_howto_other';
