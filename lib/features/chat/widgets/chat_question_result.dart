import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/reward_media_reveal.dart';

class ChatQuestionResultScreen extends ConsumerWidget {
  final ChatQuestionAnswerResponse result;
  final ChatQuestionModel question;
  final VoidCallback? onRescue;
  final List<PowerUsageRecord> powerUsages;

  const ChatQuestionResultScreen({
    super.key,
    required this.result,
    required this.question,
    this.onRescue,
    this.powerUsages = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCorrect = result.isCorrect;

    return AppScaffold(
      title: isCorrect ? 'Doğru!' : 'Yanlış',
      showBackButton: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            children: [
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
              const SizedBox(height: AppSpacing.xl),
              // Detail Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                child: Column(
                  children: [
                    if (_totalGreen > 0)
                      _GreenRewardDetailCard(
                        totalGreen: _totalGreen,
                        powerUsages: powerUsages,
                      ),
                    if (_totalPurple > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      _PurpleSpentCard(
                        totalPurple: _totalPurple,
                        powerUsages: powerUsages,
                      ),
                    ],
                    if (result.powersUsed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _PowersUsedCard(powers: result.powersUsed),
                    ],
                    if (result.correctOption != null && result.answeredOption != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _AnswerDetailsCard(
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
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasRewardMedia =>
      result.rewardMediaUrl != null || question.rewardMediaUrl != null;

  int get _totalGreen =>
      powerUsages.fold(0, (sum, p) => sum + p.greenEarned);

  int get _totalPurple =>
      powerUsages.fold(0, (sum, p) => sum + p.purpleSpent);
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


class _GreenRewardDetailCard extends StatefulWidget {
  final int totalGreen;
  final List<PowerUsageRecord> powerUsages;

  const _GreenRewardDetailCard({
    required this.totalGreen,
    required this.powerUsages,
  });

  @override
  State<_GreenRewardDetailCard> createState() => _GreenRewardDetailCardState();
}

class _GreenRewardDetailCardState extends State<_GreenRewardDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successColor = context.appColors.success;

    // Group by powerName and sum greenEarned
    final grouped = <String, int>{};
    for (final usage in widget.powerUsages) {
      if (usage.greenEarned > 0) {
        grouped[usage.powerName] =
            (grouped[usage.powerName] ?? 0) + usage.greenEarned;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: successColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — tappable to expand
          GestureDetector(
            onTap: grouped.length > 1
                ? () => setState(() => _expanded = !_expanded)
                : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const DiamondIcon.green(size: 24, showGlow: false),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+${widget.totalGreen} Yeşil Elmas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Soru sahibine kazandırdın',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (grouped.length > 1)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: context.appColors.textSecondary,
                    size: 20,
                  ),
              ],
            ),
          ),
          // Expandable detail
          if (_expanded && grouped.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(
              color: successColor.withValues(alpha: 0.2),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...grouped.entries.map((entry) {
              final label = entry.key == 'ANSWER'
                  ? 'Doğru cevap'
                  : entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    Text(
                      '+${entry.value}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _PurpleSpentCard extends StatefulWidget {
  final int totalPurple;
  final List<PowerUsageRecord> powerUsages;

  const _PurpleSpentCard({
    required this.totalPurple,
    required this.powerUsages,
  });

  @override
  State<_PurpleSpentCard> createState() => _PurpleSpentCardState();
}

class _PurpleSpentCardState extends State<_PurpleSpentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purpleColor = context.appColors.primary;

    // Group by powerName and sum purpleSpent
    final grouped = <String, int>{};
    for (final usage in widget.powerUsages) {
      if (usage.purpleSpent > 0) {
        grouped[usage.powerName] =
            (grouped[usage.powerName] ?? 0) + usage.purpleSpent;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: purpleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: purpleColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: grouped.length > 1
                ? () => setState(() => _expanded = !_expanded)
                : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const DiamondIcon.purple(size: 24, showGlow: false),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '-${widget.totalPurple} Mor Elmas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: purpleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        grouped.length == 1
                            ? '${grouped.keys.first} için harcandı'
                            : 'Güç kullanımı için harcandı',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (grouped.length > 1)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: context.appColors.textSecondary,
                    size: 20,
                  ),
              ],
            ),
          ),
          if (_expanded && grouped.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(
              color: purpleColor.withValues(alpha: 0.2),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...grouped.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      Text(
                        '-${entry.value}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: purpleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _PowersUsedCard extends StatelessWidget {
  final List<String> powers;
  const _PowersUsedCard({required this.powers});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kullanılan Güçler',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Builder(builder: (context) {
            final grouped = <String, int>{};
            for (final name in powers) {
              grouped[name] = (grouped[name] ?? 0) + 1;
            }
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: grouped.entries.map((entry) {
                final type = PowerType.fromApiName(entry.key);
                if (type == null) return const SizedBox.shrink();
                final label = entry.value > 1
                    ? '${entry.key} ×${entry.value}'
                    : entry.key;
                return Chip(
                  avatar: PowerIcon(type: type, size: 16),
                  label: Text(
                    label,
                    style: TextStyle(fontSize: 11, color: type.color),
                  ),
                  backgroundColor: type.color.withValues(alpha: 0.1),
                  side: BorderSide(color: type.color.withValues(alpha: 0.3)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _AnswerDetailsCard extends StatelessWidget {
  final String answeredOption;
  final String correctOption;
  final bool isCorrect;
  final int? timeSpent;

  const _AnswerDetailsCard({
    required this.answeredOption,
    required this.correctOption,
    required this.isCorrect,
    this.timeSpent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correctColor = context.appColors.success;
    final wrongColor = context.appColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: (isCorrect ? correctColor : wrongColor).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OptionBadge(
              label: 'Cevabın',
              option: answeredOption,
              color: isCorrect ? correctColor : wrongColor,
            ),
          ),
          Container(width: 1, height: 36, color: theme.dividerColor),
          Expanded(
            child: _OptionBadge(
              label: 'Doğru',
              option: correctOption,
              color: correctColor,
            ),
          ),
          if (timeSpent != null) ...[
            Container(width: 1, height: 36, color: theme.dividerColor),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Süre',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.appColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${timeSpent}s',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionBadge extends StatelessWidget {
  final String label;
  final String option;
  final Color color;

  const _OptionBadge({
    required this.label,
    required this.option,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.appColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              option,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
