import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/features/discover/mixins/discover_location_prompt_mixin.dart';
import 'package:qulo_v2/features/discover/models/location_prompt_content.dart';
import 'package:qulo_v2/features/discover/utils/discover_location_gate.dart';
import 'package:qulo_v2/providers/location_provider.dart';

class _Prompt with DiscoverLocationPromptMixin {}

/// Konum istem kartı: hata koduna göre doğru eylem. iOS reddedilen izni bir
/// daha sormaz → kalıcı redde "izin iste" butonu ölü buton olurdu.
void main() {
  final prompt = _Prompt();

  test('izin hiç verilmedi / reddedildi → sistem izni istenir', () {
    final c = prompt.promptFor(LocationErrors.permissionDenied);
    expect(c.action, LocationPromptAction.requestPermission);
    expect(c.ctaKey, 'location_prompt_allow');
    expect(c.isMock, isFalse);
  });

  test('kalıcı red → uygulama ayarları', () {
    final c = prompt.promptFor(LocationErrors.permissionDeniedForever);
    expect(c.action, LocationPromptAction.openAppSettings);
  });

  test('konum servisi kapalı → telefonun konum ayarları', () {
    final c = prompt.promptFor(LocationErrors.serviceDisabled);
    expect(c.action, LocationPromptAction.openLocationSettings);
  });

  test('sahte konum → engelleyici uyarı, açıklama yok', () {
    final c = prompt.promptFor(LocationErrors.mockDetected);
    expect(c.isMock, isTrue);
    expect(c.messageKey, isNull);
  });

  test('bilinmeyen hata (GPS zaman aşımı) → tekrar istemeyi dener', () {
    final c = prompt.promptFor('TimeoutException');
    expect(c.action, LocationPromptAction.requestPermission);
  });

  test('tüm kart anahtarları çeviride var', () {
    for (final error in [
      LocationErrors.permissionDenied,
      LocationErrors.permissionDeniedForever,
      LocationErrors.serviceDisabled,
      LocationErrors.mockDetected,
    ]) {
      final c = prompt.promptFor(error);
      for (final key in [c.titleKey, c.ctaKey, ?c.messageKey]) {
        expect(enTranslations.containsKey(key), isTrue, reason: '$error → $key');
      }
    }
  });

  // 2.0.18 konumsuz yedek yol: konum vermeyen de şehir seçip desteyi görebilir.
  test('"şehir seç" yalnız sahte konumda sunulmaz', () {
    expect(prompt.promptFor(LocationErrors.mockDetected).offersCity, isFalse);
    for (final error in [
      LocationErrors.permissionDenied,
      LocationErrors.permissionDeniedForever,
      LocationErrors.serviceDisabled,
      discoverLocationMissingCode,
    ]) {
      expect(prompt.promptFor(error).offersCity, isTrue, reason: error);
    }
    expect(enTranslations.containsKey('city_picker_choose_city'), isTrue);
  });

  test('sunucuda konum yok (PROFILE_INCOMPLETE) → konum izni iste + şehir seç', () {
    final c = prompt.promptFor(discoverLocationMissingCode);
    expect(c.action, LocationPromptAction.requestPermission);
  });
}

