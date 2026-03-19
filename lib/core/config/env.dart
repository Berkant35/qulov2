abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.20.10.5:3001/api/v1',
  );
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vtntrtozgoyhjdvvurkj.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ0bnRydG96Z295aGpkdnZ1cmtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4ODg1MTMsImV4cCI6MjA4ODQ2NDUxM30.bDonZohUQUynDYd8rttQyGTi-o2Pktd5a9Zv5LeHxCA',
  );
  static const revenueCatAppleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'appl_WFnimoKwLYxkyxZYOxjyuLMSRpc',
  );
  static const revenueCatGoogleKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: 'goog_tAQvpZTakPHMKEYCoFvjSpGmjmv',
  );
}
