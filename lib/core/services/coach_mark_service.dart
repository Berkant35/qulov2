import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_controller.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_overlay.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';

/// Single entry point for anchored coach-mark tours. Feature code calls
/// [maybeStartTour]; the overlay/painter internals stay encapsulated here.
/// Tours are shown through [OverlayQueueService] so they never collide with
/// page-message modals or in-app banners.
class CoachMarkService {
  CoachMarkService._();
  static final CoachMarkService instance = CoachMarkService._();

  OverlayEntry? _activeEntry;
  Completer<void>? _activeCompleter;
  String? _queuedTourId;

  bool get isTourActive => _activeEntry != null;

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
    if (_activeEntry != null) return; // a tour is already on screen
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
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      completer.complete();
      return completer.future;
    }

    final controller = CoachMarkController(steps: steps);
    controller.onFinished = () => _close(tourId);

    final entry = OverlayEntry(
      builder: (_) => CoachMarkOverlay(controller: controller),
    );
    _activeEntry = entry;
    _activeCompleter = completer;
    overlay.insert(entry);
    return completer.future;
  }

  /// Force-removes the active tour overlay WITHOUT marking it seen, and
  /// cancels it if still waiting in the queue. Call from a triggering
  /// screen's dispose() so a route pop cannot orphan the overlay.
  void forceClose() {
    if (_queuedTourId != null) {
      OverlayQueueService.instance.cancel(_queueId(_queuedTourId!));
      _queuedTourId = null;
    }
    _activeEntry?.remove();
    _activeEntry = null;
    _activeCompleter?.complete(); // let the queue advance
    _activeCompleter = null;
  }

  void _close(String tourId) {
    _activeEntry?.remove();
    _activeEntry = null;
    _activeCompleter?.complete(); // queue advances
    _activeCompleter = null;
    // Fire-and-forget; flag write must not block UI removal.
    markSeen(tourId);
  }
}
