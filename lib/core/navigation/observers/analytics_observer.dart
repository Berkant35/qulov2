import 'package:qulo_v2/core/navigation/navigation_observer.dart';
import 'package:qulo_v2/core/navigation/navigation_event.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';

class AnalyticsNavigationObserver extends AppNavigationObserver {
  final AnalyticsManager _analytics = AnalyticsManager.instance;

  @override
  void onNavigate(NavigationEvent event) {
    _analytics.logScreenView(event.routeName);
  }

  @override
  void onDialogOpen(String dialogName, {Map<String, dynamic>? params}) {
    _analytics.logEvent(AnalyticsEvents.uiDialogShow, params: {
      AnalyticsEvents.paramDialogType: dialogName,
    });
  }

  @override
  void onDialogClose(String dialogName, {dynamic result}) {
    _analytics.logEvent(AnalyticsEvents.uiDialogAction, params: {
      AnalyticsEvents.paramDialogType: dialogName,
      AnalyticsEvents.paramAction: result?.toString() ?? 'dismiss',
    });
  }

  @override
  void onBottomSheetOpen(String sheetName, {Map<String, dynamic>? params}) {
    _analytics.logEvent(AnalyticsEvents.uiBottomSheetShow, params: {
      AnalyticsEvents.paramSheetType: sheetName,
    });
  }

  @override
  void onBottomSheetClose(String sheetName, {dynamic result}) {
    _analytics.logEvent(AnalyticsEvents.uiBottomSheetDismiss, params: {
      AnalyticsEvents.paramSheetType: sheetName,
    });
  }
}
