import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/features/chat/widgets/reaction_picker.dart';
import 'package:qulo_v2/features/profile_detail/widgets/report_category_sheet.dart';
import 'package:qulo_v2/features/chat/mixins/chat_screen_mixin.dart';

/// Chat ekraninda mesaj menusu (reaksiyon + silme) ve moderasyon akislari
/// (kullaniciyi sikayet et / engelle).
///
/// `ChatScreenMixin`'den ayrildi: tek dosya 677 satira ciktu (limit 300).
mixin ChatModerationMixin on ChatScreenMixin {

  // ─── Message Menu ───

  void showMessageMenu(MessageModel msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReactionPicker(
                onReactionSelected: (emoji) {
                  Navigator.pop(context);
                  ref
                      .read(chatProvider(widget.matchId).notifier)
                      .addReaction(msg.id, emoji);
                },
              ),
              if (isMe) ...[
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: context.appColors.error),
                  title: Text(
                    AppLocalizations.of(context).get('chat_delete_message'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: context.appColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(chatProvider(widget.matchId).notifier)
                        .deleteMessage(msg.id);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Report & Block ───

  String? _getTargetUserId() {
    return ref.read(matchListProvider).valueOrNull
        ?.where((m) => m.matchId == widget.matchId)
        .firstOrNull
        ?.user
        ?.userId;
  }

  void onChatReport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReportCategorySheet(
        onSelected: _showChatReportReasonDialog,
      ),
    );
  }

  void _showChatReportReasonDialog(String category) {
    final nav = ref.read(navigationServiceProvider);
    final controller = TextEditingController();
    final isOther = category == 'OTHER';
    final l10n = AppLocalizations.of(context);

    nav.showAppDialog(
      CustomDialog(
        name: 'chat_report_reason',
        builder: (ctx) => AlertDialog(
          title: Text(l10n.get('report')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.get('report_reason_hint'),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => nav.closeOverlay(),
              child: Text(l10n.get('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final reason = controller.text.trim();
                if (isOther && reason.isEmpty) return;
                nav.closeOverlay();
                final targetId = _getTargetUserId();
                if (targetId == null) return;
                await ref.read(reportRepositoryProvider).createReport(
                  reportedId: targetId,
                  category: category,
                  reason: reason.isNotEmpty ? reason : null,
                );
                controller.dispose();
              },
              child: Text(l10n.get('report')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onChatBlock() async {
    final l10n = AppLocalizations.of(context);
    final nav = ref.read(navigationServiceProvider);
    final confirmed = await nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'chat_block_user',
        title: l10n.get('block_user_title'),
        message: l10n.get('block_user_message'),
        confirmText: l10n.get('block'),
        cancelText: l10n.get('cancel'),
        isDestructive: true,
      ),
    );
    if (confirmed != true) return;
    final targetId = _getTargetUserId();
    if (targetId == null) return;
    await ref.read(blockRepositoryProvider).blockUser(targetId);
    if (mounted) {
      ref.read(navigationServiceProvider).pop();
    }
  }
}
