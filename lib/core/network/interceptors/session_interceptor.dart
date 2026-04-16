import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Adds X-Session-Id header to all API requests for server-side flow tracking.
///
/// A new session ID is generated on first use. Call [resetSession] when the
/// app comes back from background to start a new session boundary.
class SessionInterceptor extends Interceptor {
  static const _headerKey = 'X-Session-Id';
  static const _uuid = Uuid();

  static String _sessionId = _uuid.v4();

  /// Call when app resumes from background to start a new analytics session.
  static void resetSession() {
    _sessionId = _uuid.v4();
  }

  /// Current session ID (for debug/logging).
  static String get currentSessionId => _sessionId;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[_headerKey] = _sessionId;
    handler.next(options);
  }
}
