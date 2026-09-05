import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_content.dart';

class PageMessageInlineCard extends ConsumerWidget {
  final PageMessageModel message;
  final VoidCallback onDismiss;

  const PageMessageInlineCard({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Stack(
        children: [
          PageMessageContent(message: message, onClose: onDismiss),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 18,
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
