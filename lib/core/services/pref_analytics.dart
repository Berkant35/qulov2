import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';

/// Tercih/rıza event'lerinin giriş noktaları.
abstract final class PrefEntryPoint {
  static const signup = 'signup';
  static const gate = 'gate';
  static const legacySheet = 'legacy_sheet';
  static const editProfile = 'edit_profile';
}

/// Tercih ve rıza event'leri — tek kapı. Cinsiyet + tercih birlikte yönelim verisidir
/// (KVKK m.6); tercih DEĞERİ hiçbir event'e, user property'ye ya da Crashlytics'e girmez.
abstract final class PrefAnalytics {
  static void prefSelected(String entryPoint) => AnalyticsManager.instance.logEvent(
        entryPoint == PrefEntryPoint.signup
            ? AnalyticsEvents.signupGenderPrefSelected
            : AnalyticsEvents.setupGenderPrefSelected,
        params: {'entry_point': entryPoint},
      );

  static void consentAnswered({required String entryPoint, required bool granted}) =>
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.prefConsentAnswered,
        params: {'entry_point': entryPoint, 'consent': granted ? 'granted' : 'declined'},
      );
}
