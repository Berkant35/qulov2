import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/blurred_media_preview.dart';

class ChatQuestionCard extends StatelessWidget {
  final ChatQuestionModel question;
  final bool isMyQuestion;
  /// Called when the receiver taps "Soruyu Aç" — navigate to solve screen.
  final VoidCallback? onOpen;

  const ChatQuestionCard({
    super.key,
    required this.question,
    required this.isMyQuestion,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = question.hasUnmatchRisk
        ? context.appColors.error.withValues(alpha: 0.6)
        : question.hasChatLock
            ? context.appColors.warning.withValues(alpha: 0.6)
            : context.appColors.primary.withValues(alpha: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badges row
              _BadgesRow(question: question),

              // Question text
              Text(
                question.questionText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Options / action
              if (question.isAbandoned)
                _AbandonedOptions(question: question)
              else if (!question.isAnswered && !isMyQuestion)
                _OpenButton(onOpen: onOpen)
              else if (!question.isAnswered && isMyQuestion)
                _WaitingOptions(question: question)
              else
                _AnsweredOptions(question: question),
            ],
          ),
        ),

        // Blurred media preview (below the card)
        if (question.hasRewardMedia)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: BlurredMediaPreview(
              mediaUrl: question.rewardMediaUrl,
              mediaType: question.rewardMediaType ?? 'image',
              isRevealed: question.isCorrect == true,
            ),
          ),
      ],
    );
  }
}

// ─── Badges Row ───────────────────────────────────────────────────────────────

class _BadgesRow extends StatelessWidget {
  final ChatQuestionModel question;

  const _BadgesRow({required this.question});

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (question.hasUnmatchRisk) {
      badges.add(_Badge(
        icon: '\u26a0\ufe0f',
        label: context.tr('question_risky'),
        color: context.appColors.error,
      ));
    }

    if (question.isPowerBlocked) {
      badges.add(_Badge(
        icon: '\u26a1',
        label: context.tr('question_power_block'),
        color: context.appColors.warning,
      ));
    }

    if (question.hasChatLock) {
      badges.add(_Badge(
        icon: '\ud83d\udd12',
        label: context.tr('question_chat_locked'),
        color: context.appColors.warning,
      ));
    }

    if (question.timeLimitSeconds > 0) {
      badges.add(_Badge(
        icon: '\u23f1',
        label: '${question.timeLimitSeconds}s',
        color: context.appColors.textSecondary,
      ));
    }

    if (question.isAbandoned) {
      badges.add(_Badge(
        icon: '\ud83c\udfc3',
        label: context.tr('question_fled'),
        color: Colors.grey,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: badges,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Open Button (receiver, unanswered) ───────────────────────────────────────

class _OpenButton extends StatelessWidget {
  final VoidCallback? onOpen;

  const _OpenButton({this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onOpen,
        icon: const Icon(Icons.lock_open_rounded, size: 16),
        label: Text(AppLocalizations.of(context).get('chat_open_question')),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Waiting Options (sender) ─────────────────────────────────────────────────

class _WaitingOptions extends StatelessWidget {
  final ChatQuestionModel question;

  const _WaitingOptions({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _buildOptionLabels(question);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final opt in options) ...[
          _OptionText(label: opt.$1, text: opt.$2, theme: theme),
          if (opt != options.last) const SizedBox(height: AppSpacing.xs),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context).get('chat_waiting_answer'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.appColors.textHint,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ─── Answered Options (both sides) ───────────────────────────────────────────

class _AnsweredOptions extends StatelessWidget {
  final ChatQuestionModel question;

  const _AnsweredOptions({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answeredOpt = question.answeredOption;
    final isCorrect = question.isCorrect ?? false;
    final options = _buildOptionLabels(question);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final opt in options) ...[
          _AnsweredOption(
            label: opt.$1,
            text: opt.$2,
            isSelected: answeredOpt == opt.$1,
            isCorrectChoice: isCorrect && answeredOpt == opt.$1,
            isWrongChoice: !isCorrect && answeredOpt == opt.$1,
            theme: theme,
          ),
          if (opt != options.last) const SizedBox(height: AppSpacing.sm),
        ],
        // Unmatch result
        if (!isCorrect && question.hasUnmatchRisk) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).get('chat_unmatch_occurred'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        // Powers used (grouped: TIME_EXTEND ×6)
        if (question.powersUsed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Builder(builder: (context) {
            // Group same powers: {ORACLE: 1, TIME_EXTEND: 6}
            final grouped = <String, int>{};
            for (final name in question.powersUsed) {
              final key = name.toString();
              grouped[key] = (grouped[key] ?? 0) + 1;
            }
            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: grouped.entries.map((entry) {
                final type = PowerType.fromApiName(entry.key);
                if (type == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: type.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PowerIcon(type: type, size: 12),
                      if (entry.value > 1) ...[
                        const SizedBox(width: 2),
                        Text(
                          '×${entry.value}',
                          style: TextStyle(fontSize: 9, color: type.color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ],
    );
  }
}

// ─── Abandoned Options (question was abandoned by receiver) ───────────────────

class _AbandonedOptions extends StatelessWidget {
  final ChatQuestionModel question;

  const _AbandonedOptions({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _buildOptionLabels(question);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final opt in options) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    opt.$1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    opt.$2,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (opt != options.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Returns list of (label, text) pairs for options A/B or A/B/C/D.
List<(String, String)> _buildOptionLabels(ChatQuestionModel question) {
  if (question.optionCount == 4) {
    return [
      ('A', question.optionA),
      ('B', question.optionB),
      ('C', question.optionC ?? ''),
      ('D', question.optionD ?? ''),
    ];
  }
  return [
    ('A', question.optionA),
    ('B', question.optionB),
  ];
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _OptionText extends StatelessWidget {
  final String label;
  final String text;
  final ThemeData theme;

  const _OptionText({
    required this.label,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnsweredOption extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrectChoice;
  final bool isWrongChoice;
  final ThemeData theme;

  const _AnsweredOption({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrectChoice,
    required this.isWrongChoice,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = context.appColors.surfaceElevated;
    Color textColor = context.appColors.textSecondary;
    Color labelColor = context.appColors.textHint;

    if (isCorrectChoice) {
      bgColor = context.appColors.success.withValues(alpha: 0.15);
      textColor = context.appColors.success;
      labelColor = context.appColors.success;
    } else if (isWrongChoice) {
      bgColor = context.appColors.error.withValues(alpha: 0.15);
      textColor = context.appColors.error;
      labelColor = context.appColors.error;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: isCorrectChoice
                ? Icon(Icons.check, size: 14, color: labelColor)
                : isWrongChoice
                    ? Icon(Icons.close, size: 14, color: labelColor)
                    : Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
