/// Demonun hangi anda olduğu. Makine yalnız uygun fazda eylem kabul eder; diğer fazlarda
/// gelen (çift dokunuş, efekt sürerken dokunuş) eylem yok sayılır.
enum PowerDemoPhase {
  /// "Gerçek quiz'in provası" + Başla.
  intro,

  /// Güç adımı: kullanıcı o güce dokunmadan ilerleyemez (cevap yok sayılır).
  awaitingPower,

  /// Güç kullanıldı (ya da güçsüz soru): şık seçilir, onaylanır.
  awaitingAnswer,

  /// Yanlış cevap: kurtarma kartı ("Doğru Say ile kurtar").
  rescue,

  /// Hepsini Geç çalışıyor: başlıktaki sayaç sona sayıyor.
  skippingAll,

  /// Demo bitti: kutlama + kapanış.
  finale,

  /// Kullanıcı demoyu atladı.
  skipped,
}

/// Demonun değişmez (immutable) durumu — [PowerDemoMachine] bir sonrakini üretir.
final class PowerDemoProgress {
  const PowerDemoProgress({
    required this.stepIndex,
    required this.phase,
    this.selectedIndex,
    this.removedIndices = const [],
    this.oracleIndex,
    this.hintVisible = false,
    this.extraSecondsToken = 0,
    this.skipToken = 0,
    this.wrongAnswers = 0,
    this.powerUsedAtStep,
  });

  /// Şu anki sorunun indeksi (0 tabanlı). [PowerDemoPhase.finale]'de son soru; atlandığında
  /// atlanılan adım korunur.
  final int stepIndex;
  final PowerDemoPhase phase;

  /// Seçilen (henüz onaylanmamış / yanlış çıkan) şık; yeni soruda temizlenir.
  final int? selectedIndex;

  /// Yarıla'nın elediği şıklar (yeni soruda temizlenir).
  final List<int> removedIndices;

  /// Kâhin'in önerdiği şık (yeni soruda temizlenir).
  final int? oracleIndex;

  /// İpucu kartı açık mı (yeni soruda kapanır).
  final bool hintVisible;

  /// Her TIME_EXTEND kullanımında +1: UI efekti bu jetonun değişimiyle tetikler.
  final int extraSecondsToken;

  /// Her SKIP kullanımında +1: UI "soru kenara kayar + ✓" efektini bununla tetikler.
  final int skipToken;

  /// Demo boyunca yanlış cevap sayısı (analitik `wrong_answers`).
  final int wrongAnswers;

  /// Bir gücün en son kullanıldığı adım; `null` = henüz hiç güç kullanılmadı.
  final int? powerUsedAtStep;

  /// `null` alanlar yalnız `clear*` bayraklarıyla temizlenir (`copyWith(selectedIndex: null)`
  /// "değiştirme" anlamına gelir).
  PowerDemoProgress copyWith({
    int? stepIndex,
    PowerDemoPhase? phase,
    int? selectedIndex,
    bool clearSelectedIndex = false,
    List<int>? removedIndices,
    int? oracleIndex,
    bool clearOracleIndex = false,
    bool? hintVisible,
    int? extraSecondsToken,
    int? skipToken,
    int? wrongAnswers,
    int? powerUsedAtStep,
    bool clearPowerUsedAtStep = false,
  }) => PowerDemoProgress(
    stepIndex: stepIndex ?? this.stepIndex,
    phase: phase ?? this.phase,
    selectedIndex: clearSelectedIndex
        ? null
        : selectedIndex ?? this.selectedIndex,
    removedIndices: removedIndices ?? this.removedIndices,
    oracleIndex: clearOracleIndex ? null : oracleIndex ?? this.oracleIndex,
    hintVisible: hintVisible ?? this.hintVisible,
    extraSecondsToken: extraSecondsToken ?? this.extraSecondsToken,
    skipToken: skipToken ?? this.skipToken,
    wrongAnswers: wrongAnswers ?? this.wrongAnswers,
    powerUsedAtStep: clearPowerUsedAtStep
        ? null
        : powerUsedAtStep ?? this.powerUsedAtStep,
  );

  @override
  bool operator ==(Object other) =>
      other is PowerDemoProgress &&
      other.stepIndex == stepIndex &&
      other.phase == phase &&
      other.selectedIndex == selectedIndex &&
      _sameIndices(other.removedIndices, removedIndices) &&
      other.oracleIndex == oracleIndex &&
      other.hintVisible == hintVisible &&
      other.extraSecondsToken == extraSecondsToken &&
      other.skipToken == skipToken &&
      other.wrongAnswers == wrongAnswers &&
      other.powerUsedAtStep == powerUsedAtStep;

  @override
  int get hashCode => Object.hash(
    stepIndex,
    phase,
    selectedIndex,
    Object.hashAll(removedIndices),
    oracleIndex,
    hintVisible,
    extraSecondsToken,
    skipToken,
    wrongAnswers,
    powerUsedAtStep,
  );

  static bool _sameIndices(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
