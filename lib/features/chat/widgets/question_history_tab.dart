import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/question_history_item.dart';

/// Taslak gecmisi sheet'inin "Gecmis" sekmesi: yukleniyor / hata / bos / liste.
class QuestionHistoryTab extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final List<ChatQuestionHistoryItem>? history;

  const QuestionHistoryTab({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = history;

    if (isLoading) {
      return const Center(child: AppLoadingWidget.large());
    }
    if (hasError) {
      return Center(
        child: Text(
          context.tr('chat_history_load_failed'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      );
    }
    if (items == null || items.isEmpty) {
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
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => QuestionHistoryItem(item: items[i]),
    );
  }
}
