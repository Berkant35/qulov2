import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/mixins/solve_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_result.dart';
import 'package:qulo_v2/features/chat/widgets/solve_question_body.dart';

class SolveChatQuestionScreen extends ConsumerStatefulWidget {
  final ChatQuestionModel question;

  const SolveChatQuestionScreen({super.key, required this.question});

  @override
  ConsumerState<SolveChatQuestionScreen> createState() =>
      _SolveChatQuestionScreenState();
}

class _SolveChatQuestionScreenState
    extends ConsumerState<SolveChatQuestionScreen>
    with SolveChatQuestionScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (answered && result != null) {
      return ChatQuestionResultScreen(
        result: result!,
        question: widget.question,
        onRescue: !result!.isCorrect ? handleRescue : null,
      );
    }

    final q = widget.question;

    return PopScope(
      canPop: false,
      child: AppScaffold(
        title: q.questionText.length > 25
            ? '${q.questionText.substring(0, 25)}...'
            : q.questionText,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        padding: EdgeInsets.zero,
        body: SolveQuestionBody(
          question: q,
          timerKey: timerKey,
          selectedOption: selectedOption,
          isSubmitting: isSubmitting,
          removedOptions: removedOptions,
          suggestedOption: suggestedOption,
          hintVisible: hintVisible,
          hintText: hintText,
          powerBlockActive: powerBlockActive,
          onTimeout: onTimeout,
          onOptionSelected: selectOption,
          onSubmit: submitAnswer,
          onPowerTap: usePower,
        ),
      ),
    );
  }
}
