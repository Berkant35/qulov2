import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/notifications/widgets/push_permission_sheet.dart';
import 'package:qulo_v2/providers/notification_provider.dart';

/// Bildirim izninin istendiği "değerli anlar" (analytics `trigger`).
abstract final class PushPromptTrigger {
  /// Eşleşme kutlamasından çıkış.
  static const String match = 'match';

  /// Sohbette ilk mesaj gönderildi.
  static const String firstMessage = 'first_message';

  /// En az soru sayısına ulaşma kutlaması (2.0.18): kayıtların %95'i en az 2 soru
  /// kaydediyor, eşleşme anına ise yalnız %35'i ulaşıyor.
  static const String questionCelebration = 'question_celebration';

  /// Açıklama metni ana göre: eşleşmede "biri sorularını çözünce de haber
  /// verelim" (soru sahibi tarafı — "Seni çözdüler" bildirimi buna dayanıyor);
  /// soru kutlamasında henüz eşleşme yok, "biri çözüp eşleşince".
  static String bodyKeyFor(String trigger) => switch (trigger) {
        match => 'push_prompt_body_match',
        questionCelebration => 'push_prompt_body_questions',
        _ => 'push_prompt_body',
      };
}

/// Bildirim iznini login sonrası soğuk istemek yerine değerli anda sorar:
/// önce açıklama ekranı, kabul edilirse sistem istemi. Ömür boyu bir kez
/// ([PushPromptStore]); reddedene tekrar sorulmaz.
///
/// Platform: iOS'ta sistem istemi yalnız `notDetermined` iken açılır; Android
/// 13+ `POST_NOTIFICATIONS` çalışma zamanı istemi aynı `requestPermission`
/// çağrısıyla (firebase_messaging) gelir, Android ≤12'de izin varsayılan açık
/// olduğundan açıklama hiç gösterilmez ve token açılışta alınır.
mixin PushPermissionOfferMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Uygunsa açıklama ekranını gösterir; gösterildiyse `true` (çağıran aynı
  /// anda başka bir istem — ör. mağaza puanı — açmamak için kullanır).
  ///
  /// Bağımlılıklar ilk await'ten ÖNCE alınır: sohbette ilk mesajdan hemen sonra
  /// geri dönülürse ekran kapanır ve `ref` artık kullanılamaz. Kapanan ekranda
  /// açıklama, kullanıcının geçtiği başka ekranın üstünde açılmaz.
  Future<bool> offerPushPermission({required String trigger}) async {
    final notifications = ref.read(notificationProvider.notifier);
    final nav = ref.read(navigationServiceProvider);
    if (!await notifications.shouldOfferPushPrompt()) return false;
    if (!mounted) return false;

    await notifications.markPushPromptShown();
    if (!mounted) return false;
    final params = {AnalyticsEvents.paramTrigger: trigger};
    final analytics = AnalyticsManager.instance;
    analytics.logEvent(AnalyticsEvents.notificationPrePromptShow, params: params);
    FocusManager.instance.primaryFocus?.unfocus();

    final accepted = await nav.showAppBottomSheet<bool>(
      CustomBottomSheet(
        name: 'push_permission_prompt',
        builder: (_) =>
            PushPermissionSheet(bodyKey: PushPromptTrigger.bodyKeyFor(trigger)),
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
