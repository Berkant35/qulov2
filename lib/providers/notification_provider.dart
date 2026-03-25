import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/notification_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/chat_provider.dart' show chatQuestionCacheProvider, activeChatMatchIdProvider;
import 'package:qulo_v2/providers/user_provider.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

  Future<void> init() async {
    dev.log('[NotificationNotifier] init() started', name: 'Notification');
    try {
      final manager = ref.read(notificationManagerProvider);

      // Set callbacks BEFORE init so we don't miss token refresh events
      manager.setCallbacks(
        onTokenRefresh: (newToken) {
          dev.log('[NotificationNotifier] Token refreshed, sending to backend', name: 'Notification');
          ref.read(userProvider.notifier).updatePushToken(newToken);
        },
        onForegroundMessage: _handleForegroundMessage,
        onMessageOpenedApp: _handleMessageTap,
        shouldSuppress: _shouldSuppressBanner,
      );

      await manager.init();

      // Send token to backend
      final token = manager.token;
      dev.log('[NotificationNotifier] FCM token: ${token != null ? "OK (${token.substring(0, 20)}...)" : "NULL — will arrive via onTokenRefresh"}', name: 'Notification');

      if (token != null) {
        dev.log('[NotificationNotifier] Sending token to backend...', name: 'Notification');
        await ref.read(userProvider.notifier).updatePushToken(token);
        dev.log('[NotificationNotifier] Token sent to backend ✓', name: 'Notification');
      }

      // Check if app was opened via notification from terminated state (one-time)
      final initialMessage = await manager.getInitialMessage();
      if (initialMessage != null) {
        dev.log('[NotificationNotifier] App opened from terminated notification', name: 'Notification');
        _handleMessageTap(initialMessage);
      }

      dev.log('[NotificationNotifier] FCM setup complete ✓', name: 'Notification');
    } catch (e) {
      dev.log('[NotificationNotifier] FCM init failed: $e', name: 'Notification');
    }

    // Fetch unread count regardless of FCM status
    dev.log('[NotificationNotifier] Fetching unread count...', name: 'Notification');
    await fetchUnreadCount();
    dev.log('[NotificationNotifier] Unread count: ${state.unreadCount}', name: 'Notification');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    dev.log('[NotificationNotifier] Foreground notification received: ${message.notification?.title}', name: 'Notification');
    state = state.copyWith(unreadCount: state.unreadCount + 1);

    final type = message.data['type'] as String?;
    if (type == NotificationTypes.chatQuestionAnswered) {
      final questionId = message.data['question_id'] as String?;
      if (questionId != null) {
        dev.log('[NotificationNotifier] Question answered via FCM, refreshing: $questionId', name: 'Notification');
        _refreshQuestionCache(questionId);
      }
    }

    // Banner suppress is already handled by shouldSuppressNotification callback
    // in NotificationManager (which also suppresses local notifications).
    // Only show in-app banner for non-suppressed messages.
    if (!_shouldSuppressBanner(message)) {
      _onForegroundNotification?.call(message);
    }
  }

  /// Mesaj bildirimi + kullanıcı o chat'e bakıyorsa banner'ı bastır.
  bool _shouldSuppressBanner(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type != NotificationTypes.newMessage &&
        type != NotificationTypes.newMessageImage) {
      return false;
    }

    final actionUrl = message.data['action_url'] as String?;
    if (actionUrl == null) return false;

    // action_url format: /chat/{matchId}
    final activeChatMatchId = ref.read(activeChatMatchIdProvider);
    if (activeChatMatchId == null) return false;

    return actionUrl.contains('/chat/$activeChatMatchId');
  }

  Future<void> _refreshQuestionCache(String questionId) async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.getQuestion(questionId);
    result.when(
      success: (question) {
        ref.read(chatQuestionCacheProvider.notifier).update((state) {
          final copy = Map<String, ChatQuestionModel>.from(state);
          copy[questionId] = question;
          return copy;
        });
        dev.log('[NotificationNotifier] Question cache updated: $questionId', name: 'Notification');
      },
      failure: (_) {},
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    final actionUrl = message.data['action_url'] as String?;
    final notificationId = message.data['notification_id'] as String?;

    if (notificationId != null) {
      markAsRead(notificationId);
    }
    if (actionUrl != null && actionUrl.isNotEmpty) {
      if (_onNavigate == null) {
        // Callback henuz set edilmedi (terminated state race condition)
        // URL'yi sakla, setUICallbacks'te replay edilecek
        dev.log('[NotificationNotifier] _onNavigate not ready, queuing: $actionUrl', name: 'Notification');
        _pendingNavigationUrl = actionUrl;
        return;
      }
      _onNavigate!(actionUrl);
    }
  }

  // UI callbacks — set by app shell
  void Function(RemoteMessage)? _onForegroundNotification;
  void Function(String actionUrl)? _onNavigate;
  String? _pendingNavigationUrl;

  void setUICallbacks({
    void Function(RemoteMessage)? onForegroundNotification,
    void Function(String actionUrl)? onNavigate,
  }) {
    _onForegroundNotification = onForegroundNotification;
    _onNavigate = onNavigate;

    // Replay queued navigation from terminated state
    if (_pendingNavigationUrl != null && onNavigate != null) {
      dev.log('[NotificationNotifier] Replaying pending navigation: $_pendingNavigationUrl', name: 'Notification');
      final url = _pendingNavigationUrl!;
      _pendingNavigationUrl = null;
      onNavigate(url);
    }
  }

  Future<void> fetchNotifications({int page = 1}) async {
    state = state.copyWith(isLoading: true);
    final result =
        await ref.read(notificationRepositoryProvider).getNotifications(page, 20);
    result.when(
      success: (list) {
        final all = page == 1 ? list : [...state.notifications, ...list];
        state = state.copyWith(notifications: all, isLoading: false);
      },
      failure: (_) => state = state.copyWith(isLoading: false),
    );
  }

  Future<void> fetchUnreadCount() async {
    final result =
        await ref.read(notificationRepositoryProvider).getUnreadCount();
    result.when(
      success: (count) => state = state.copyWith(unreadCount: count),
      failure: (_) {},
    );
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    final updated = state.notifications.map((n) {
      if (n.id == id && !n.isRead) {
        return NotificationModel(
          id: n.id,
          userId: n.userId,
          campaignId: n.campaignId,
          type: n.type,
          title: n.title,
          body: n.body,
          imageUrl: n.imageUrl,
          actionUrl: n.actionUrl,
          actionLabel: n.actionLabel,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    final newUnread = (state.unreadCount - 1).clamp(0, 9999);
    state = state.copyWith(notifications: updated, unreadCount: newUnread);
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    final updated = state.notifications
        .map((n) => NotificationModel(
              id: n.id,
              userId: n.userId,
              campaignId: n.campaignId,
              type: n.type,
              title: n.title,
              body: n.body,
              imageUrl: n.imageUrl,
              actionUrl: n.actionUrl,
              actionLabel: n.actionLabel,
              isRead: true,
              createdAt: n.createdAt,
            ))
        .toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
  }

  Future<void> trackClick(String id) async {
    await ref.read(notificationRepositoryProvider).trackClick(id);
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
