import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_card.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Renders a question message inside the chat timeline.
/// Fetches the question by ID from cache/API and shows [ChatQuestionCard].
class ChatQuestionMessage extends ConsumerWidget {
  final String questionId;
  final String matchId;
  final bool isMe;

  const ChatQuestionMessage({
    super.key,
    required this.questionId,
    required this.matchId,
    required this.isMe,
  });

  Future<void> _openSolveScreen(
    BuildContext context,
    WidgetRef ref,
    ChatQuestionModel question,
  ) async {
    await ref.read(navigationServiceProvider).push(
      RouteNames.solveChatQuestion,
      params: {'questionId': question.id},
      extra: question,
    );

    // After returning from solve screen, refresh the question from API
    // (the cache will be stale if the user answered)
    if (context.mounted) {
      _refreshQuestion(ref);
    }
  }

  void _refreshQuestion(WidgetRef ref) {
    // Cache'den sil + fetch provider'i invalidate et
    // Cache temizlenince chatQuestionProvider rebuild olur,
    // fetch provider invalidate edilince API'den taze veri cekilir
    ref.read(chatQuestionCacheProvider.notifier).update((state) {
      final updated = Map<String, ChatQuestionModel>.from(state);
      updated.remove(questionId);
      return updated;
    });
    ref.invalidate(chatQuestionFetchProvider(questionId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(chatQuestionProvider(questionId));

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      child: questionAsync.when(
        loading: () => const _LoadingPlaceholder(),
        error: (_, __) => const _ErrorPlaceholder(),
        data: (question) {
          if (question == null) return const _ErrorPlaceholder();
          return ChatQuestionCard(
            question: question,
            isMyQuestion: isMe,
            onOpen: question.isAnswered || isMe
                ? null
                : () => _openSolveScreen(context, ref, question),
          );
        },
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: const Center(child: AppLoadingWidget.small()),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        'Soru yüklenemedi',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
