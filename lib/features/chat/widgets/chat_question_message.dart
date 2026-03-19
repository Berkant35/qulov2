import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_card.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';

/// Renders a question message inside the chat timeline.
/// Fetches the question by ID from cache/API and shows [ChatQuestionCard].
class ChatQuestionMessage extends ConsumerStatefulWidget {
  final String questionId;
  final String matchId;
  final bool isMe;

  const ChatQuestionMessage({
    super.key,
    required this.questionId,
    required this.matchId,
    required this.isMe,
  });

  @override
  ConsumerState<ChatQuestionMessage> createState() =>
      _ChatQuestionMessageState();
}

class _ChatQuestionMessageState extends ConsumerState<ChatQuestionMessage> {
  bool _isAnswering = false;

  Future<void> _handleAnswer(
    String selectedOption,
    ChatQuestionModel question,
  ) async {
    if (_isAnswering) return;
    setState(() => _isAnswering = true);

    try {
      final service = ref.read(chatQuestionServiceProvider);
      final response = await service.answerQuestion(
        widget.questionId,
        {'selected_option': selectedOption},
      );

      // Update the cache with the answered state
      final answered = ChatQuestionModel(
        id: question.id,
        matchId: question.matchId,
        senderId: question.senderId,
        questionText: question.questionText,
        optionA: question.optionA,
        optionB: question.optionB,
        hasUnmatchRisk: question.hasUnmatchRisk,
        diamondCost: question.diamondCost,
        answeredOption: selectedOption,
        isCorrect: response.isCorrect,
        answeredAt: DateTime.now().toIso8601String(),
        createdAt: question.createdAt,
      );

      ref.read(chatQuestionCacheProvider.notifier).update((state) => {
            ...state,
            widget.questionId: answered,
          });

      // Refresh diamond balance
      ref.invalidate(diamondProvider);

      // If unmatch happened, we could handle navigation here
      // but the backend/realtime should handle the unmatch state
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cevap gonderilemedi. Lutfen tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnswering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionAsync = ref.watch(chatQuestionProvider(widget.questionId));

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      child: questionAsync.when(
        loading: () => const _LoadingPlaceholder(),
        error: (_, __) => const _ErrorPlaceholder(),
        data: (question) {
          if (question == null) return const _ErrorPlaceholder();
          return Stack(
            children: [
              ChatQuestionCard(
                question: question,
                isMyQuestion: widget.isMe,
                onAnswer: question.isAnswered || widget.isMe
                    ? null
                    : (option) => _handleAnswer(option, question),
              ),
              if (_isAnswering)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.6),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Center(child: AppLoadingWidget.small()),
                  ),
                ),
            ],
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
        'Soru yuklenemedi',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
