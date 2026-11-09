import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';

/// Güç çubuğundaki "?" baloncuğunun durumu: hangi gücün açıklaması açık.
///
/// Yalnız bilgi verir: güç kullanmaz (`onPowerUsed` çağrılmaz), `quiz_power_tap` atmaz,
/// sayacı durdurmaz (sunucu süresi zaten durmaz — spec §4.4). Açılış `quiz_power_help_open`
/// olarak ölçülür (yalnız Firebase; para olayı değil).
mixin PowerHelpMixin<T extends StatefulWidget> on State<T> {
  PowerType? openHelp;

  /// Aynı "?" kapatır, başka "?" o gücün baloncuğuna geçer.
  void toggleHelp(PowerType type) {
    if (openHelp == type) {
      closeHelp();
      return;
    }
    setState(() => openHelp = type);
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizPowerHelpOpen,
      params: {AnalyticsEvents.paramPower: type.apiName},
    );
  }

  void closeHelp() {
    if (openHelp == null || !mounted) return;
    setState(() => openHelp = null);
  }

  /// Açık güç çubukta artık yoksa (ör. Hepsini Geç teklifi kalktı) baloncuk gösterilmez.
  PowerType? visibleHelp(List<PowerType> powers) =>
      powers.contains(openHelp) ? openHelp : null;
}
