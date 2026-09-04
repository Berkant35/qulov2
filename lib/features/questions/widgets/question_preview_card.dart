import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

class QuestionPreviewCard extends StatefulWidget {
  final String questionText;
  final String answer1;
  final String answer2;
  final String answer3;
  final String answer4;
  final int correctAnswer;
  final String? category;
  final int timeLimit;
  final String? hintText;

  const QuestionPreviewCard({
    super.key,
    required this.questionText,
    required this.answer1,
    required this.answer2,
    required this.answer3,
    required this.answer4,
    required this.correctAnswer,
    this.category,
    this.timeLimit = 30,
    this.hintText,
  });

  @override
  State<QuestionPreviewCard> createState() => _QuestionPreviewCardState();
}

class _QuestionPreviewCardState extends State<QuestionPreviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final answers = [widget.answer1, widget.answer2, widget.answer3, widget.answer4];

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Preview label + badges + toggle
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  context.tr('question_create_preview'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.appColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: context.appColors.primary,
                  ),
                ),
                const Spacer(),
                if (widget.category != null) ...[
                  _CategoryBadge(category: widget.category!),
                  const SizedBox(width: AppSpacing.xs),
                ],
                _TimeBadge(timeLimit: widget.timeLimit),
                if (widget.hintText != null && widget.hintText!.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  QIcon(QIcons.icLightbulb, size: 14, color: context.appColors.warning),
                ],
              ],
            ),
          ),

          // Collapsible content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                // Question text
                Text(
                  widget.questionText.isEmpty ? '...' : widget.questionText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.questionText.isEmpty ? context.appColors.textHint : null,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                // Answer pills — 2x2 grid
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: List.generate(4, (i) {
                    final isCorrect = i + 1 == widget.correctAnswer;
                    final text = answers[i];
                    return _AnswerPill(
                      label: text.isEmpty ? '...' : text,
                      isCorrect: isCorrect,
                      isEmpty: text.isEmpty,
                    );
                  }),
                ),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.appColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        context.tr('question_category_$category'),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.appColors.primary,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final int timeLimit;
  const _TimeBadge({required this.timeLimit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QIcon(QIcons.icClock, size: 10, color: context.appColors.textSecondary),
          const SizedBox(width: 3),
          Text(
            context.fmt.seconds(timeLimit),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.appColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerPill extends StatelessWidget {
  final String label;
  final bool isCorrect;
  final bool isEmpty;

  const _AnswerPill({
    required this.label,
    required this.isCorrect,
    this.isEmpty = false,
  });

  Color _textColor(BuildContext context) {
    if (isEmpty) return context.appColors.textHint;
    if (isCorrect) return context.appColors.secondary;
    return context.appColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isCorrect
            ? context.appColors.secondary.withValues(alpha: 0.15)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isCorrect
              ? context.appColors.secondary.withValues(alpha: 0.5)
              : context.appColors.border,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _textColor(context),
          fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
