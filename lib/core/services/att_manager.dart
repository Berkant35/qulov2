import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/app_lifecycle_gate.dart';

/// App Tracking Transparency (ATT) manager — iOS only.
/// On Android/non-iOS platforms, all methods return authorized by default.
class AttManager {
  AttManager._();
  static final AttManager instance = AttManager._();

  /// Requests ATT permission from the user (iOS 14.5+).
  /// On non-iOS platforms, returns [TrackingStatus.authorized] immediately.
  Future<TrackingStatus> requestPermission() async {
    if (!Platform.isIOS) {
      dev.log('[ATT] Non-iOS platform — returning authorized', name: 'AttManager');
      return TrackingStatus.authorized;
    }

    try {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      dev.log('[ATT] Permission requested — result: ${status.name}', name: 'AttManager');
      // Sahada kanıt: diyalog gerçekten çıktı mı (authorized/denied), yoksa hâlâ
      // notDetermined mi? GA4'te (direct) şişkinliğinin tek ayırt edici sinyali.
      AnalyticsManager.instance
        ..logEvent(AnalyticsEvents.attPromptResult,
            params: {AnalyticsEvents.paramStatus: status.name})
        ..setUserProperty(AnalyticsEvents.userPropAttStatus, status.name);
      return status;
    } catch (e, stack) {
      // Plugin hatası açılışta fatal crash raporu olmasın (ErrorManager release'te
      // fatal sayar); MetaEventsManager ile aynı kalıp.
      AnalyticsManager.instance
          .logNonFatalError(e, stack, context: 'AttManager.requestPermission');
      return TrackingStatus.notDetermined;
    }
  }

  /// iOS diyaloğu yalnızca uygulama aktifken çıkar; `runApp`'ten önce istenince
  /// sessizce notDetermined dönüyor ve IDFA hiç alınmıyordu. İlk `resumed`
  /// beklenir, sonra istenir. Non-iOS'ta beklemeden authorized döner.
  Future<TrackingStatus> requestWhenActive() async {
    if (!Platform.isIOS) return TrackingStatus.authorized;
    await AppLifecycleGate.whenResumed();
    return requestPermission();
  }

  /// Returns the current ATT status without prompting the user.
  /// On non-iOS platforms, returns [TrackingStatus.authorized] immediately.
  Future<TrackingStatus> getStatus() async {
    if (!Platform.isIOS) {
      return TrackingStatus.authorized;
    }

    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    dev.log('[ATT] Current status: ${status.name}', name: 'AttManager');
    return status;
  }

  /// Convenience method — returns `true` if tracking is authorized.
  Future<bool> isAuthorized() async {
    final status = await getStatus();
    return status == TrackingStatus.authorized;
  }
}
