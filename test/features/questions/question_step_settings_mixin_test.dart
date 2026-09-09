import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/questions/mixins/question_step_settings_mixin.dart';

/// Süre seçeneği etiketleri — sayısı config'ten gelir, 4 olmak zorunda değil.
///
/// Widget eskiden `itemCount: 4` sabitiyle `timePresets[i]` indeksliyordu:
/// backoffice `timing.timePresets` listesini 3 elemana indirseydi RangeError
/// ile çökerdi, 5'e çıkarsaydı beşincisi sessizce görünmezdi.
class _Subject with QuestionStepSettingsMixin {}

void main() {
  final subject = _Subject();

  test('ilk dört indeks için l10n anahtarı döner', () {
    expect(subject.timeLabelKey(0), 'question_time_fast');
    expect(subject.timeLabelKey(3), 'question_time_thoughtful');
    expect(subject.timeDescKey(0), 'question_time_fast_desc');
    expect(subject.timeDescKey(3), 'question_time_thoughtful_desc');
  });

  test('liste dışındaki indekste null döner — çağıran süreyi yazar, çökmez', () {
    expect(subject.timeLabelKey(4), isNull);
    expect(subject.timeDescKey(4), isNull);
    expect(subject.timeLabelKey(99), isNull);
  });

  test('etiket ve açıklama listeleri aynı uzunlukta — kartlar yarım kalmasın', () {
    for (var i = 0; i < 4; i++) {
      expect(subject.timeLabelKey(i), isNotNull, reason: 'index $i etiketi olmalı');
      expect(subject.timeDescKey(i), isNotNull, reason: 'index $i açıklaması olmalı');
    }
    expect(subject.timeLabelKey(4), isNull);
    expect(subject.timeDescKey(4), isNull);
  });
}
