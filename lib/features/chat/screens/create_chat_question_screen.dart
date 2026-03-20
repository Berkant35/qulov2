import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/data/models/chat_question_draft_model.dart';
import 'package:qulo_v2/features/chat/sheets/draft_history_sheet.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_step1.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_step2.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';

class CreateChatQuestionScreen extends ConsumerStatefulWidget {
  final String matchId;

  const CreateChatQuestionScreen({super.key, required this.matchId});

  @override
  ConsumerState<CreateChatQuestionScreen> createState() =>
      _CreateChatQuestionScreenState();
}

class _CreateChatQuestionScreenState
    extends ConsumerState<CreateChatQuestionScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1 data
  int _optionCount = 2;
  String _questionText = '';
  String _optionA = '';
  String _optionB = '';
  String _optionC = '';
  String _optionD = '';
  String _correctOption = 'A';

  // Step 2 data
  int _timeLimitSeconds = 30;
  String _hintText = '';
  String? _rewardMediaUrl;
  String? _rewardMediaType;
  bool _hasUnmatchRisk = false;
  bool _hasChatLock = false;
  bool _hasPowerBlock = false;

  bool get _isStep1Valid =>
      _questionText.trim().length >= 3 &&
      _optionA.trim().isNotEmpty &&
      _optionB.trim().isNotEmpty &&
      (_optionCount == 2 ||
          (_optionC.trim().isNotEmpty && _optionD.trim().isNotEmpty));

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Soru Olustur',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Taslaklar & Gecmis',
          onPressed: _showDraftHistory,
        ),
      ],
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: _currentStep),
          // Step content
          Expanded(
            child: _currentStep == 0
                ? ChatQuestionStep1(
                    optionCount: _optionCount,
                    questionText: _questionText,
                    optionA: _optionA,
                    optionB: _optionB,
                    optionC: _optionC,
                    optionD: _optionD,
                    correctOption: _correctOption,
                    onChanged: _onStep1Changed,
                  )
                : ChatQuestionStep2(
                    matchId: widget.matchId,
                    timeLimitSeconds: _timeLimitSeconds,
                    hintText: _hintText,
                    rewardMediaUrl: _rewardMediaUrl,
                    rewardMediaType: _rewardMediaType,
                    hasUnmatchRisk: _hasUnmatchRisk,
                    hasChatLock: _hasChatLock,
                    hasPowerBlock: _hasPowerBlock,
                    onChanged: _onStep2Changed,
                  ),
          ),
          // Bottom buttons
          _BottomButtons(
            currentStep: _currentStep,
            isLoading: _isLoading,
            isStep1Valid: _isStep1Valid,
            onNext: _onNext,
            onBack: _onBack,
            onSubmit: _onSubmit,
            onSaveDraft: _onSaveDraft,
          ),
        ],
      ),
    );
  }

  void _onStep1Changed({
    int? optionCount,
    String? questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
  }) {
    setState(() {
      if (optionCount != null) _optionCount = optionCount;
      if (questionText != null) _questionText = questionText;
      if (optionA != null) _optionA = optionA;
      if (optionB != null) _optionB = optionB;
      if (optionC != null) _optionC = optionC;
      if (optionD != null) _optionD = optionD;
      if (correctOption != null) _correctOption = correctOption;
    });
  }

  void _onStep2Changed({
    int? timeLimitSeconds,
    String? hintText,
    String? rewardMediaUrl,
    String? rewardMediaType,
    bool? hasUnmatchRisk,
    bool? hasChatLock,
    bool? hasPowerBlock,
  }) {
    setState(() {
      if (timeLimitSeconds != null) _timeLimitSeconds = timeLimitSeconds;
      if (hintText != null) _hintText = hintText;
      if (rewardMediaUrl != null) _rewardMediaUrl = rewardMediaUrl;
      if (rewardMediaType != null) _rewardMediaType = rewardMediaType;
      if (hasUnmatchRisk != null) _hasUnmatchRisk = hasUnmatchRisk;
      if (hasChatLock != null) _hasChatLock = hasChatLock;
      if (hasPowerBlock != null) _hasPowerBlock = hasPowerBlock;
    });
  }

  void _onNext() {
    if (_isStep1Valid) {
      setState(() => _currentStep = 1);
    }
  }

  void _onBack() {
    setState(() => _currentStep = 0);
  }

  Future<void> _onSubmit() async {
    if (!_isStep1Valid || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final data = _buildPayload();
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.createQuestion(widget.matchId, data);

      result.when(
        success: (question) {
          ref.read(chatQuestionCacheProvider.notifier).update((state) => {
                ...state,
                question.id: question,
              });
          ref.invalidate(diamondProvider);
          ref.read(chatProvider(widget.matchId).notifier).loadMessages();

          if (mounted) {
            ref.read(navigationServiceProvider).pop(true);
          }
        },
        failure: (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppLocalizations.of(context).get('chat_question_send_failed')}: $failure')),
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSaveDraft() async {
    if (!_isStep1Valid || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final data = _buildPayload();
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.saveDraft(data);

      if (mounted) {
        result.when(
          success: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).get('chat_draft_saved'))),
            );
          },
          failure: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppLocalizations.of(context).get('chat_draft_save_failed')}: $failure')),
            );
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final data = <String, dynamic>{
      'question_text': _questionText.trim(),
      'option_count': _optionCount,
      'option_a': _optionA.trim(),
      'option_b': _optionB.trim(),
      'correct_option': _correctOption,
      'time_limit_seconds': _timeLimitSeconds,
      'has_unmatch_risk': _hasUnmatchRisk,
      'has_chat_lock': _hasChatLock,
      'has_power_block': _hasPowerBlock,
    };
    if (_optionCount == 4) {
      data['option_c'] = _optionC.trim();
      data['option_d'] = _optionD.trim();
    }
    if (_hintText.trim().isNotEmpty) {
      data['hint_text'] = _hintText.trim();
    }
    if (_rewardMediaUrl != null) {
      data['reward_media_url'] = _rewardMediaUrl;
      data['reward_media_type'] = _rewardMediaType;
    }
    return data;
  }

  void _showDraftHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (_) => DraftHistorySheet(
        onDraftSelected: _fillFromDraft,
      ),
    );
  }

  void _fillFromDraft(ChatQuestionDraftModel draft) {
    setState(() {
      _optionCount = draft.optionCount;
      _questionText = draft.questionText;
      _optionA = draft.optionA;
      _optionB = draft.optionB;
      _optionC = draft.optionC ?? '';
      _optionD = draft.optionD ?? '';
      _correctOption = draft.correctOption;
      _timeLimitSeconds = draft.timeLimitSeconds;
      _hintText = draft.hintText ?? '';
      _hasUnmatchRisk = draft.hasUnmatchRisk;
      _hasChatLock = draft.hasChatLock;
      _currentStep = 0;
    });
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: currentStep >= 1
                    ? AppColors.primary
                    : AppColors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButtons extends StatelessWidget {
  final int currentStep;
  final bool isLoading;
  final bool isStep1Valid;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraft;

  const _BottomButtons({
    required this.currentStep,
    required this.isLoading,
    required this.isStep1Valid,
    required this.onNext,
    required this.onBack,
    required this.onSubmit,
    required this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        top: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: currentStep == 0
          ? _buildStep1Buttons(theme)
          : _buildStep2Buttons(theme),
    );
  }

  Widget _buildStep1Buttons(ThemeData theme) {
    final enabled = isStep1Valid && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryButtonGradient : null,
          color: enabled ? null : AppColors.textHint.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: MaterialButton(
          onPressed: enabled ? onNext : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            'Ileri',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Buttons(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient:
                  !isLoading ? AppColors.primaryButtonGradient : null,
              color: isLoading
                  ? AppColors.textHint.withValues(alpha: 0.3)
                  : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: MaterialButton(
              onPressed: !isLoading ? onSubmit : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: isLoading
                  ? const AppLoadingWidget.small()
                  : Text(
                      'Gonder',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Row with Back + Save Draft
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: !isLoading ? onBack : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Geri',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: !isLoading ? onSaveDraft : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Taslak Kaydet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
