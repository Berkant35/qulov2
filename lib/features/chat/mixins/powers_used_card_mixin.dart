import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/constants/power_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// [PowersUsedCard]'ın sunum-dışı logic'i: aynı güç birden çok kullanıldıysa tek çipte sayar,
/// etiketi çevirir (ham sunucu kodu — `HALF` — gösterilmez).
mixin PowersUsedCardWidgetMixin {
  /// Güç adı → kullanım sayısı; ilk görülme sırası korunur.
  Map<String, int> countByPower(List<String> powers) {
    final counts = <String, int>{};
    for (final name in powers) {
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }

  String powerChipLabel(BuildContext context, String powerName, int count) {
    final label = context.tr(powerLabelKey(powerName));
    return count > 1 ? '$label ×$count' : label;
  }
}
