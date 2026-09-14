import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/quiz_summary_provider.dart';
import 'package:qulo_v2/features/chat/mixins/chat_screen_mixin.dart';
import 'package:qulo_v2/features/chat/mixins/chat_realtime_mixin.dart';
import 'package:qulo_v2/features/chat/mixins/chat_media_mixin.dart';
import 'package:qulo_v2/features/chat/mixins/chat_moderation_mixin.dart';
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

class _ChatScreenState extends ConsumerState<ChatScreen>
    with ChatScreenMixin, ChatRealtimeMixin, ChatMediaMixin, ChatModerationMixin {
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
    // Yalniz bu sohbetin karsi tarafi izlenir: baska eslesmenin son mesaji
    // degisince ekran yeniden kurulmaz (MatchUserModel deger esitligi tasir).
    final matchUser = ref.watch(
      matchListProvider.select((s) => matchUserIn(s.valueOrNull)),
    );
    final chatData = chatState.valueOrNull;
    final mediaEnabled = chatData?.mediaEnabled ?? false;
    final pendingRequest = chatData?.pendingMediaRequest;
    final isChatLocked = chatData?.isLockedFor(
          currentUserId: myId ?? '',
          questionCache: ref.watch(chatQuestionCacheProvider),
        ) ??
        false;

    // Raw Scaffold: the AppBar carries a custom title and a `bottom` media
    // request banner, which AppScaffold's title-only AppBar can't express.
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: ChatAppBarTitle(
          userName: matchUser?.name ?? context.tr('chat'),
          isOnline: matchUser?.isOnline ?? false,
          statusText: statusTextFor(matchUser),
          photoUrl: matchUser?.photos?.firstOrNull,
          onTap: matchUser == null ? null : () => openMatchProfile(matchUser),
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
                onAccept: () => respondToMediaRequest(pendingRequest.id, accept: true),
                onReject: () => respondToMediaRequest(pendingRequest.id, accept: false),
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
