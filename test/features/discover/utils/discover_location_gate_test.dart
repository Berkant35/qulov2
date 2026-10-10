import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/discover/utils/discover_location_gate.dart';
import 'package:qulo_v2/providers/location_provider.dart';

/// Discover'ın konum kapısı: ne zaman istem kartı gösterilir, ne zaman deste
/// yüklenir.
void main() {
  group('blockingLocationError', () {
    test('hata yoksa engel yok', () {
      expect(blockingLocationError(const LocationState(lat: 41, lng: 29)), isNull);
    });

    test('konum yokken izin reddi kartı gösterir', () {
      const s = LocationState(error: LocationErrors.permissionDenied);
      expect(blockingLocationError(s), LocationErrors.permissionDenied);
    });

    test('profilden konum varken izin reddi desteyi ENGELLEMEZ', () {
      const s = LocationState(lat: 41, lng: 29, error: LocationErrors.permissionDenied);
      expect(blockingLocationError(s), isNull);
    });

    test('profilden konum varken servis kapalı da engellemez', () {
      const s = LocationState(lat: 41, lng: 29, error: LocationErrors.serviceDisabled);
      expect(blockingLocationError(s), isNull);
    });

    test('sahte konum her durumda engeller', () {
      const s = LocationState(lat: 41, lng: 29, error: LocationErrors.mockDetected);
      expect(blockingLocationError(s), LocationErrors.mockDetected);
    });
  });

  group('locationBecameReady', () {
    const denied = LocationState(error: LocationErrors.permissionDenied);
    const loading = LocationState(isLoading: true);
    const ready = LocationState(lat: 41, lng: 29);

    test('iki adımlı geçiş: hata → yükleniyor → hazır, son adımda yakalanır', () {
      // getCurrentLocation önce hatayı silip yükleniyor durumuna geçer;
      // eski "önceki hatalı" kontrolü son adımı kaçırıyordu.
      expect(locationBecameReady(denied, loading), isFalse);
      expect(locationBecameReady(loading, ready), isTrue);
    });

    test('zaten hazırken yenilenen konum yeniden tetiklemez', () {
      expect(locationBecameReady(ready, const LocationState(lat: 42, lng: 29)), isFalse);
    });

    test('hazır değilse tetiklemez', () {
      expect(locationBecameReady(loading, denied), isFalse);
      expect(locationBecameReady(null, loading), isFalse);
    });
  });
}
