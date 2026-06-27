import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_controller.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_overlay.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';

/// Single entry point for anchored coach-mark tours. Feature code calls
/// [maybeStartTour]; the overlay/painter internals stay encapsulated here.
class CoachMarkService {
  CoachMarkService._();
  static final CoachMarkService instance = CoachMarkService._();

  OverlayEntry? _activeEntry;

  bool get isTourActive => _activeEntry != null;

  String _flag(String tourId) => 'coach_${tourId}_seen';

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
    if (_activeEntry != null) return; // single-tour guard
    if (steps.isEmpty) return;
    if (await isSeen(tourId)) return;
    if (!context.mounted) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final controller = CoachMarkController(steps: steps);
    controller.onFinished = () => _close(tourId);

    final entry = OverlayEntry(
      builder: (_) => CoachMarkOverlay(controller: controller),
    );
    _activeEntry = entry;
    overlay.insert(entry);
  }

  /// Force-removes the active tour overlay WITHOUT marking it seen.
  /// Call from a triggering screen's dispose() so a route pop while the
  /// card is open cannot orphan the overlay or wedge the single-tour guard.
  void forceClose() {
    _activeEntry?.remove();
    _activeEntry = null;
  }

  void _close(String tourId) {
    _activeEntry?.remove();
    _activeEntry = null;
    // Fire-and-forget; flag write must not block UI removal.
    markSeen(tourId);
  }
}
