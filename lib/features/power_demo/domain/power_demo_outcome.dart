/// Kullanıcının demoyla ilişkisinin kalıcı sonucu: baştan sona yaptı / yarıda bıraktı /
/// hiç görmedi. Yalnız onboarding sonucu saklanır (kayıt sonrası raporlama için).
sealed class PowerDemoOutcome {
  const PowerDemoOutcome();

  /// Depolama kodu: `'completed'`, `'skipped:<adım>'`; hiç görülmediyse `null`.
  String? encode();

  static final RegExp _skipped = RegExp(r'^skipped:(\d+)$');

  /// [encode]'un tersi. Boş, bilinmeyen ya da bozuk değer → [PowerDemoNotSeen]
  /// (bozuk depolama demoyu çökertmez; kullanıcı demoyu görmemiş sayılır).
  static PowerDemoOutcome decode(String? raw) {
    if (raw == 'completed') return const PowerDemoCompleted();
    final fromStep = int.tryParse(
      _skipped.firstMatch(raw ?? '')?.group(1) ?? '',
    );
    if (fromStep != null) return PowerDemoSkipped(fromStep);
    return const PowerDemoNotSeen();
  }
}

/// Demo baştan sona bitirildi.
final class PowerDemoCompleted extends PowerDemoOutcome {
  const PowerDemoCompleted();

  @override
  String? encode() => 'completed';

  @override
  bool operator ==(Object other) => other is PowerDemoCompleted;

  @override
  int get hashCode => (PowerDemoCompleted).hashCode;
}

/// Demo [fromStep]. adımda atlandı (ya da sayfadan kaydırarak çıkıldı).
final class PowerDemoSkipped extends PowerDemoOutcome {
  const PowerDemoSkipped(this.fromStep);

  final int fromStep;

  @override
  String? encode() => 'skipped:$fromStep';

  @override
  bool operator ==(Object other) =>
      other is PowerDemoSkipped && other.fromStep == fromStep;

  @override
  int get hashCode => Object.hash(PowerDemoSkipped, fromStep);
}

/// Demo hiç görülmedi (ya da kayıt okunamadı).
final class PowerDemoNotSeen extends PowerDemoOutcome {
  const PowerDemoNotSeen();

  @override
  String? encode() => null;

  @override
  bool operator ==(Object other) => other is PowerDemoNotSeen;

  @override
  int get hashCode => (PowerDemoNotSeen).hashCode;
}
