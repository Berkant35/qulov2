import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';

/// Demo sorusunun yapısı. Metinler buraya konmaz (l10n): UI anahtarları [id]'den türetir —
/// `power_demo_{id}`, `power_demo_{id}_opt{i}`, `power_demo_{id}_hint`.
class PowerDemoQuestion {
  const PowerDemoQuestion({
    required this.id,
    required this.optionCount,
    required this.correctIndex,
    this.hasHint = false,
    this.power,
  }) : assert(optionCount >= 2, 'bir soruda en az 2 şık olmalı'),
       assert(
         correctIndex >= 0 && correctIndex < optionCount,
         'doğru şık aralıkta olmalı',
       );

  /// `q1`, `q2`, … (senaryodaki sıra, 1 tabanlı).
  final String id;
  final int optionCount;

  /// Doğru şıkkın indeksi (0 tabanlı).
  final int correctIndex;

  /// Soru sahibinin ipucu var mı (İpucu adımı için).
  final bool hasHint;

  /// Bu adımda öğretilen güç; `null` = güçsüz soru (Hepsini Geç'in geçeceği sorular).
  final DemoPower? power;
}
