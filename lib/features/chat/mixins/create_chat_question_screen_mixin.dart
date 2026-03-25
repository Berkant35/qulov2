import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/data/models/chat_question_draft_model.dart';
import 'package:qulo_v2/features/chat/screens/create_chat_question_screen.dart';
import 'package:qulo_v2/features/chat/sheets/draft_history_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';

mixin CreateChatQuestionScreenMixin
    on ConsumerState<CreateChatQuestionScreen> {
  int currentStep = 0;
  bool isLoading = false;

  // Step 1 data
  int optionCount = 2;
  String questionText = '';
  String optionA = '';
  String optionB = '';
  String optionC = '';
  String optionD = '';
  String correctOption = 'A';

  // Step 2 data
  int timeLimitSeconds = 30;
  String hintText = '';
  String? rewardMediaUrl;
  String? rewardMediaType;
  bool hasUnmatchRisk = false;
  bool hasChatLock = false;
  bool hasPowerBlock = false;

  bool get isStep1Valid =>
      questionText.trim().length >= 3 &&
      optionA.trim().isNotEmpty &&
      optionB.trim().isNotEmpty &&
      (optionCount == 2 ||
          (optionC.trim().isNotEmpty && optionD.trim().isNotEmpty));

  void onStep1Changed({
    int? optionCount,
    String? questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
  }) {
    setState(() {
      if (optionCount != null) this.optionCount = optionCount;
      if (questionText != null) this.questionText = questionText;
      if (optionA != null) this.optionA = optionA;
      if (optionB != null) this.optionB = optionB;
      if (optionC != null) this.optionC = optionC;
      if (optionD != null) this.optionD = optionD;
      if (correctOption != null) this.correctOption = correctOption;
    });
  }

  void onStep2Changed({
    int? timeLimitSeconds,
    String? hintText,
    String? rewardMediaUrl,
    String? rewardMediaType,
    bool? hasUnmatchRisk,
    bool? hasChatLock,
    bool? hasPowerBlock,
  }) {
    setState(() {
      if (timeLimitSeconds != null) this.timeLimitSeconds = timeLimitSeconds;
      if (hintText != null) this.hintText = hintText;
      if (rewardMediaUrl != null) this.rewardMediaUrl = rewardMediaUrl;
      if (rewardMediaType != null) this.rewardMediaType = rewardMediaType;
      if (hasUnmatchRisk != null) this.hasUnmatchRisk = hasUnmatchRisk;
      if (hasChatLock != null) this.hasChatLock = hasChatLock;
      if (hasPowerBlock != null) this.hasPowerBlock = hasPowerBlock;
    });
  }

  void onNext() {
    if (isStep1Valid) {
      setState(() => currentStep = 1);
    }
  }

  void onBack() {
    setState(() => currentStep = 0);
  }

  Future<void> onSubmit() async {
    if (!isStep1Valid || isLoading) return;
    setState(() => isLoading = true);

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
              SnackBar(
                  content: Text(
                      '${AppLocalizations.of(context).get('chat_question_send_failed')}: $failure')),
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> onSaveDraft() async {
    if (!isStep1Valid || isLoading) return;
    setState(() => isLoading = true);

    try {
      final data = _buildPayload();
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.saveDraft(data);

      if (mounted) {
        result.when(
          success: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      AppLocalizations.of(context).get('chat_draft_saved'))),
            );
          },
          failure: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '${AppLocalizations.of(context).get('chat_draft_save_failed')}: $failure')),
            );
          },
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final data = <String, dynamic>{
      'question_text': questionText.trim(),
      'option_count': optionCount,
      'option_a': optionA.trim(),
      'option_b': optionB.trim(),
      'correct_option': correctOption,
      'time_limit_seconds': timeLimitSeconds,
      'has_unmatch_risk': hasUnmatchRisk,
      'has_chat_lock': hasChatLock,
      'has_power_block': hasPowerBlock,
    };
    if (optionCount == 4) {
      data['option_c'] = optionC.trim();
      data['option_d'] = optionD.trim();
    }
    if (hintText.trim().isNotEmpty) {
      data['hint_text'] = hintText.trim();
    }
    if (rewardMediaUrl != null) {
      data['reward_media_url'] = rewardMediaUrl;
      data['reward_media_type'] = rewardMediaType;
    }
    return data;
  }

  void showDraftHistory() {
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
      optionCount = draft.optionCount;
      questionText = draft.questionText;
      optionA = draft.optionA;
      optionB = draft.optionB;
      optionC = draft.optionC ?? '';
      optionD = draft.optionD ?? '';
      correctOption = draft.correctOption;
      timeLimitSeconds = draft.timeLimitSeconds;
      hintText = draft.hintText ?? '';
      hasUnmatchRisk = draft.hasUnmatchRisk;
      hasChatLock = draft.hasChatLock;
      currentStep = 0;
    });
  }
}
