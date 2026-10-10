import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/answer_details_card.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_reward_cards.dart';
import 'package:qulo_v2/features/chat/widgets/powers_used_card.dart';
import 'package:qulo_v2/features/chat/widgets/result_icon.dart';
import 'package:qulo_v2/features/chat/widgets/reward_media_reveal.dart';
import 'package:qulo_v2/features/chat/widgets/unmatch_warning.dart';

class ChatQuestionResultScreen extends StatelessWidget {
  final ChatQuestionAnswerResponse result;
  final ChatQuestionModel question;
  final VoidCallback? onRescue;

  /// "Geri dön": çözüm ekranını sonuçla kapatır (ekranın sahibi karar verir, burada Navigator yok).
  final VoidCallback onClose;
  final List<PowerUsageRecord> powerUsages;

  const ChatQuestionResultScreen({
    super.key,
    required this.result,
    required this.question,
    required this.onClose,
    this.onRescue,
    this.powerUsages = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = result.isCorrect;

    return AppScaffold(
      title: isCorrect ? context.tr('result_correct') : context.tr('result_wrong'),
      showBackButton: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            children: [
              // Result icon
              ResultIcon(isCorrect: isCorrect),
              const SizedBox(height: AppSpacing.xl),
              // Title
              Text(
                isCorrect ? context.tr('result_congrats') : context.tr('result_wrong'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? context.appColors.success : context.appColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Subtitle
              if (result.unmatched)
                const UnmatchWarning()
              else if (isCorrect)
                Text(
                  context.tr('result_correct_subtitle'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                )
              else ...[
                Text(
                  context.tr('result_wrong_subtitle'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRescue != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: onRescue,
                    icon: Icon(Icons.skip_next, color: context.appColors.warning),
                    label: Text(
                      context.tr('result_rescue'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.appColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.appColors.warning),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.xl),
              // Detail Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                child: Column(
                  children: [
                    ChatQuestionRewardCards(powerUsages: powerUsages),
                    if (result.powersUsed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      PowersUsedCard(powers: result.powersUsed),
                    ],
                    if (result.correctOption != null && result.answeredOption != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AnswerDetailsCard(
                        answeredOption: result.answeredOption!,
                        correctOption: result.correctOption!,
                        isCorrect: result.isCorrect,
                        timeSpent: result.timeSpent,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Reward media reveal
              if (isCorrect && _hasRewardMedia)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: RewardMediaReveal(
                    mediaUrl: result.rewardMediaUrl ?? question.rewardMediaUrl!,
                    mediaType: question.rewardMediaType ?? 'image',
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      context.tr('result_go_back'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.inkOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasRewardMedia =>
      result.rewardMediaUrl != null || question.rewardMediaUrl != null;
}
