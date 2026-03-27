import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/mixins/solve_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_result.dart';
import 'package:qulo_v2/features/chat/widgets/solve_question_body.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';

class SolveChatQuestionScreen extends ConsumerStatefulWidget {
  final ChatQuestionModel question;
  final String matchId;

  const SolveChatQuestionScreen({
    super.key,
    required this.question,
    required this.matchId,
  });

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

    // Task 2: Power inventory counts
    final exchange = ref.watch(exchangeProvider);
    final powerCounts = <String, int>{};
    for (final type in PowerType.values) {
      final c = exchange.getCount(type.apiName);
      if (c > 0) powerCounts[type.apiName] = c;
    }

    // Task 3: Diamond balance
    final diamonds = ref.watch(diamondProvider);
    final balance = diamonds.valueOrNull;

    // Task 4: Sender profile info
    final matchUser = ref.watch(matchListProvider).whenData((matches) {
      try {
        return matches.firstWhere((m) => m.matchId == widget.matchId).user;
      } catch (_) {
        return null;
      }
    }).valueOrNull;
    final senderPhotoUrl = matchUser?.photos?.isNotEmpty == true ? matchUser!.photos!.first : null;
    final senderName = matchUser?.name;

    return PopScope(
      canPop: false,
      child: AppScaffold(
        title: q.questionText.length > 25
            ? '${q.questionText.substring(0, 25)}...'
            : q.questionText,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (balance != null)
            _CompactDiamondBalance(purple: balance.purple, green: balance.green),
        ],
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
          powerCounts: powerCounts,
          senderPhotoUrl: senderPhotoUrl,
          senderName: senderName,
        ),
      ),
    );
  }
}

class _CompactDiamondBalance extends StatelessWidget {
  final int purple;
  final int green;

  const _CompactDiamondBalance({
    required this.purple,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DiamondIcon.purple(size: 14, showGlow: false),
          const SizedBox(width: 2),
          Text(
            '$purple',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.sm),
          const DiamondIcon.green(size: 14, showGlow: false),
          const SizedBox(width: 2),
          Text(
            '$green',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
