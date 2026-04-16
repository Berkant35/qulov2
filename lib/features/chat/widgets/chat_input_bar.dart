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
  final bool isLocked;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.hasText,
    required this.onSend,
    required this.onPhotoTap,
    required this.onQuestionTap,
    required this.onVoiceStart,
    required this.onChanged,
    this.isLocked = false,
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
              onPressed: isLocked ? null : onPhotoTap,
              icon: Icon(
                Icons.photo_camera_outlined,
                color: isLocked
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLocked,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                onChanged: onChanged,
                style: TextStyle(
                  color: isLocked
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: isLocked
                      ? context.tr('chat_answer_question_hint')
                      : context.tr('message_hint'),
                  hintStyle: TextStyle(color: theme.hintColor),
                  filled: true,
                  fillColor: isLocked
                      ? context.appColors.surfaceElevated
                          .withValues(alpha: 0.5)
                      : context.appColors.surfaceElevated,
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
                  disabledBorder: OutlineInputBorder(
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
              onPressed: isLocked ? null : onQuestionTap,
              icon: Icon(
                Icons.help_outline,
                color: isLocked ? context.appColors.primary.withValues(alpha: 0.4) : context.appColors.primary,
                size: 22,
              ),
            ),
            if (hasText)
              SafeTapButton(
                onTap: isLocked ? null : () async => onSend(),
                builder: (context, isLoading, onTap) => Opacity(
                  opacity: isLocked ? 0.4 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: context.appColors.primaryButtonGradient,
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
                ),
              )
            else
              Opacity(
                opacity: isLocked ? 0.4 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: context.appColors.primaryButtonGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: isLocked ? null : onVoiceStart,
                    icon: Icon(Icons.mic,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
