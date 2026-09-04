import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/chat_question_draft_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class DraftHistorySheet extends ConsumerStatefulWidget {
  final void Function(ChatQuestionDraftModel draft) onDraftSelected;

  const DraftHistorySheet({super.key, required this.onDraftSelected});

  @override
  ConsumerState<DraftHistorySheet> createState() => _DraftHistorySheetState();
}

class _DraftHistorySheetState extends ConsumerState<DraftHistorySheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<ChatQuestionDraftModel>? _drafts;
  List<Map<String, dynamic>>? _history;
  bool _isDraftsLoading = true;
  bool _isHistoryLoading = true;
  String? _draftsError;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadDrafts();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.getDrafts();
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _drafts = data;
        _isDraftsLoading = false;
      }),
      failure: (f) => setState(() {
        _draftsError = f.toString();
        _isDraftsLoading = false;
      }),
    );
  }

  Future<void> _loadHistory() async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.getHistory();
    if (!mounted) return;
    result.when(
      success: (data) {
        final questions = data.items
            .map((item) => {
                  'id': item.id,
                  'question_text': item.questionText,
                  'option_count': item.optionCount,
                  'created_at': item.createdAt,
                })
            .toList();
        setState(() {
          _history = questions;
          _isHistoryLoading = false;
        });
      },
      failure: (f) => setState(() {
        _historyError = f.toString();
        _isHistoryLoading = false;
      }),
    );
  }

  Future<void> _deleteDraft(String draftId) async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.deleteDraft(draftId);
    result.when(
      success: (_) {
        setState(() {
          _drafts?.removeWhere((d) => d.id == draftId);
        });
      },
      failure: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).get('chat_draft_delete_failed'))),
          );
        }
      },
    );
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
                borderRadius: BorderRadius.circular(2),
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
                _DraftsTab(
                  isLoading: _isDraftsLoading,
                  error: _draftsError,
                  drafts: _drafts,
                  onDraftSelected: (draft) {
                    Navigator.pop(context);
                    widget.onDraftSelected(draft);
                  },
                  onDeleteDraft: _deleteDraft,
                ),
                _HistoryTab(
                  isLoading: _isHistoryLoading,
                  error: _historyError,
                  history: _history,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _DraftsTab extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<ChatQuestionDraftModel>? drafts;
  final void Function(ChatQuestionDraftModel draft) onDraftSelected;
  final void Function(String draftId) onDeleteDraft;

  const _DraftsTab({
    required this.isLoading,
    required this.error,
    required this.drafts,
    required this.onDraftSelected,
    required this.onDeleteDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(child: AppLoadingWidget.large());
    }
    if (error != null) {
      return Center(
        child: Text(
          context.tr('chat_drafts_load_failed'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }
    if (drafts == null || drafts!.isEmpty) {
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
      itemCount: drafts!.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final draft = drafts![i];
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
          child: _DraftItem(
            draft: draft,
            onTap: () => onDraftSelected(draft),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>>? history;

  const _HistoryTab({
    required this.isLoading,
    required this.error,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(child: AppLoadingWidget.large());
    }
    if (error != null) {
      return Center(
        child: Text(
          context.tr('chat_history_load_failed'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }
    if (history == null || history!.isEmpty) {
      return Center(
        child: Text(
          context.tr('chat_no_history'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: history!.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final item = history![i];
        return _HistoryItem(data: item);
      },
    );
  }
}

class _DraftItem extends StatelessWidget {
  final ChatQuestionDraftModel draft;
  final VoidCallback onTap;

  const _DraftItem({required this.draft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.questionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.trPlural('option_count', draft.optionCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.appColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.appColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '${draft.optionCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.appColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HistoryItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questionText = data['question_text'] as String? ?? '';
    final optionCount = data['option_count'] as int? ?? 2;
    final isCorrect = data['is_correct'] as bool?;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.trPlural('option_count', optionCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.appColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (isCorrect != null)
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? context.appColors.success : context.appColors.error,
              size: 20,
            ),
        ],
      ),
    );
  }
}
