import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_overlay_body.dart';

/// Ortali modal varyanti: Material kart + sinirli genislik; showDialog'un
/// yari saydam barrier'i uzerinde durur.
class PageMessageModalCard extends StatelessWidget {
  const PageMessageModalCard({
    super.key,
    required this.message,
    required this.onClose,
  });

  final PageMessageModel message;
  final VoidCallback onClose;

  static const _maxWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.appColors.surfaceElevated,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PageMessageOverlayBody(message: message, onClose: onClose),
        ),
      ),
    );
  }
}
