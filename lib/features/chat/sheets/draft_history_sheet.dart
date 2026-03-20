import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
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
            labelColor: AppColors.primary,
            unselectedLabelColor: context.appColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Taslaklar'),
              Tab(text: 'Gecmis'),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildDraftsTab(theme),
                _buildHistoryTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsTab(ThemeData theme) {
    if (_isDraftsLoading) {
      return const Center(child: AppLoadingWidget.large());
    }
    if (_draftsError != null) {
      return Center(
        child: Text(
          'Taslaklar yuklenemedi',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }
    if (_drafts == null || _drafts!.isEmpty) {
      return Center(
        child: Text(
          'Henuz taslak yok',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: _drafts!.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final draft = _drafts![i];
        return Dismissible(
          key: Key(draft.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
          onDismissed: (_) => _deleteDraft(draft.id),
          child: _DraftItem(
            draft: draft,
            onTap: () {
              Navigator.pop(context);
              widget.onDraftSelected(draft);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    if (_isHistoryLoading) {
      return const Center(child: AppLoadingWidget.large());
    }
    if (_historyError != null) {
      return Center(
        child: Text(
          'Gecmis yuklenemedi',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }
    if (_history == null || _history!.isEmpty) {
      return Center(
        child: Text(
          'Henuz soru gecmisi yok',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: _history!.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final item = _history![i];
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
          color: theme.colorScheme.surfaceContainerHighest,
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
                    '${draft.optionCount} sik',
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
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '${draft.optionCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
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
        color: theme.colorScheme.surfaceContainerHighest,
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
                  '$optionCount sik',
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
              color: isCorrect ? AppColors.success : AppColors.error,
              size: 20,
            ),
        ],
      ),
    );
  }
}
