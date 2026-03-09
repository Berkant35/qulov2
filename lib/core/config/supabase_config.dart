import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qulo_v2/core/config/env.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
}

SupabaseClient get supabaseClient => Supabase.instance.client;
