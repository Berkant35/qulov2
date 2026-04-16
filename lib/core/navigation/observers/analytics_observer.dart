import 'package:qulo_v2/core/navigation/navigation_observer.dart';
import 'package:qulo_v2/core/navigation/navigation_event.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';

class AnalyticsNavigationObserver extends AppNavigationObserver {
  final AnalyticsManager _analytics = AnalyticsManager.instance;
  final AnalyticsForwarder _forwarder = AnalyticsForwarder.instance;

  @override
  void onNavigate(NavigationEvent event) {
    _analytics.logScreenView(event.routeName);
    // Also forward to server for admin panel analytics
    _forwarder.trackScreen(event.routeName);
  }

  @override
  void onDialogOpen(String dialogName, {Map<String, dynamic>? params}) {
    _analytics.logEvent(AnalyticsEvents.uiDialogShow, params: {
      AnalyticsEvents.paramDialogType: dialogName,
    });
    _forwarder.track('dialog_open', category: 'ui', metadata: {'dialog': dialogName});
  }

  @override
  void onDialogClose(String dialogName, {dynamic result}) {
    _analytics.logEvent(AnalyticsEvents.uiDialogAction, params: {
      AnalyticsEvents.paramDialogType: dialogName,
      AnalyticsEvents.paramAction: result?.toString() ?? 'dismiss',
    });
    _forwarder.track('dialog_close', category: 'ui', metadata: {
      'dialog': dialogName,
      'action': result?.toString() ?? 'dismiss',
    });
  }

  @override
  void onBottomSheetOpen(String sheetName, {Map<String, dynamic>? params}) {
    _analytics.logEvent(AnalyticsEvents.uiBottomSheetShow, params: {
      AnalyticsEvents.paramSheetType: sheetName,
    });
    _forwarder.track('sheet_open', category: 'ui', metadata: {'sheet': sheetName});
  }

  @override
  void onBottomSheetClose(String sheetName, {dynamic result}) {
    _analytics.logEvent(AnalyticsEvents.uiBottomSheetDismiss, params: {
      AnalyticsEvents.paramSheetType: sheetName,
    });
    _forwarder.track('sheet_close', category: 'ui', metadata: {'sheet': sheetName});
  }
}
