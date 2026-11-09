import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/constants/power_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';

/// Gerçek quiz'deki güç efektlerinin ve "?" baloncuğunun metinleri — şık etiketi ile
/// baloncuk aynı biçimi kullansın diye tek yerde.
mixin PowerEffectLabelsMixin {
  /// Kâhin yüzdesi ("%70"); [accuracy] `EconomyConfig.oracleAccuracy` (0–1).
  String oraclePercent(BuildContext context, double accuracy) =>
      context.fmt.percent((accuracy * 100).round());

  /// Kâhin etiketi ("%70 doğru"). `power_oracle_desc` sohbette de kullanıldığı için
  /// değiştirilmez; yüzde ayrı anahtarla gelir (spec §13.2/8).
  String oracleAccuracyLabel(BuildContext context, double accuracy) => context
      .tr('power_oracle_accuracy')
      .replaceAll('{percent}', oraclePercent(context, accuracy));

  /// Gücün tek cümlelik açıklaması (mevcut `power_*_desc` anahtarları).
  String powerDescription(BuildContext context, PowerType type) =>
      context.tr(powerDescKey(type.apiName));

  /// Baloncuktaki yüzde satırı: yalnız Kâhin'de.
  String? helpAccuracyLabel(BuildContext context, PowerType type, double accuracy) =>
      type == PowerType.oracle ? oracleAccuracyLabel(context, accuracy) : null;
}
