import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_preview.dart';

/// "?" minyatürünün döngüsü: efekt son hâline oynar, bekler, kapanır; tekrar.
///
/// İlk kare efekt öncesi çizilir, bir sonraki karede oynamaya başlar (efektler ilk build'de
/// oynamaz). "Hareketi azalt" açıksa döngü yok: efekt bir kez son hâline atlar ve orada kalır.
mixin PowerHelpPreviewMixin on State<PowerHelpPreview> {
  /// Yarım döngü: giriş (~450 ms) + okuma payı.
  static const Duration halfCycle = Duration(milliseconds: 1200);

  /// Efekt son hâlde mi.
  bool shown = false;

  /// Her kapanışta artar: Doğru Say / Ek Süre sahnesi yeni turu taze kartla başlatır.
  int round = 0;

  Timer? _loop;

  /// İlk giriş: bir sonraki karede (hareketi azaltta tek ve son tik budur).
  void initPreview() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  /// Döngü yalnız hareket açıkken kurulur.
  void syncPreviewMotion() {
    if (!reduceMotionOf(context)) {
      _loop ??= Timer.periodic(halfCycle, (_) => _tick());
      return;
    }
    // Ayar döngü sürerken açıldı: son hâlde durur (efektler animasyonsuz atlar).
    final loop = _loop;
    if (loop == null) return;
    loop.cancel();
    _loop = null;
    shown = true;
  }

  void disposePreview() => _loop?.cancel();

  void _tick() {
    if (!mounted) return;
    setState(() {
      if (shown) round++;
      shown = !shown;
    });
  }
}
