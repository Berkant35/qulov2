import 'package:flutter/foundation.dart';
import 'package:qulo_v2/core/navigation/navigation_observer.dart';
import 'package:qulo_v2/core/navigation/navigation_event.dart';

class LoggingObserver extends AppNavigationObserver {
  @override
  void onNavigate(NavigationEvent event) {
    if (kDebugMode) {
      debugPrint(event.toString());
    }
  }

  @override
  void onPop(NavigationEvent event) {
    if (kDebugMode) {
      debugPrint(event.toString());
    }
  }

  @override
  void onDialogOpen(String dialogName, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      debugPrint('[NAV] dialog_open -> $dialogName${params != null ? ' | $params' : ''}');
    }
  }

  @override
  void onDialogClose(String dialogName, {dynamic result}) {
    if (kDebugMode) {
      debugPrint('[NAV] dialog_close -> $dialogName | result: $result');
    }
  }

  @override
  void onBottomSheetOpen(String sheetName, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      debugPrint('[NAV] sheet_open -> $sheetName${params != null ? ' | $params' : ''}');
    }
  }

  @override
  void onBottomSheetClose(String sheetName, {dynamic result}) {
    if (kDebugMode) {
      debugPrint('[NAV] sheet_close -> $sheetName | result: $result');
    }
  }
}
