/// Yarıla'nın eleyeceği şıklar: doğru şık ve [keepIndex] (Kâhin'in önerdiği şık) HARİÇ,
/// artan sırada ilk 2 indeks. Gerçek quiz'deki kural aynıdır: Yarıla, Kâhin'in önerdiğini
/// asla elemez. Elenecek 2 şık yoksa elde olan kadarı döner. Dönen liste değiştirilemez.
List<int> halfRemovedIndices({
  required int optionCount,
  required int correctIndex,
  int? keepIndex,
}) {
  final candidates = [
    for (var i = 0; i < optionCount; i++)
      if (i != correctIndex && i != keepIndex) i,
  ];
  return List.unmodifiable(candidates.take(2));
}
