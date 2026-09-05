import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/features/chat/coach/chat_question_coach_marks.dart';
import 'package:qulo_v2/core/services/one_time_flag_store.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/features/chat/screens/chat_screen.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Chat ekraninin ortak state'i ve yasam dongusu: metin/scroll kontrolcusu,
/// quiz ozeti kapatma, mesaj gonderme, soru sayfasi ve eslesmeyi bozma.
///
/// Alan bazli akislar alt mixin'lere ayrildi (tek dosya 677 satirdi, limit 300):
/// `ChatRealtimeMixin`, `ChatMediaMixin`, `ChatModerationMixin`. Ayni bolme
/// deseni `ChatQuestionPowerMixin` / `QuizPowerMixin` tarafinda da var.
mixin ChatScreenMixin on ConsumerState<ChatScreen> {

  final msgCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  bool disposed = false;
  final Stopwatch _chatStopwatch = Stopwatch()..start();
  int messagesSentCount = 0;
  bool hasText = false;
  bool quizSummaryDismissed = false;

  // ─── Alt Mixin Kancalari ───

  /// Realtime abonelikleri (mesaj + typing + medya) — `ChatRealtimeMixin` uygular.
  void subscribeRealtime();

  /// Realtime kanallari ve debounce timer'larini kapatir — `ChatRealtimeMixin` uygular.
  void disposeRealtime();

  // ─── Lifecycle ───

  void initMixin() {
    msgCtrl.addListener(_onTextChanged);
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatOpen,
      params: {AnalyticsEvents.paramChatId: widget.matchId},
    );
    scrollCtrl.addListener(_onScroll);
    _loadQuizSummaryDismissState();
    Future.microtask(() {
      // Aktif chat'i isaretle — in-app banner suppress icin
      ref.read(activeChatMatchIdProvider.notifier).state = widget.matchId;
      // Clear question cache so cards re-fetch fresh data
      ref.read(chatQuestionCacheProvider.notifier).state = {};
      ref.read(openedQuestionIdsProvider.notifier).state = {};

      final notifier = ref.read(chatProvider(widget.matchId).notifier);
      notifier.loadMessages();
      notifier.markAsRead();
      ref.read(matchListProvider.notifier).clearUnreadCount(widget.matchId);
      notifier.loadMediaStatus();
      subscribeRealtime();
      // Question updates handled via FCM (NotificationNotifier)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CoachMarkService.instance.maybeStartTour(
          context,
          tourId: 'chat_question',
          steps: buildChatQuestionCoachSteps(),
        );
      });
    });
  }

  void disposeMixin() {
    disposed = true;
    _chatStopwatch.stop();
    // Prevent orphaned overlay if chat is popped while coach-mark is open.
    CoachMarkService.instance.forceClose();
    // Aktif chat'i temizle — guard against disposed ref
    try {
      ref.read(activeChatMatchIdProvider.notifier).state = null;
    } catch (_) {}
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatClose,
      params: {
        AnalyticsEvents.paramChatId: widget.matchId,
        AnalyticsEvents.paramDurationMs: _chatStopwatch.elapsedMilliseconds,
        AnalyticsEvents.paramMessagesSent: messagesSentCount,
      },
    );
    disposeRealtime();
    msgCtrl.removeListener(_onTextChanged);
    scrollCtrl.removeListener(_onScroll);
    scrollCtrl.dispose();
    msgCtrl.dispose();
  }

  // ─── Text Listener ───

  void _onTextChanged() {
    final newHasText = msgCtrl.text.trim().isNotEmpty;
    if (newHasText != hasText) {
      setState(() => hasText = newHasText);
    }
  }

  // ─── Scroll ───

  void _onScroll() {
    if (!scrollCtrl.hasClients) return;
    final maxScroll = scrollCtrl.position.maxScrollExtent;
    final currentScroll = scrollCtrl.position.pixels;
    if (maxScroll - currentScroll < 200) {
      final notifier = ref.read(chatProvider(widget.matchId).notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  void scrollToBottom() {
    if (scrollCtrl.hasClients) {
      scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ─── Quiz Summary ───

  String get _quizSummaryDismissKey =>
      'quiz_summary_dismissed_${widget.matchId}';

  Future<void> _loadQuizSummaryDismissState() async {
    final dismissed = await OneTimeFlagStore.isSet(_quizSummaryDismissKey);
    if (dismissed && mounted) {
      setState(() => quizSummaryDismissed = true);
    }
  }

  Future<void> dismissQuizSummary() async {
    setState(() => quizSummaryDismissed = true);
    await OneTimeFlagStore.mark(_quizSummaryDismissKey);
  }

  // ─── Send Message ───

  Future<void> send() async {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return;
    msgCtrl.clear();
    await ref.read(chatProvider(widget.matchId).notifier).sendMessage(text);
    messagesSentCount++;
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatMessageSend,
      params: {
        AnalyticsEvents.paramChatId: widget.matchId,
        AnalyticsEvents.paramType: 'text',
        AnalyticsEvents.paramCharCount: text.length,
      },
    );
  }

  // ─── Question Screen ───

  Future<void> showCreateQuestionSheet() async {
    final result = await ref.read(navigationServiceProvider).push<bool>(
      RouteNames.createChatQuestion,
      params: {'matchId': widget.matchId},
    );
    if (result == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    }
  }

  // ─── Unmatch ───

  Future<void> confirmUnmatch() async {
    final nav = ref.read(navigationServiceProvider);
    final confirm = await nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'unmatch',
        title: context.tr('unmatch'),
        message: context.tr('chat_unmatch_confirm'),
        confirmText: context.tr('unmatch'),
        isDestructive: true,
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(matchListProvider.notifier).unmatch(widget.matchId);
      if (mounted) {
        ref.read(navigationServiceProvider).pop();
      }
    }
  }

  // ─── Helpers ───

  String formatLastSeen(String? lastSeen) {
    final dt = lastSeen == null ? null : DateTime.tryParse(lastSeen);
    if (dt == null) return '';
    return context.fmt.lastSeen(dt);
  }

  Map<String, int> groupReactions(List<MessageReaction> reactions) {
    final map = <String, int>{};
    for (final r in reactions) {
      map[r.emoji] = (map[r.emoji] ?? 0) + 1;
    }
    return map;
  }
}
