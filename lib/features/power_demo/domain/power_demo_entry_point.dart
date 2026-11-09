/// Demoya giriş noktası. Analitikte `entry_point` parametresi (`source` DEĞİL).
enum PowerDemoEntryPoint {
  /// Tanıtım carousel'inin 3. sayfası (auth öncesi).
  onboarding('onboarding'),

  /// Güç marketindeki küçük "Güçleri dene" ikonu.
  market('market'),

  /// İlk quiz öncesi `quiz_powers` kartındaki bağlantı.
  quizIntro('quiz_intro');

  const PowerDemoEntryPoint(this.analyticsValue);

  final String analyticsValue;
}
