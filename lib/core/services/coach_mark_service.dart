import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_controller.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_overlay.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/navigation/observers/route_change_notifier.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';

/// Single entry point for anchored coach-mark tours. Feature code calls
/// [maybeStartTour]; the overlay/painter internals stay encapsulated here.
/// Tours are shown through [OverlayQueueService] so they never collide with
/// page-message modals or in-app banners.
///
/// The tour overlay lives in the ROOT overlay, above every route — so it must
/// only be on screen while the triggering screen is the visible top route.
/// [_syncVisibility] enforces that: the overlay is inserted only when nothing
/// (onboarding screen, profile-setup, bottom sheet, dialog…) covers the
/// trigger screen, hides itself when something opens on top, and re-appears
/// when it closes. Route changes arrive via [RouteChangeNotifier].
class CoachMarkService {
  CoachMarkService._();
  static final CoachMarkService instance = CoachMarkService._();

  OverlayEntry? _activeEntry;
  Completer<void>? _activeCompleter;
  CoachMarkController? _activeController;
  BuildContext? _tourContext;
  String? _queuedTourId;
  bool _listeningRoutes = false;

  /// True while a tour is in progress — on screen OR hidden waiting for its
  /// trigger screen to become visible again.
  bool get isTourActive => _activeCompleter != null;

  String _flag(String tourId) => 'coach_${tourId}_seen';
  String _queueId(String tourId) => 'coach_$tourId';

  Future<bool> isSeen(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_flag(tourId)) ?? false;
  }

  Future<void> markSeen(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flag(tourId), true);
  }

  Future<void> maybeStartTour(
    BuildContext context, {
    required String tourId,
    required List<CoachMarkStep> steps,
  }) async {
    if (_activeCompleter != null) return; // a tour is already in progress
    if (_queuedTourId != null) return; // a tour is already queued
    if (steps.isEmpty) return;
    if (await isSeen(tourId)) return;
    if (!context.mounted) return;

    _queuedTourId = tourId;
    OverlayQueueService.instance.enqueue(
      OverlayRequest(
        id: _queueId(tourId),
        priority: OverlayPriority.onboarding,
        show: () => _show(context, tourId, steps),
      ),
    );
  }

  Future<void> _show(
    BuildContext context,
    String tourId,
    List<CoachMarkStep> steps,
  ) {
    _queuedTourId = null;
    final completer = Completer<void>();
    // Context may have unmounted while waiting in the queue.
    if (!context.mounted) {
      completer.complete();
      return completer.future;
    }

    final controller = CoachMarkController(steps: steps);
    controller.onFinished = () => _close(tourId);

    _tourContext = context;
    _activeController = controller;
    _activeCompleter = completer;
    _startRouteListener();
    _syncVisibility();
    return completer.future;
  }

  /// True when every route enclosing [context] — branch page, shell page on
  /// the root navigator, … — is the top-most route of its navigator, i.e.
  /// nothing (screen, sheet, dialog) covers the trigger screen.
  static bool _isContextVisible(BuildContext context) {
    if (!TickerMode.of(context)) return false; // covered / inactive shell tab
    ModalRoute<dynamic>? route = ModalRoute.of(context);
    while (route != null) {
      if (!route.isCurrent) return false;
      final navContext = route.navigator?.context;
      route = navContext == null ? null : ModalRoute.of(navContext);
    }
    return true;
  }

  /// Inserts the overlay when the trigger screen is visible, removes it when
  /// covered. Re-inserting resumes the tour at its current step (the
  /// controller keeps the index; `start()` is one-shot).
  void _syncVisibility() {
    final context = _tourContext;
    if (context == null) return; // tour already closed
    if (!context.mounted) {
      _cleanup(); // screen gone while hidden/queued — tour retries next visit
      return;
    }
    final visible = _isContextVisible(context);
    if (visible && _activeEntry == null) {
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) {
        _cleanup();
        return;
      }
      final entry = OverlayEntry(
        builder: (_) => CoachMarkOverlay(controller: _activeController!),
      );
      _activeEntry = entry;
      overlay.insert(entry);
    } else if (!visible && _activeEntry != null) {
      _activeEntry!.remove();
      _activeEntry = null;
    }
  }

  void _onRouteChanged() {
    // Route state settles within the frame; check after it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncVisibility());
  }

  void _startRouteListener() {
    if (_listeningRoutes) return;
    _listeningRoutes = true;
    RouteChangeNotifier.instance.addListener(_onRouteChanged);
  }

  void _stopRouteListener() {
    if (!_listeningRoutes) return;
    _listeningRoutes = false;
    RouteChangeNotifier.instance.removeListener(_onRouteChanged);
  }

  /// Force-removes the active tour overlay WITHOUT marking it seen, and
  /// cancels it if still waiting in the queue. Call from a triggering
  /// screen's dispose() so a route pop cannot orphan the overlay.
  void forceClose() {
    if (_queuedTourId != null) {
      OverlayQueueService.instance.cancel(_queueId(_queuedTourId!));
      _queuedTourId = null;
    }
    _cleanup();
  }

  void _close(String tourId) {
    _cleanup();
    // Fire-and-forget; flag write must not block UI removal.
    markSeen(tourId);
  }

  void _cleanup() {
    _stopRouteListener();
    _activeEntry?.remove();
    _activeEntry = null;
    _activeController = null;
    _tourContext = null;
    _activeCompleter?.complete(); // let the queue advance
    _activeCompleter = null;
  }
}
