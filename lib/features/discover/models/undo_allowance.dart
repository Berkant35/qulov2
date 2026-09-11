/// Discover geri alma butonunun hak durumu (ucretli: Plus gunde 3, Premium sinirsiz).
class UndoAllowance {
  const UndoAllowance({
    required this.hasRight,
    required this.isUnlimited,
    required this.remaining,
  });

  /// Planda geri alma hakki var mi — yoksa buton kilitli, dokunus paywall acar.
  final bool hasRight;
  final bool isUnlimited;

  /// Bugun kalan hak; sinirsizda -1.
  final int remaining;
}
