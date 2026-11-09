import 'package:flutter/widgets.dart';

/// Paylaşım sayfasının çıkış noktası (`sharePositionOrigin`).
///
/// iOS 26'da iPhone'da da zorunlu: verilmeyen, sıfır ya da görünüm dışına
/// taşan alan `PlatformException(sharePositionOrigin: argument must be set)`
/// ile crash veriyordu (Crashlytics, 2.0.14–2.0.15). Dokunulan widget'ın
/// ekranda görünen kısmı kullanılır; ölçülemiyorsa ekran ortasında 1×1'lik
/// geçerli bir alan.
Rect shareOriginFor(BuildContext context) {
  final screen = Offset.zero & MediaQuery.sizeOf(context);
  final box = context.findRenderObject();
  if (box is RenderBox && box.attached && box.hasSize) {
    final visible = (box.localToGlobal(Offset.zero) & box.size).intersect(screen);
    if (visible.width > 0 && visible.height > 0) return visible;
  }
  return Rect.fromCenter(center: screen.center, width: 1, height: 1);
}
