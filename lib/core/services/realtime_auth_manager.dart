import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/realtime_token_model.dart';

typedef RealtimeTokenIssuer = Future<Result<RealtimeToken>> Function();

/// Realtime bağlantısının kimliğini uygulayan uç (gerçeği: Supabase istemcisi).
abstract interface class RealtimeAuthTarget {
  /// Kullanıcı token'ını bağlantıya uygular; açık kanallara `access_token` iter,
  /// sonra açılan kanallar join'de bu token'ı taşır.
  Future<void> apply(String token);

  /// Anon anahtara döner: token alınamadı ve eldeki token'ın süresi geçti.
  Future<void> useAnon();

  /// Çıkış / hesap değişimi: tüm kanalları kapatır, anon anahtara döner.
  Future<void> reset();
}

/// Supabase Realtime için kullanıcı başına kısa ömürlü JWT'nin yaşam döngüsü
/// (sözleşme: `tasks/surum-2.0.18-sozlesmeler.md` → "Realtime token").
///
/// - Kanal sahibi abone olmadan ÖNCE [ensureFresh] çağırır.
/// - Ön planda token bitmeden [refreshLead] önce yenilenir; `setAuth` açık
///   kanallara yeni token'ı iter, kanallar düşmez.
/// - Arka planda zamanlayıcı durur (iOS zaten durdurur). Öne gelişte
///   [resumeThreshold]'dan az kaldıysa yenilenir ve [resubscribeRequests] ile
///   kanal sahiplerine "yeniden abone ol" denir: süresi geçen token'da Realtime
///   kanalı kapatır ("Token has expired").
/// - Token alınamazsa (503 `REALTIME_TOKEN_UNAVAILABLE`, ağ, 429) bugünkü anon
///   bağlantıyla devam edilir; hata gösterilmez. 082/083 RLS'i uygulanınca anon
///   bağlantı `matches`/`messages` olayı almaz, asgari sürüm bu yüzden 2.0.18.
/// - [clear] (çıkış) ve kullanıcı değişimi token'ı bellekten atar: sonraki
///   kullanıcıya eski `sub` kalmaz.
class RealtimeAuthManager {
  RealtimeAuthManager({
    required RealtimeTokenIssuer issueToken,
    required RealtimeAuthTarget target,
    DateTime Function()? now,
  })  : _issueToken = issueToken,
        _target = target,
        _now = now ?? DateTime.now;

  final RealtimeTokenIssuer _issueToken;
  final RealtimeAuthTarget _target;
  final DateTime Function() _now;

  /// Zamanlayıcıyla yenileme: bitişten bu kadar önce.
  static const refreshLead = Duration(minutes: 2);

  /// Abone olmadan önce ve öne gelişte: bundan az kaldıysa önce yenile.
  static const resumeThreshold = Duration(minutes: 3);

  /// Başarısız denemeden sonra abonelik yollarının yeniden istemesi için bekleme
  /// (sunucu sınırı kullanıcı başına dakikada 10). Öne geliş beklemez.
  static const failureCooldown = Duration(minutes: 1);

  final _resubscribe = StreamController<void>.broadcast();
  String? _userId;
  RealtimeToken? _token;
  DateTime? _failedAt;
  Timer? _timer;
  Future<void>? _inFlight;
  bool _inForeground = true;

  /// Kanal sahipleri dinler: token öne gelişte yenilendi (ya da düştü), kanalları yeniden kur.
  Stream<void> get resubscribeRequests => _resubscribe.stream;

  /// Bağlantıdaki kullanıcı token'ı; `null` = anon bağlantı.
  String? get currentToken => _token?.token;

  @visibleForTesting
  bool get hasScheduledRefresh => _timer?.isActive ?? false;

  Future<void> ensureFresh({required String userId}) async {
    if (_userId != userId) {
      if (_userId != null) await clear();
      _userId = userId;
    }
    if (_hasFreshToken || _inCooldown) return;
    await _refresh();
  }

  Future<void> onForeground() async {
    _inForeground = true;
    if (_userId == null) return;
    if (_hasFreshToken) {
      _scheduleRefresh();
      return;
    }
    final hadToken = _token != null;
    _failedAt = null;
    await _refresh();
    if (hadToken || _token != null) _resubscribe.add(null);
  }

  void onBackground() {
    _inForeground = false;
    _cancelTimer();
  }

  Future<void> clear() async {
    _userId = null;
    _token = null;
    _failedAt = null;
    _cancelTimer();
    await _target.reset();
  }

  void dispose() {
    _cancelTimer();
    _resubscribe.close();
  }

  bool get _hasFreshToken =>
      _token != null && _token!.remaining(_now()) > resumeThreshold;

  bool get _hasValidToken =>
      _token != null && _token!.remaining(_now()) > Duration.zero;

  bool get _inCooldown =>
      _failedAt != null && _now().difference(_failedAt!) < failureCooldown;

  /// Aynı anda gelen istekler (eşleşme listesi + sohbet ekranı) tek istekte birleşir.
  Future<void> _refresh() =>
      _inFlight ??= _fetchAndApply().whenComplete(() => _inFlight = null);

  Future<void> _fetchAndApply() async {
    final owner = _userId;
    final result = await _issueToken();
    // İstek sürerken çıkış yapıldı ya da hesap değişti: sonucu uygulama.
    if (owner == null || owner != _userId) return;
    switch (result) {
      case Success(:final data):
        _token = data;
        _failedAt = null;
        await _target.apply(data.token);
        _scheduleRefresh();
      case Failure(:final failure):
        _failedAt = _now();
        debugPrint('[RealtimeAuth] token unavailable, staying on anon connection: $failure');
        await _onRefreshFailed();
    }
  }

  Future<void> _onRefreshFailed() async {
    if (_token == null) return;
    if (_hasValidToken) {
      // Eski token hâlâ geçerli: bitmeden bir kez daha dene.
      final remaining = _token!.remaining(_now());
      _scheduleAfter(remaining < failureCooldown ? remaining : failureCooldown);
      return;
    }
    _token = null;
    await _target.useAnon();
  }

  void _scheduleRefresh() {
    final token = _token;
    if (token == null) return;
    _scheduleAfter(token.remaining(_now()) - refreshLead);
  }

  void _scheduleAfter(Duration delay) {
    _cancelTimer();
    if (!_inForeground || _userId == null) return;
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () => unawaited(_refresh()));
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
