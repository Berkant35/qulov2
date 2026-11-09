import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_question.dart';

/// Güç demosunun dinamik çeviri anahtarları — tek kaynak. Ekran metni bu adlardan okur,
/// `dynamic_keys_test` aynı fonksiyonlarla her ailenin 18 dilde var olduğunu sınar.
abstract final class PowerDemoKeys {
  /// Soru metni: `power_demo_q1`.
  static String question(PowerDemoQuestion q) => 'power_demo_${q.id}';

  /// Şık metni: `power_demo_q1_opt0`.
  static String option(PowerDemoQuestion q, int index) =>
      'power_demo_${q.id}_opt$index';

  /// Soru sahibinin ipucu: `power_demo_q4_hint`.
  static String questionHint(PowerDemoQuestion q) => 'power_demo_${q.id}_hint';

  /// Güç adımının tek cümlelik talimatı: `power_demo_hint_half`.
  static String instruction(DemoPower power) =>
      'power_demo_hint_${_slug(power)}';

  /// Güç kullanıldıktan sonraki tek satır: `power_demo_result_half`.
  static String result(DemoPower power) => 'power_demo_result_${_slug(power)}';

  /// Güç butonunun etiketi — gerçek quiz çubuğuyla aynı anahtarlar (`PowerBarMixin.powerLabel`).
  static String barLabel(DemoPower power) => switch (power) {
    DemoPower.timeExtend => 'power_bar_time',
    DemoPower.oracle => 'power_bar_oracle',
    DemoPower.half => 'power_bar_half',
    DemoPower.hint => 'power_bar_hint',
    DemoPower.skip => 'power_bar_skip',
    DemoPower.skipAll => 'power_bar_skip_all',
  };

  /// `TIME_EXTEND` → `time_extend`.
  static String _slug(DemoPower power) => power.apiName.toLowerCase();
}
