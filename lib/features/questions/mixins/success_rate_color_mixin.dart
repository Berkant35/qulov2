import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

/// Soru başarı oranı (0–100) → renk eşlemesi: iyi / orta / zayıf.
///
/// `SuccessRateBar` ve `AnalyticsTotalsSection` aynı eşikleri ayrı ayrı
/// tutuyordu; tek yerde. Stateless widget'lara `on` kısıtsız mixlenir.
mixin SuccessRateColorMixin {
  static const int _goodRate = 70;
  static const int _fairRate = 40;

  Color successRateColor(BuildContext context, int rate) {
    if (rate >= _goodRate) return context.appColors.success;
    if (rate >= _fairRate) return context.appColors.warning;
    return context.appColors.error;
  }
}
