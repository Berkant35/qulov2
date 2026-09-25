import 'dart:async';

import 'package:qulo_v2/core/services/location_manager.dart';

/// Konum akisi testleri icin. Varsayilan: servis acik, izin verilmis; konum
/// `position` tamamlanana kadar askida kalir — ekran bu askidayken
/// kapatilabilir (Crashlytics'teki "await sirasinda unmount" senaryosu).
class FakeLocationManager implements LocationManager {
  final position = Completer<LocationResult>();
  bool serviceEnabled = true;
  LocationPermissionStatus permission = LocationPermissionStatus.granted;

  /// `requestPermission` sonucu; null ise `permission` degismez.
  LocationPermissionStatus? permissionAfterRequest;
  int requestPermissionCalls = 0;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionStatus> checkPermission() async => permission;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    requestPermissionCalls++;
    return permissionAfterRequest ?? permission;
  }

  @override
  Future<LocationResult> getCurrentPosition() => position.future;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeLocationManager.${invocation.memberName}');
}
