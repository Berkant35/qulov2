import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

/// Editable preview of AI-suggested questions. User can rewrite the question
/// text, edit any of the 4 answers, and re-select the correct answer before
/// committing via "Sorularımı Ata". Outgoing payload mirrors the AI suggest
/// shape (`question_text`, `answers: [4]`, `correct_answer: 1..4`, plus the
/// original `hint` / `category` pass-through).
///
/// Loaders for the underlying async assignment live on the gate screen
/// (`AppScaffold.isLoading: isProcessing`), not on these CTAs — the sheet
/// pops before the network call starts.
class SetupAiPreviewSheet extends StatefulWidget {
  final List<Map<String, dynamic>> suggestions;
  final void Function(List<Map<String, dynamic>> edited) onAssign;
  final VoidCallback onRegenerate;
  final VoidCallback onSkip;

  const SetupAiPreviewSheet({
    super.key,
    required this.suggestions,
    required this.onAssign,
    required this.onRegenerate,
    required this.onSkip,
  });

  @override
  State<SetupAiPreviewSheet> createState() => _SetupAiPreviewSheetState();
}

class _SetupAiPreviewSheetState extends State<SetupAiPreviewSheet> {
  late List<_EditableSuggestion> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = widget.suggestions.map(_EditableSuggestion.fromMap).toList();
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _handleAssign() {
    widget.onAssign(_drafts.map((d) => d.toMap()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.hintColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('preview_sheet_title'),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ..._drafts.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _SuggestionEditor(
                  draft: d,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.tr('preview_sheet_assign_cta'),
              onPressed: _handleAssign,
              fullWidth: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: context.tr('preview_sheet_regen_cta'),
              onPressed: widget.onRegenerate,
              variant: AppButtonVariant.secondary,
              fullWidth: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: widget.onSkip,
              child: Text(
                context.tr('preview_sheet_skip_link'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Holds the user-editable state for a single AI suggestion.
class _EditableSuggestion {
  final TextEditingController questionCtrl;
  final List<TextEditingController> answerCtrls;
  int correctIdx; // 1-indexed to match server contract
  final String? hint;
  final String? category;

  _EditableSuggestion({
    required this.questionCtrl,
    required this.answerCtrls,
    required this.correctIdx,
    required this.hint,
    required this.category,
  });

  factory _EditableSuggestion.fromMap(Map<String, dynamic> s) {
    final answers = (s['answers'] as List?) ?? const [];
    final padded = List.generate(
      4,
      (i) => i < answers.length ? answers[i].toString() : '',
    );
    return _EditableSuggestion(
      questionCtrl: TextEditingController(text: (s['question_text'] ?? '') as String),
      answerCtrls: padded.map((a) => TextEditingController(text: a)).toList(),
      correctIdx: (s['correct_answer'] as int?) ?? 1,
      hint: s['hint'] as String?,
      category: s['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'question_text': questionCtrl.text,
        'answers': answerCtrls.map((c) => c.text).toList(),
        'correct_answer': correctIdx,
        'hint': hint,
        'category': category,
      };

  void dispose() {
    questionCtrl.dispose();
    for (final c in answerCtrls) {
      c.dispose();
    }
  }
}

class _SuggestionEditor extends StatelessWidget {
  final _EditableSuggestion draft;
  final VoidCallback onChanged;

  const _SuggestionEditor({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: draft.questionCtrl,
            maxLines: null,
            style: theme.textTheme.titleMedium,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Divider(height: AppSpacing.lg),
          ...List.generate(4, (idx) {
            final isCorrect = idx + 1 == draft.correctIdx;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      draft.correctIdx = idx + 1;
                      onChanged();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isCorrect ? Icons.check_circle : Icons.circle_outlined,
                        size: 22,
                        color: isCorrect
                            ? colors.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: draft.answerCtrls[idx],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isCorrect
                            ? colors.primary
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            isCorrect ? FontWeight.w600 : FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: '${idx + 1}',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
