import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Yuvarlak köşeli renkli yüzey; rengi bir [Material] boyar.
///
/// `ListTile` / `InkWell` mürekkebini (dokunma dalgası, vurgu) en yakın
/// [Material]'a çizer. Rengi `Container(decoration:)` ile boyamak bu mürekkebi
/// örter: dokunmada görsel geri bildirim kaybolur (Flutter bunu debug'da
/// assertion ile yakalar). Dokunulabilir satır içeren kartlarda bunu kullan.
class InkSurface extends StatelessWidget {
  final Widget child;

  /// Varsayılan: `colorScheme.surface`.
  final Color? color;
  final double radius;
  final BorderSide side;
  final EdgeInsetsGeometry margin;

  const InkSurface({
    super.key,
    required this.child,
    this.color,
    this.radius = AppSpacing.radiusMd,
    this.side = BorderSide.none,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
