/// Mesafe etiketi: 1 km alti "yakinda" cevirisi, ustu tek ondalikla km.
/// Discover karti, profil detayi ve quiz basligi ayni kaynagi kullanir.
String distanceLabel(double km, {required String nearbyLabel}) =>
    km < 1.0 ? nearbyLabel : '${km.toStringAsFixed(1)} km';

/// "Sehir • 3.2 km" satiri. Sehir yokken mesafe, mesafe yokken sehir tek basina;
/// ikisi de yoksa null (satir hic cizilmez). `distanceKm` null = bilinmiyor.
String? locationLine({
  required String? city,
  required double? distanceKm,
  required String nearbyLabel,
}) {
  final parts = [
    if (city != null && city.isNotEmpty) city,
    if (distanceKm != null) distanceLabel(distanceKm, nearbyLabel: nearbyLabel),
  ];
  return parts.isEmpty ? null : parts.join(' • ');
}
