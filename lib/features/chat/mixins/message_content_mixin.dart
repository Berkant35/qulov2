import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// [MessageContent] turetmeleri: gruplu baloncuk kose yaricapi.
mixin MessageContentMixin {
  /// Tek basina mesajda tum koseler tam yuvarlak. Ardisik mesajlarda
  /// baloncuklarin birlestigi ic koseler daralir (4px).
  BorderRadius groupedBorderRadius({
    required bool isMe,
    required bool isGroupStart,
    required bool isGroupEnd,
  }) {
    const full = Radius.circular(AppSpacing.radiusLg);
    const tight = Radius.circular(AppSpacing.radiusXs);

    if (isMe) {
      // Right-aligned bubbles: the right side gets tight corners in the middle
      return BorderRadius.only(
        topLeft: full,
        topRight: isGroupStart ? full : tight,
        bottomLeft: full,
        bottomRight: isGroupEnd ? full : tight,
      );
    }
    // Left-aligned bubbles: the left side gets tight corners in the middle
    return BorderRadius.only(
      topLeft: isGroupStart ? full : tight,
      topRight: full,
      bottomLeft: isGroupEnd ? full : tight,
      bottomRight: full,
    );
  }
}
