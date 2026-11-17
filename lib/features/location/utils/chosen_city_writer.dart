import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

/// Kayıt / profil tamamlamada "yalnız seçim" kipinde seçilen şehri, hesap
/// (oturum) var olduktan sonra sunucuya yazar (`PATCH /users/me/location/city`).
///
/// Yazım başarısız olursa kullanıcı kilitlenmez: akış devam eder, hata
/// Crashlytics'e non-fatal olarak ve GA4'e olay olarak gider; konumsuz kalan
/// kullanıcıyı Keşfet'teki istem kartı yakalar.
abstract final class ChosenCityWriter {
  static const _errorContext = 'chosen_city_write';

  /// Yazım başarılıysa true. Asla fırlatmaz.
  static Future<bool> write(ICityRepository cities, String cityId, {required String source}) async {
    try {
      final result = await cities.setCity(cityId);
      if (result case Failure(:final failure)) {
        _report(failure, StackTrace.current, source);
        return false;
      }
      return true;
    } catch (e, stack) {
      _report(e, stack, source);
      return false;
    }
  }

  static void _report(Object error, StackTrace stack, String source) {
    AnalyticsManager.instance.logNonFatalError(
      error,
      stack,
      context: _errorContext,
      extras: {AnalyticsEvents.paramSource: source},
    );
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.onboardingCitySaveFail,
      params: {AnalyticsEvents.paramSource: source},
    );
  }
}
