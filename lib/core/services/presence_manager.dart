import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:qulo_v2/core/network/services/presence_service.dart';

class PresenceManager {
  PresenceManager._();
  static final PresenceManager instance = PresenceManager._();

  PresenceService? _service;
  Timer? _timer;
  bool _started = false;

  static const _interval = Duration(seconds: 60);

  void init(PresenceService service) {
    _service = service;
  }

  /// Start periodic heartbeat — called on login + app resume
  void start() {
    if (_started || _service == null) return;
    _started = true;
    // Send immediately, then every 60s
    _sendHeartbeat();
    _timer = Timer.periodic(_interval, (_) => _sendHeartbeat());
    debugPrint('[Presence] Heartbeat started (${_interval.inSeconds}s interval)');
  }

  /// Stop heartbeat + send offline — called on logout + app pause
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _started = false;
    await _sendOffline();
    debugPrint('[Presence] Heartbeat stopped, sent offline');
  }

  /// Pause timer without sending offline — for temporary interruptions
  void pause() {
    _timer?.cancel();
    _timer = null;
    _started = false;
    debugPrint('[Presence] Heartbeat paused');
  }

  /// Send heartbeat (fire-and-forget, don't block on errors)
  Future<void> _sendHeartbeat() async {
    try {
      await _service?.heartbeat();
    } catch (e) {
      debugPrint('[Presence] Heartbeat failed: $e');
    }
  }

  /// Send offline status (fire-and-forget)
  Future<void> _sendOffline() async {
    try {
      await _service?.goOffline();
    } catch (e) {
      debugPrint('[Presence] Offline call failed: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _started = false;
    _service = null;
  }
}
