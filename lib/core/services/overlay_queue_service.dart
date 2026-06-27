import 'package:qulo_v2/core/services/overlay_request.dart';

/// App-wide serializer for "show something to the user" overlays
/// (coach-marks, page-message modals/sheets, in-app banners).
///
/// Only ONE overlay is shown at a time. Others wait in a priority-ordered
/// queue and start as each active overlay closes. Hardware-Manager pattern:
/// features go through [instance], never insert overlays directly.
class OverlayQueueService {
  OverlayQueueService();
  static final OverlayQueueService instance = OverlayQueueService();

  OverlayRequest? _active;
  final List<OverlayRequest> _queue = [];

  /// Max queued notification-tier requests; oldest is dropped past this.
  static const int _maxQueuedNotifications = 3;

  /// True while an overlay is on screen.
  bool get isShowing => _active != null;

  /// Queues [req]. Shows immediately if nothing is active, else waits in
  /// priority order. Same id already active/queued → ignored (idempotent).
  void enqueue(OverlayRequest req) {
    if (_active?.id == req.id) return;
    if (_queue.any((r) => r.id == req.id)) return;

    if (req.priority == OverlayPriority.notification) {
      final queuedNotifs = _queue
          .where((r) => r.priority == OverlayPriority.notification)
          .toList();
      if (queuedNotifs.length >= _maxQueuedNotifications) {
        _queue.remove(queuedNotifs.first); // drop oldest notification
      }
    }

    if (_active == null) {
      _start(req);
    } else {
      _insertByPriority(req);
    }
  }

  /// Removes a still-queued request by id. No effect on the active overlay.
  void cancel(String id) {
    _queue.removeWhere((r) => r.id == id);
  }

  void _insertByPriority(OverlayRequest req) {
    // Higher priority first; equal priority keeps FIFO (insert after equals).
    var i = 0;
    while (i < _queue.length && _queue[i].priority >= req.priority) {
      i++;
    }
    _queue.insert(i, req);
  }

  void _start(OverlayRequest req) {
    _active = req;
    final Future<void> future;
    try {
      future = req.show();
    } catch (_) {
      _active = null;
      _drainNext();
      return;
    }
    future.whenComplete(() {
      // Guard: only advance if THIS request is still active (defensive —
      // protects against double-advance if _active is cleared elsewhere).
      if (_active?.id == req.id) {
        _active = null;
        _drainNext();
      }
    });
  }

  void _drainNext() {
    if (_queue.isEmpty) return;
    final next = _queue.removeAt(0);
    _start(next);
  }
}
