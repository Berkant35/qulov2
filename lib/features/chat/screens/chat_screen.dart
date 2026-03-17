import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/quiz_summary_provider.dart';
import 'package:qulo_v2/features/chat/mixins/chat_screen_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';
import 'package:qulo_v2/features/chat/widgets/chat_app_bar_content.dart';
import 'package:qulo_v2/features/chat/widgets/chat_input_bar.dart';
import 'package:qulo_v2/features/chat/widgets/chat_message_list.dart';
import 'package:qulo_v2/features/chat/widgets/quiz_summary_card.dart';
import 'package:qulo_v2/features/chat/widgets/typing_indicator.dart';
import 'package:qulo_v2/features/chat/widgets/voice_recorder_overlay.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  const ChatScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with ChatScreenMixin {
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
    final chatState = ref.watch(chatProvider(widget.matchId));
    final myId = ref.watch(authProvider).userId;
    final theme = Theme.of(context);
    final quizSummary = ref.watch(quizSummaryProvider(widget.matchId));

    // Match user info for header
    final matchUser = ref.watch(matchListProvider).whenData((matches) {
      try {
        return matches.firstWhere((m) => m.matchId == widget.matchId).user;
      } catch (_) {
        return null;
      }
    }).valueOrNull;

    final userName = matchUser?.name ?? context.tr('chat');
    final isOnline = matchUser?.isOnline ?? false;
    final lastSeen = matchUser?.lastSeen;
    final statusText = isOnline ? 'Online' : formatLastSeen(lastSeen);
    final mediaEnabled =
        ref.read(chatProvider(widget.matchId)).valueOrNull?.mediaEnabled ??
            false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: ChatAppBarTitle(
          userName: userName,
          isOnline: isOnline,
          statusText: statusText,
          onTap: matchUser != null
              ? () => ref.read(navigationServiceProvider).push(
                    RouteNames.profileDetail,
                    params: {'userId': matchUser.userId},
                    extra: ProfileDetailArgs(
                      context: ProfileDetailContext.chat,
                      userId: matchUser.userId,
                      matchId: widget.matchId,
                    ),
                  )
              : null,
        ),
        actions: [
          ChatAppBarActions(
            mediaEnabled: mediaEnabled,
            onUnmatch: confirmUnmatch,
            onMediaDisable: handleDisableMedia,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quiz Summary Card
          if (!quizSummaryDismissed)
            quizSummary.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) {
                if (summary == null) return const SizedBox.shrink();
                return QuizSummaryCard(
                  summary: summary,
                  currentUserId: myId ?? '',
                  onDismiss: dismissQuizSummary,
                );
              },
            ),

          // Message List
          Expanded(
            child: ChatMessageList(
              chatState: chatState,
              scrollCtrl: scrollCtrl,
              myId: myId,
              matchId: widget.matchId,
              onLongPress: showMessageMenu,
              groupReactions: groupReactions,
            ),
          ),

          // Typing Indicator
          if (isOtherTyping)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.pagePadding,
                bottom: AppSpacing.xs,
              ),
              child: const TypingIndicator(),
            ),

          // Voice Recorder or Input Bar
          if (isRecording)
            VoiceRecorderOverlay(
              onRecordComplete: handleVoiceComplete,
              onCancel: cancelVoiceRecording,
            )
          else
            ChatInputBar(
              controller: msgCtrl,
              hasText: hasText,
              onSend: send,
              onPhotoTap: handlePhotoTap,
              onQuestionTap: showCreateQuestionSheet,
              onVoiceStart: startVoiceRecording,
              onChanged: (_) => sendTypingEvent(),
            ),
        ],
      ),
    );
  }
}
