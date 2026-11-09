import 'package:qulo_v2/core/config/env.dart';
import 'package:qulo_v2/core/services/realtime_auth_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [RealtimeAuthTarget]'ın Supabase karşılığı. Uygulama `supabase.auth`
/// kullanmadığı için token yalnız Realtime istemcisine verilir.
class SupabaseRealtimeAuthTarget implements RealtimeAuthTarget {
  const SupabaseRealtimeAuthTarget();

  RealtimeClient get _realtime => Supabase.instance.client.realtime;

  @override
  Future<void> apply(String token) => _realtime.setAuth(token);

  /// `setAuth(null)` mevcut token'ı korur; anon'a dönmek için anahtar açıkça verilir.
  @override
  Future<void> useAnon() => _realtime.setAuth(Env.supabaseAnonKey);

  @override
  Future<void> reset() async {
    await Supabase.instance.client.removeAllChannels();
    await useAnon();
  }
}
