import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/constants/power_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// [ChatQuestionRewardCards]'ın sunum-dışı logic'i: kart metinleri ve güç adı → çevrilmiş satır
/// etiketi eşlemesi (ham sunucu kodu — `HALF`, `ANSWER` — gösterilmez).
mixin ChatQuestionRewardCardsWidgetMixin {
  String countText(BuildContext context, String key, int count) =>
      context.tr(key).replaceAll('{count}', '$count');

  /// Tek güçte hangi güç için harcandığı, birden çokta genel metin (döküm kartın içinde).
  String purpleSubtitle(BuildContext context, Map<String, int> purpleByPower) => purpleByPower.length == 1
      ? context
          .tr('result_power_spent_single')
          .replaceAll('{power}', context.tr(powerUsageLabelKey(purpleByPower.keys.first)))
      : context.tr('result_power_spent_multi');

  Map<String, int> labeledRows(BuildContext context, Map<String, int> amountsByPower) => {
        for (final entry in amountsByPower.entries) context.tr(powerUsageLabelKey(entry.key)): entry.value,
      };
}
