import 'package:flutter/foundation.dart';

/// Filled (Solar bold-duotone) ve outlined (Solar linear) SVG path'lerini
/// bir arada tutan immutable value object.
///
/// Kullanım: [QIcons.heart] gibi const referanslar üzerinden çağrılır,
/// [AppIcon] widget'ı `filled` bool'una göre uygun path'i seçer.
@immutable
class IconRef {
  final String filled;
  final String outlined;
  const IconRef({required this.filled, required this.outlined});
}
