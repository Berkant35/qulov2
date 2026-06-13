import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/icons/icon_ref.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

/// Tip güvenli icon API'si — [IconRef]'ten filled veya outlined varyantı
/// seçip [QIcon]'a delege eder. QIcon altyapısı dokunulmadan kalır;
/// AppIcon sadece üst katman.
///
/// Kullanım:
/// ```dart
/// AppIcon(QIcons.heart, filled: isLiked, color: appColors.primary)
/// AppIcon(QIcons.lock, size: 20)
/// ```
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.ref, {
    this.filled = false,
    this.color,
    this.size = 24,
    super.key,
  });

  final IconRef ref;
  final bool filled;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return QIcon(
      filled ? ref.filled : ref.outlined,
      size: size,
      color: color,
    );
  }
}
