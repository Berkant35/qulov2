/// Elmas paketleri — magazadaki tuketilebilir urun katalogu.
///
/// Widget dosyasindan buraya tasindi: fiyat saglayicisi da bu listeye ihtiyac
/// duyuyor ve bir provider'in widget dosyasi import etmesi katman ihlali olurdu.
enum DiamondTier {
  starter(amount: 50, diamondCount: 1, productId: 'qulopurple50'),
  popular(amount: 150, diamondCount: 2, productId: 'qulopurple150'),
  bestValue(amount: 400, diamondCount: 3, productId: 'qulopurple400'),
  mega(amount: 1000, diamondCount: 4, productId: 'qulopurple1000'),
  ultra(amount: 2500, diamondCount: 5, productId: 'qulopurple2500'),
  vip(amount: 6000, diamondCount: 6, productId: 'qulopurple6000');

  final int amount;
  final int diamondCount;
  final String productId;

  const DiamondTier({
    required this.amount,
    required this.diamondCount,
    required this.productId,
  });
}

class PurchasePackage {
  final DiamondTier tier;

  const PurchasePackage({required this.tier});

  int get amount => tier.amount;
}
