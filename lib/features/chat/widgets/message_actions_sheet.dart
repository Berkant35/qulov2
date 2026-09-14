import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/chat/widgets/reaction_picker.dart';

/// Mesaja uzun basinca acilan sheet: tepki secici + (kendi mesajiysa) silme.
/// Secimden once kendini kapatir (`ReportCategorySheet` ile ayni desen).
class MessageActionsSheet extends StatelessWidget {
  final bool canDelete;
  final ValueChanged<String> onReaction;
  final VoidCallback onDelete;

  const MessageActionsSheet({
    super.key,
    required this.canDelete,
    required this.onReaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = context.appColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReactionPicker(
              onReactionSelected: (emoji) {
                Navigator.pop(context);
                onReaction(emoji);
              },
            ),
            if (canDelete) ...[
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Icon(Icons.delete_outline, color: errorColor),
                title: Text(
                  context.tr('chat_delete_message'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: errorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
