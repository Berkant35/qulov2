import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onPhotoTap;
  final VoidCallback onQuestionTap;
  final VoidCallback onVoiceStart;
  final ValueChanged<String> onChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.hasText,
    required this.onSend,
    required this.onPhotoTap,
    required this.onQuestionTap,
    required this.onVoiceStart,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: onPhotoTap,
              icon: Icon(
                Icons.photo_camera_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                onChanged: onChanged,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: context.tr('message_hint'),
                  hintStyle: TextStyle(color: theme.hintColor),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onQuestionTap,
              icon: Icon(
                Icons.help_outline,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            if (hasText)
              SafeTapButton(
                onTap: () async => onSend(),
                builder: (context, isLoading, onTap) => Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryButtonGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: onTap,
                    icon: isLoading
                        ? const AppLoadingWidget.small()
                        : Icon(Icons.send,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20),
                  ),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryButtonGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onVoiceStart,
                  icon: Icon(Icons.mic,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
