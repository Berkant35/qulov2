/// "Hepsini Geç" (SKIP_ALL) teklif kuralı — gerçek quiz ile güç demosunun ORTAK kuralı.
/// İki yerde ayrı yazılırsa kaçınılmaz olarak ayrışır; demo, gerçek ekranın gizlediği bir anı
/// öğretmemelidir.
///
/// Yalnız kalan soruları tek tek geçmekten UCUZ olduğunda teklif edilir. Çarpan ikisine de
/// uygulandığı için sadeleşir: Hepsini Geç ancak yeterince soru kaldığında kazandırır
/// (Doğru Say 10 / Hepsini Geç 30: 2 soruda pahalı, 3'te başabaş, 4'te ucuz).
/// Fiyat henüz yüklenmediyse (≤ 0) gizlenir — yanlış teklif göstermektense hiç gösterme.
bool skipAllOffered({
  required int skipCost,
  required int skipAllCost,
  required int remaining,
}) {
  if (skipCost <= 0 || skipAllCost <= 0) return false;
  return skipAllCost < remaining * skipCost;
}

/// Hepsini Geç'in teklif edilmeye başladığı EN KÜÇÜK kalan soru sayısı ([floor]..[ceiling]).
/// Hiçbiri uymuyorsa (ya da fiyat yoksa) [ceiling] — demo en fazla bu kadar soru kalacak
/// şekilde kurulur.
int minRemainingForSkipAll({
  required int skipCost,
  required int skipAllCost,
  int floor = 2,
  int ceiling = 4,
}) {
  for (var remaining = floor; remaining <= ceiling; remaining++) {
    if (skipAllOffered(
      skipCost: skipCost,
      skipAllCost: skipAllCost,
      remaining: remaining,
    )) {
      return remaining;
    }
  }
  return ceiling;
}
