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
import 'package:qulo_v2/features/chat/widgets/chat_popup_menu.dart';
import 'package:qulo_v2/features/chat/widgets/chat_message_list.dart';
import 'package:qulo_v2/features/chat/widgets/quiz_summary_card.dart';
import 'package:qulo_v2/features/chat/widgets/typing_indicator.dart';
import 'package:qulo_v2/features/chat/widgets/chat_lock_banner.dart';
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
    final chatData = chatState.valueOrNull;
    final mediaEnabled = chatData?.mediaEnabled ?? false;
    final pendingRequest = chatData?.pendingMediaRequest;

    // Derive chat-lock state from the question cache
    final questionCache = ref.watch(chatQuestionCacheProvider);
    const qPrefix = '__QUESTION__:';
    final isChatLocked = chatData?.messages.any((msg) {
          if (!msg.content.startsWith(qPrefix)) return false;
          final qId = msg.content.replaceFirst(qPrefix, '');
          final question = questionCache[qId];
          if (question == null) return false;
          return question.hasChatLock &&
              !question.isAnswered &&
              question.senderId != (myId ?? '');
        }) ??
        false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: ChatAppBarTitle(
          userName: userName,
          isOnline: isOnline,
          statusText: statusText,
          photoUrl: matchUser?.photos?.isNotEmpty == true ? matchUser!.photos!.first : null,
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
          ChatPopupMenu(
            mediaEnabled: mediaEnabled,
            onReport: onChatReport,
            onBlock: onChatBlock,
            onUnmatch: confirmUnmatch,
            onMediaDisable: mediaEnabled ? handleDisableMedia : null,
          ),
        ],
        bottom: pendingRequest != null
            ? MediaRequestBanner(
                request: pendingRequest,
                currentUserId: myId ?? '',
                onAccept: () => ref
                    .read(chatProvider(widget.matchId).notifier)
                    .respondToMediaRequest(pendingRequest.id, 'accept'),
                onReject: () => ref
                    .read(chatProvider(widget.matchId).notifier)
                    .respondToMediaRequest(pendingRequest.id, 'reject'),
              )
            : null,
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

          // Chat lock banner
          if (isChatLocked) const ChatLockBanner(),

          // Voice Recorder or Input Bar
          if (isRecording)
            VoiceRecorderOverlay(
              onRecordComplete: handleVoiceComplete,
              onCancel: cancelVoiceRecording,
            )
          else
            ChatInputBar(
              controller: msgCtrl,
              hasText: hasText && !isChatLocked,
              onSend: isChatLocked ? () {} : send,
              onPhotoTap: isChatLocked ? () {} : handlePhotoTap,
              onQuestionTap: showCreateQuestionSheet,
              onVoiceStart: isChatLocked ? () {} : startVoiceRecording,
              onChanged: isChatLocked ? (_) {} : (_) => sendTypingEvent(),
              isLocked: isChatLocked,
            ),
        ],
      ),
    );
  }
}
