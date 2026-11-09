import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/chat_question_draft_model.dart';
import 'package:qulo_v2/features/chat/widgets/draft_list_item.dart';

/// Taslak gecmisi sheet'inin "Taslaklar" sekmesi: yukleniyor / hata / bos /
/// kaydirarak silinebilen liste.
class DraftListTab extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final List<ChatQuestionDraftModel>? drafts;
  final void Function(ChatQuestionDraftModel draft) onDraftSelected;
  final void Function(String draftId) onDeleteDraft;

  const DraftListTab({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.drafts,
    required this.onDraftSelected,
    required this.onDeleteDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = drafts;

    if (isLoading) {
      return const Center(child: AppLoadingWidget.large());
    }
    if (hasError) {
      return Center(
        child: Text(
          context.tr('chat_drafts_load_failed'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }
    if (items == null || items.isEmpty) {
      return Center(
        child: Text(
          context.tr('chat_no_drafts'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final draft = items[i];
        return Dismissible(
          key: Key(draft.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.appColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(Icons.delete_outline, color: context.appColors.error),
          ),
          onDismissed: (_) => onDeleteDraft(draft.id),
          child: DraftListItem(
            draft: draft,
            onTap: () => onDraftSelected(draft),
          ),
        );
      },
    );
  }
}
