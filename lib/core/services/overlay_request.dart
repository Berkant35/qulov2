/// A request to show a single overlay through [OverlayQueueService].
class OverlayRequest {
  /// Idempotency key — the same id is never queued twice.
  final String id;

  /// Higher value is shown first. See [OverlayPriority].
  final int priority;

  /// Opens the overlay and returns a Future that completes ONLY when the
  /// overlay closes. The queue advances when this future completes.
  final Future<void> Function() show;

  const OverlayRequest({
    required this.id,
    required this.priority,
    required this.show,
  });
}

/// Standard priority tiers. Higher = shown first.
abstract final class OverlayPriority {
  static const int onboarding = 300;
  static const int campaign = 200;
  static const int notification = 100;
}
