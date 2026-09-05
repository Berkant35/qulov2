import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_content.dart';

/// Modal ve bottom sheet varyantlarinin ortak govdesi: mesaj icerigi +
/// sag ustte kapatma dokunma alani.
class PageMessageOverlayBody extends StatelessWidget {
  const PageMessageOverlayBody({
    super.key,
    required this.message,
    required this.onClose,
  });

  final PageMessageModel message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageMessageContent(message: message, onClose: onClose),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.close,
              size: 20,
              color: context.appColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
