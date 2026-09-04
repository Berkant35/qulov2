/// Quiz ekranina gecerken karsi kisinin kimligi. Discover karti ve profil detayi
/// bu bilgiyi zaten tutuyor; sunucuya ayrica sorulmaz. Route `extra` ile tasinir.
class QuizTargetArgs {
  final String? name;
  final String? photoUrl;
  final double? distanceKm;

  const QuizTargetArgs({this.name, this.photoUrl, this.distanceKm});
}
