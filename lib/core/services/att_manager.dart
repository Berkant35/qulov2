import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

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

    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    dev.log('[ATT] Permission requested — result: ${status.name}', name: 'AttManager');
    return status;
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
