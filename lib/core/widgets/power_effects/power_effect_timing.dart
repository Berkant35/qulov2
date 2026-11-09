import 'package:flutter/animation.dart';

/// Güç efektlerinin ortak zamanlaması (spec §4.3: tek hareket, ~300-600 ms).
abstract final class PowerEffectTiming {
  /// Efektin görünür hâle gelişi.
  static const Duration enter = Duration(milliseconds: 450);

  /// Efektin kapanışı: dikkat artık başka yerde olduğundan girişten kısa.
  static const Duration exit = Duration(milliseconds: 300);

  /// Girişte hızlı başlayıp yumuşak oturur; tüm efektler aynı eğriyi kullanır.
  static const Curve curve = Curves.easeOutCubic;
}
