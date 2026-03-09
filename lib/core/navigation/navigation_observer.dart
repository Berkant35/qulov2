import 'package:qulo_v2/core/navigation/navigation_event.dart';

abstract class AppNavigationObserver {
  void onNavigate(NavigationEvent event) {}
  void onPop(NavigationEvent event) {}
  void onDialogOpen(String dialogName, {Map<String, dynamic>? params}) {}
  void onDialogClose(String dialogName, {dynamic result}) {}
  void onBottomSheetOpen(String sheetName, {Map<String, dynamic>? params}) {}
  void onBottomSheetClose(String sheetName, {dynamic result}) {}
}
