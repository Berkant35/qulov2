import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/chat_question_draft_model.dart';
import 'package:qulo_v2/features/chat/mixins/draft_history_sheet_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/draft_list_tab.dart';
import 'package:qulo_v2/features/chat/widgets/question_history_tab.dart';

class DraftHistorySheet extends ConsumerStatefulWidget {
  final void Function(ChatQuestionDraftModel draft) onDraftSelected;

  const DraftHistorySheet({super.key, required this.onDraftSelected});

  @override
  ConsumerState<DraftHistorySheet> createState() => _DraftHistorySheetState();
}

class _DraftHistorySheetState extends ConsumerState<DraftHistorySheet>
    with SingleTickerProviderStateMixin, DraftHistorySheetMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    initMixin();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.textHint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Tab bar
          TabBar(
            controller: _tabCtrl,
            labelColor: context.appColors.primary,
            unselectedLabelColor: context.appColors.textSecondary,
            indicatorColor: context.appColors.primary,
            tabs: [
              Tab(text: context.tr('chat_drafts_tab')),
              Tab(text: context.tr('chat_history_tab')),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                DraftListTab(
                  isLoading: isDraftsLoading,
                  hasError: draftsFailed,
                  drafts: drafts,
                  onDraftSelected: selectDraft,
                  onDeleteDraft: deleteDraft,
                ),
                QuestionHistoryTab(
                  isLoading: isHistoryLoading,
                  hasError: historyFailed,
                  history: history,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
