/// `QuestionStepSettings` için sunum-dışı logic: süre seçeneklerinin etiket ve
/// açıklama eşlemesi.
///
/// CLAUDE.md "Widget Logic → Mixin" kuralı gereği burada; stateless widget
/// olduğu için `on` kısıtı yok.
mixin QuestionStepSettingsMixin {
  /// Süre kartlarının l10n anahtarları — hızlıdan yavaşa.
  ///
  /// Bu liste 4 elemanlı ama süre seçenekleri (`timing.timePresets`) economy
  /// config'ten geliyor ve backoffice'ten değiştirilebiliyor: sayısı 4 olmak
  /// zorunda değil. Bu yüzden erişim indeks güvenli — liste taşarsa etiket
  /// yerine sürenin kendisi gösterilir.
  static const _labels = [
    'question_time_fast',
    'question_time_normal',
    'question_time_relaxed',
    'question_time_thoughtful',
  ];

  static const _descs = [
    'question_time_fast_desc',
    'question_time_normal_desc',
    'question_time_relaxed_desc',
    'question_time_thoughtful_desc',
  ];

  /// `index` için l10n anahtarı; liste dışındaysa `null` (çağıran süreyi yazar).
  String? timeLabelKey(int index) => index < _labels.length ? _labels[index] : null;

  String? timeDescKey(int index) => index < _descs.length ? _descs[index] : null;
}
