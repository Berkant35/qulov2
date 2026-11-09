import 'dart:async';

import 'package:qulo_v2/core/services/realtime_auth_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef RealtimeStatusCallback = void Function(RealtimeSubscribeStatus status, Object? error);

/// Kanalları kurar ve abone eder; her kanalın `subscribe`'ına [onStatus] verilir.
/// [generation] o kuruluşun kimliği: eski kuruluşun olayını ayıklamak için.
typedef RealtimeChannelBuilder = List<RealtimeChannel> Function(
  int generation,
  RealtimeStatusCallback onStatus,
);

/// Bir sahibin (eşleşme listesi, sohbet ekranı) Realtime kanallarını birlikte yönetir.
///
/// - Abone olmadan önce kullanıcı token'ını tazeler ([RealtimeAuthManager.ensureFresh]).
/// - Kanal hata verir, zaman aşımına uğrar ya da sunucu kapatırsa (süresi geçen
///   token: "Token has expired") hepsini artan beklemeyle yeniden kurar; en çok
///   [maxRetries] kez, başarılı abonelik sayacı sıfırlar.
/// - Token öne gelişte yenilenince ([RealtimeAuthManager.resubscribeRequests]) hemen yeniden kurar.
/// Kanal adları ve filtreler sahibin [RealtimeChannelBuilder]'ında kalır, burada değişmez.
class RealtimeChannelGroup {
  RealtimeChannelGroup({
    required RealtimeAuthManager auth,
    required String userId,
    required RealtimeChannelBuilder build,
    Future<void> Function()? reload,
    void Function(RealtimeChannel channel)? close,
  })  : _auth = auth,
        _userId = userId,
        _build = build,
        _reload = reload,
        _close = close ?? _unsubscribe;

  final RealtimeAuthManager _auth;
  final String _userId;
  final RealtimeChannelBuilder _build;

  /// Yeniden kurmadan önce (kopukluk sırasında kaçan olaylar için) veriyi tazeler.
  final Future<void> Function()? _reload;
  final void Function(RealtimeChannel channel) _close;

  static const maxRetries = 3;
  static const retryStep = Duration(seconds: 5);

  int _generation = 0;
  int _retries = 0;
  bool _disposed = false;
  List<RealtimeChannel> _channels = const [];
  StreamSubscription<void>? _authSub;
  Timer? _retryTimer;

  /// Geçerli kuruluşun kimliği; sahibin olay işleyicileri bununla karşılaştırır.
  int get generation => _generation;

  Future<void> start() async {
    _authSub ??= _auth.resubscribeRequests.listen((_) => unawaited(restart()));
    await _subscribe();
  }

  /// Kanalları hemen yeniden kurar (token yenilendi / eşleşme listesi değişti).
  Future<void> restart({bool reload = true}) async {
    if (_disposed) return;
    _retries = 0;
    _teardown();
    if (reload) await _reload?.call();
    await _subscribe();
  }

  void dispose() {
    _disposed = true;
    _teardown();
    // Beklenmez: abonelik iptali kök bölgenin hazır Future'ını döner, sahibin
    // `onDispose` / `dispose` akışında beklemeye değer bir iş yok.
    unawaited(_authSub?.cancel());
    _authSub = null;
  }

  Future<void> _subscribe() async {
    if (_disposed) return;
    final gen = ++_generation;
    await _auth.ensureFresh(userId: _userId);
    // Beklerken kapatıldı ya da başka bir kurulum başladı: bu kuruluş geçersiz.
    if (_disposed || gen != _generation) return;
    _channels = _build(gen, (status, _) => _onStatus(gen, status));
  }

  void _onStatus(int gen, RealtimeSubscribeStatus status) {
    if (_disposed || gen != _generation) return;
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _retries = 0;
      case RealtimeSubscribeStatus.channelError:
      case RealtimeSubscribeStatus.timedOut:
      case RealtimeSubscribeStatus.closed:
        _scheduleReconnect(gen);
    }
  }

  /// Aynı kopuklukta birden çok kanal haber verir; tek yeniden kurulum yeter.
  void _scheduleReconnect(int gen) {
    if (_retryTimer?.isActive ?? false) return;
    if (_retries >= maxRetries) return;
    _retries++;
    _retryTimer = Timer(retryStep * _retries, () async {
      if (_disposed || gen != _generation) return;
      _teardown();
      await _reload?.call();
      await _subscribe();
    });
  }

  /// Önce kuruluş kimliği artar: kapatılan kanalın `closed` durumu yeniden kurulum tetiklemez.
  void _teardown() {
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    final old = _channels;
    _channels = const [];
    for (final channel in old) {
      _close(channel);
    }
  }

  static void _unsubscribe(RealtimeChannel channel) => unawaited(channel.unsubscribe());
}
