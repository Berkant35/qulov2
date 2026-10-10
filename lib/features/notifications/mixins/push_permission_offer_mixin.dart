import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/push_prompt_store.dart';
import 'package:qulo_v2/features/notifications/widgets/push_permission_sheet.dart';
import 'package:qulo_v2/providers/notification_provider.dart';

/// Bildirim izninin istendiği "değerli anlar" (analytics `trigger`).
abstract final class PushPromptTrigger {
  /// Eşleşme kutlamasından çıkış.
  static const String match = 'match';

  /// Sohbette ilk mesaj gönderildi.
  static const String firstMessage = 'first_message';
}

/// Bildirim iznini login sonrası soğuk istemek yerine değerli anda sorar:
/// önce açıklama ekranı, kabul edilirse sistem istemi.
mixin PushPermissionOfferMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Uygunsa açıklama ekranını gösterir; gösterildiyse `true` (çağıran aynı
  /// anda başka bir istem — ör. mağaza puanı — açmamak için kullanır).
  Future<bool> offerPushPermission({required String trigger}) async {
    final notifications = ref.read(notificationProvider.notifier);
    if (!await notifications.shouldOfferPushPrompt()) return false;
    if (!mounted) return false;

    await PushPromptStore.markShown();
    final params = {AnalyticsEvents.paramTrigger: trigger};
    final analytics = AnalyticsManager.instance;
    analytics.logEvent(AnalyticsEvents.notificationPrePromptShow, params: params);
    FocusManager.instance.primaryFocus?.unfocus();

    final accepted = await ref.read(navigationServiceProvider).showAppBottomSheet<bool>(
          CustomBottomSheet(
            name: 'push_permission_prompt',
            builder: (_) => const PushPermissionSheet(),
          ),
        );
    analytics.logEvent(
      accepted == true
          ? AnalyticsEvents.notificationPrePromptAccept
          : AnalyticsEvents.notificationPrePromptDecline,
      params: params,
    );
    if (accepted == true) await notifications.requestPushPermission(trigger: trigger);
    return true;
  }
}
