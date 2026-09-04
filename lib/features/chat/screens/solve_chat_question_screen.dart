import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/compact_diamond_balance.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/mixins/chat_question_power_mixin.dart';
import 'package:qulo_v2/features/chat/mixins/solve_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_result.dart';
import 'package:qulo_v2/features/chat/widgets/solve_question_body.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
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
    with SolveChatQuestionScreenMixin, ChatQuestionPowerMixin {
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
        powerUsages: powerUsages,
      );
    }

    final q = widget.question;

    // Power inventory counts (from exchange)
    final exchange = ref.watch(exchangeProvider);
    final powerCounts = <String, int>{};
    for (final entry in exchange.inventory) {
      if (entry.count > 0) powerCounts[entry.powerName] = entry.count;
    }

    // Power costs (from economy config — loaded at app start)
    final economyConfig = ref.watch(economyConfigProvider);
    final powerCosts = economyConfig.powerCosts;

    // Sender profile info
    final matchUser = ref.watch(matchListProvider).whenData((matches) {
      try {
        return matches.firstWhere((m) => m.matchId == widget.matchId).user;
      } catch (_) {
        return null;
      }
    }).valueOrNull;
    final senderPhotoUrl = matchUser?.photos?.isNotEmpty == true
        ? matchUser!.photos!.first
        : null;
    final senderName = matchUser?.name;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleBackPress();
      },
      child: AppScaffold(
        title: senderName ?? '',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: handleBackPress,
        ),
        actions: const [CompactDiamondBalance()],
        padding: EdgeInsets.zero,
        body: Stack(
          children: [
            // Background: sender photo with low opacity
            if (senderPhotoUrl != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.08,
                  child: CachedNetworkImage(
                    imageUrl: senderPhotoUrl,
                    fit: BoxFit.cover,
                    // %8 opaklikta arka plan — tam cozunurluk bellekte bosuna durur
                    memCacheWidth: 540,
                  ),
                ),
              ),
            // Foreground: question body
            SolveQuestionBody(
              question: q,
              timerKey: timerKey,
              selectedOption: selectedOption,
              isSubmitting: isSubmitting,
              removedOptions: removedOptions,
              suggestedOption: suggestedOption,
              hintVisible: hintVisible,
              usedPowers: usedPowers,
              hintText: hintText,
              powerBlockActive: powerBlockActive,
              onTimeout: onTimeout,
              onOptionSelected: selectOption,
              onSubmit: submitAnswer,
              onPowerTap: usePower,
              powerCounts: powerCounts,
              powerCosts: powerCosts,
              senderPhotoUrl: senderPhotoUrl,
              senderName: senderName,
            ),
          ],
        ),
      ),
    );
  }
}
