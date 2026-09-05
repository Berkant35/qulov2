import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_content.dart';

/// Tam genislik bottom sheet varyanti: drag handle + icerik.
class PageMessageSheet extends StatelessWidget {
  const PageMessageSheet({
    super.key,
    required this.message,
    required this.onClose,
  });

  final PageMessageModel message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appColors.textSecondary
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              PageMessageContent(message: message, onClose: onClose),
            ],
          ),
        ),
      ),
    );
  }
}
