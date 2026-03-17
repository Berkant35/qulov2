import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/navigation/navigation_event.dart';
import 'package:qulo_v2/core/navigation/navigation_observer.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/models/app_bottom_sheet.dart';
import 'package:qulo_v2/core/navigation/widgets/confirm_dialog_widget.dart';
import 'package:qulo_v2/core/navigation/widgets/info_dialog_widget.dart';
import 'package:qulo_v2/core/navigation/widgets/list_bottom_sheet_widget.dart';

class NavigationService {
  final GoRouter _router;
  final GlobalKey<NavigatorState> _rootNavigatorKey;
  final List<AppNavigationObserver> _observers;

  NavigationService({
    required GoRouter router,
    required GlobalKey<NavigatorState> rootNavigatorKey,
    List<AppNavigationObserver>? observers,
  })  : _router = router,
        _rootNavigatorKey = rootNavigatorKey,
        _observers = observers ?? [];

  // ─── Route Navigation ───

  DateTime _lastNavTime = DateTime(2000);

  bool _shouldThrottle() {
    final now = DateTime.now();
    if (now.difference(_lastNavTime) < AppDurations.navigationThrottle) return true;
    _lastNavTime = now;
    return false;
  }

  void go(String name, {Map<String, String>? params, Object? extra}) {
    if (_shouldThrottle()) return;
    final event = NavigationEvent.go(name, pathParameters: params, extra: extra);
    _notifyNavigate(event);
    _router.goNamed(name, pathParameters: params ?? {}, extra: extra);
  }

  Future<T?> push<T extends Object?>(String name, {Map<String, String>? params, Object? extra}) {
    if (_shouldThrottle()) return Future.value(null);
    final event = NavigationEvent.push(name, pathParameters: params, extra: extra);
    _notifyNavigate(event);
    return _router.pushNamed<T>(name, pathParameters: params ?? {}, extra: extra);
  }

  void pop<T>([T? result]) {
    final event = NavigationEvent.pop('current');
    _notifyPop(event);
    _router.pop(result);
  }

  bool canPop() => _router.canPop();

  // ─── Dialog ───

  Future<T?> showAppDialog<T>(AppDialog dialog) {
    final context = _rootNavigatorKey.currentContext;
    if (context == null) return Future.value(null);

    _notifyDialogOpen(dialog.name, _dialogParams(dialog));

    final Widget dialogWidget = switch (dialog) {
      ConfirmDialog d => ConfirmDialogWidget(dialog: d),
      InfoDialog d => InfoDialogWidget(dialog: d),
      CustomDialog d => d.builder(context),
    };

    return showDialog<T>(
      context: context,
      barrierDismissible: dialog.barrierDismissible,
      useRootNavigator: dialog.useRootNavigator,
      builder: (_) => dialogWidget,
    ).then((result) {
      _notifyDialogClose(dialog.name, result);
      return result;
    });
  }

  // ─── BottomSheet ───

  Future<T?> showAppBottomSheet<T>(AppBottomSheet sheet) {
    final context = _rootNavigatorKey.currentContext;
    if (context == null) return Future.value(null);

    _notifySheetOpen(sheet.name);

    final Widget sheetWidget = switch (sheet) {
      ListBottomSheet s => ListBottomSheetWidget(sheet: s),
      CustomBottomSheet s => s.builder(context),
    };

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: sheet.isDismissible,
      enableDrag: sheet.enableDrag,
      useRootNavigator: sheet.useRootNavigator,
      isScrollControlled: sheet.maxHeightFactor != null,
      constraints: sheet.maxHeightFactor != null
          ? BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * sheet.maxHeightFactor!,
            )
          : null,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => sheetWidget,
    ).then((result) {
      _notifySheetClose(sheet.name, result);
      return result;
    });
  }

  // ─── Overlay Close ───

  void closeOverlay<T>([T? result]) {
    final context = _rootNavigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  // ─── Deep Link ───

  void handleDeepLink(String uri) {
    for (final o in _observers) {
      o.onNavigate(NavigationEvent.go(uri));
    }
    _router.go(uri);
  }

  // ─── Observer Management ───

  void addObserver(AppNavigationObserver observer) => _observers.add(observer);
  void removeObserver(AppNavigationObserver observer) => _observers.remove(observer);

  // ─── Private Helpers ───

  void _notifyNavigate(NavigationEvent event) {
    for (final o in _observers) {
      o.onNavigate(event);
    }
  }

  void _notifyPop(NavigationEvent event) {
    for (final o in _observers) {
      o.onPop(event);
    }
  }

  void _notifyDialogOpen(String name, Map<String, dynamic>? params) {
    for (final o in _observers) {
      o.onDialogOpen(name, params: params);
    }
  }

  void _notifyDialogClose(String name, dynamic result) {
    for (final o in _observers) {
      o.onDialogClose(name, result: result);
    }
  }

  void _notifySheetOpen(String name) {
    for (final o in _observers) {
      o.onBottomSheetOpen(name);
    }
  }

  void _notifySheetClose(String name, dynamic result) {
    for (final o in _observers) {
      o.onBottomSheetClose(name, result: result);
    }
  }

  Map<String, dynamic>? _dialogParams(AppDialog dialog) {
    return switch (dialog) {
      ConfirmDialog d => {'type': 'ConfirmDialog', 'destructive': d.isDestructive},
      InfoDialog _ => {'type': 'InfoDialog'},
      CustomDialog _ => {'type': 'CustomDialog'},
    };
  }
}
