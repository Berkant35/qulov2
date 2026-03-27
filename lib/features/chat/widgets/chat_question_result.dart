import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/reward_media_reveal.dart';

class ChatQuestionResultScreen extends ConsumerWidget {
  final ChatQuestionAnswerResponse result;
  final ChatQuestionModel question;
  final VoidCallback? onRescue;

  const ChatQuestionResultScreen({
    super.key,
    required this.result,
    required this.question,
    this.onRescue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCorrect = result.isCorrect;

    return AppScaffold(
      title: isCorrect ? 'Doğru!' : 'Yanlış',
      showBackButton: false,
      body: Column(
        children: [
          const Spacer(flex: 2),
          // Result icon
          _ResultIcon(isCorrect: isCorrect),
          const SizedBox(height: AppSpacing.xl),
          // Title
          Text(
            isCorrect ? 'Tebrikler!' : 'Yanlış Cevap',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isCorrect ? context.appColors.success : context.appColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Subtitle
          if (result.unmatched)
            _UnmatchWarning()
          else if (isCorrect)
            Text(
              'Soruyu doğru cevapladın!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            )
          else ...[
            Text(
              'Bir dahaki sefere daha şanslı olursun.',
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
                  'Kurtarma Hakkı (Skip)',
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
          const SizedBox(height: AppSpacing.xxl),
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
          const Spacer(flex: 3),
          // Back button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  'Geri Dön',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  bool get _hasRewardMedia =>
      result.rewardMediaUrl != null || question.rewardMediaUrl != null;
}

class _ResultIcon extends StatefulWidget {
  final bool isCorrect;
  const _ResultIcon({required this.isCorrect});

  @override
  State<_ResultIcon> createState() => _ResultIconState();
}

class _ResultIconState extends State<_ResultIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isCorrect ? context.appColors.success : context.appColors.error;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          widget.isCorrect ? Icons.check_rounded : Icons.close_rounded,
          size: 48,
          color: color,
        ),
      ),
    );
  }
}

class _UnmatchWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: context.appColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Eşleşme sona erdi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appColors.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
