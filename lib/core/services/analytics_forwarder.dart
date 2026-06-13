import 'dart:async';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';

/// Forwards select mobile events to the server-side flow_events table
/// for admin panel analytics dashboard.
///
/// Complements Firebase Analytics (which is client-side only) by giving
/// the admin panel visibility into screen views and custom events.
///
/// Usage:
/// ```dart
/// AnalyticsForwarder.instance.track('screen_view', metadata: {'screen': 'discover'});
/// ```
class AnalyticsForwarder {
  AnalyticsForwarder._();
  static final AnalyticsForwarder instance = AnalyticsForwarder._();

  final List<Map<String, dynamic>> _buffer = [];
  Timer? _flushTimer;
  bool _enabled = true;

  static const int _maxBatchSize = 25;
  static const Duration _flushInterval = Duration(seconds: 15);

  /// Disable forwarding (e.g. for debug builds or privacy opt-out)
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _buffer.clear();
      _flushTimer?.cancel();
      _flushTimer = null;
    }
  }

  /// Track a single event. Batched and flushed periodically.
  void track(String eventName, {String? category, Map<String, dynamic>? metadata}) {
    if (!_enabled) return;
    if (eventName.isEmpty) return;

    _buffer.add({
      'event_name': eventName,
      if (category != null) 'category': category,
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    });

    if (_buffer.length >= _maxBatchSize) {
      _flushNow();
    } else {
      _scheduleFlush();
    }
  }

  /// Track a screen view.
  void trackScreen(String screenName) {
    track('screen_view', category: 'navigation', metadata: {'screen': screenName});
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(_flushInterval, _flushNow);
  }

  Future<void> _flushNow() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_buffer.isEmpty) return;

    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    // Fire-and-forget: never throw, never block
    try {
      final result = await NetworkManager.instance.post<dynamic>(
        '/analytics/track',
        data: {'events': batch},
      );
      // If the server endpoint is unavailable (e.g. not yet deployed),
      // disable forwarding for the rest of this session so we stop
      // spamming network/error logs every 15 seconds.
      if (result is Failure) {
        _enabled = false;
        _buffer.clear();
        _flushTimer?.cancel();
        _flushTimer = null;
      }
    } catch (_) {
      // Silent fail — analytics should never break the app
      _enabled = false;
    }
  }

  /// Force flush (e.g. on app background).
  Future<void> flush() async {
    await _flushNow();
  }
}
