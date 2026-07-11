import 'package:flutter/widgets.dart';

/// App-wide "a route changed somewhere" signal. Fires after any push/pop/
/// remove/replace on an observed navigator (root + every shell branch).
/// Listeners re-evaluate visibility-dependent UI (e.g. coach-mark tours)
/// instead of tracking navigator internals themselves.
class RouteChangeNotifier extends ChangeNotifier {
  RouteChangeNotifier._();
  static final RouteChangeNotifier instance = RouteChangeNotifier._();

  void notifyRouteChanged() => notifyListeners();
}

/// A [NavigatorObserver] can be attached to only ONE navigator, so each
/// navigator (GoRouter root + each [StatefulShellBranch]) gets its own
/// instance; all of them report into the single [RouteChangeNotifier].
class RouteChangeObserver extends NavigatorObserver {
  void _changed() => RouteChangeNotifier.instance.notifyRouteChanged();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _changed();
}
