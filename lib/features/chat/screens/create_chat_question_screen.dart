import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/chat/mixins/create_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_step1.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_step2.dart';
import 'package:qulo_v2/features/chat/widgets/create_question_bottom_buttons.dart';
import 'package:qulo_v2/features/chat/widgets/create_question_step_indicator.dart';

class CreateChatQuestionScreen extends ConsumerStatefulWidget {
  final String matchId;

  const CreateChatQuestionScreen({super.key, required this.matchId});

  @override
  ConsumerState<CreateChatQuestionScreen> createState() =>
      _CreateChatQuestionScreenState();
}

class _CreateChatQuestionScreenState
    extends ConsumerState<CreateChatQuestionScreen>
    with CreateChatQuestionScreenMixin {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.tr('create_question'),
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: context.tr('drafts_history'),
          onPressed: showDraftHistory,
        ),
      ],
      body: Column(
        children: [
          CreateQuestionStepIndicator(currentStep: currentStep),
          Expanded(
            child: currentStep == 0
                ? ChatQuestionStep1(
                    optionCount: optionCount,
                    questionText: questionText,
                    optionA: optionA,
                    optionB: optionB,
                    optionC: optionC,
                    optionD: optionD,
                    correctOption: correctOption,
                    onChanged: onStep1Changed,
                  )
                : ChatQuestionStep2(
                    matchId: widget.matchId,
                    timeLimitSeconds: timeLimitSeconds,
                    hintText: hintText,
                    rewardMediaUrl: rewardMediaUrl,
                    rewardMediaType: rewardMediaType,
                    hasUnmatchRisk: hasUnmatchRisk,
                    hasChatLock: hasChatLock,
                    hasPowerBlock: hasPowerBlock,
                    onChanged: onStep2Changed,
                  ),
          ),
          CreateQuestionBottomButtons(
            currentStep: currentStep,
            isLoading: isLoading,
            isStep1Valid: isStep1Valid,
            onNext: onNext,
            onBack: onBack,
            onSubmit: onSubmit,
            onSaveDraft: onSaveDraft,
          ),
        ],
      ),
    );
  }
}
