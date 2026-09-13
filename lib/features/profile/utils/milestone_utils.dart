/// Profil tamamlanma yuzdesine gore bir sonraki odullu esik (economy config
/// `rewards.milestones` anahtarlari, orn. 25/50/75/100). Tum esikler gecildiyse
/// `null` — ilerleme cubugunda odul mesaji gosterilmez.
int? nextMilestoneFor(int completion, Iterable<int> milestones) {
  final sorted = milestones.toList()..sort();
  for (final m in sorted) {
    if (completion < m) return m;
  }
  return null;
}
