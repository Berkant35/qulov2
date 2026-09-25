import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/features/auth/mixins/location_request_mixin.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../helpers/fake_location_manager.dart';

/// Crashlytics 2.0.11 `profile_completion_mixin.dart:179` — "Null check
/// operator used on a null value": konum beklenirken kullanici "Atla/Devam"
/// ile profili tamamlayip ekrandan cikiyor; GPS gelince `setState` release'de
/// `_element!.markNeedsBuild()` (framework.dart) ile patliyor. Ayni kod kayit
/// ekraninda da vardi; ikisi bu mixin'de birlesti.
class _Host extends ConsumerStatefulWidget {
  const _Host();

  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> with LocationRequestMixin {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final _en = AppLocalizations(const Locale('en'));

/// Fake ve container test GOVDESINDE kurulur: `setUp` gercek zone'da calisir,
/// orada yaratilan Completer'in future'i FakeAsync'te hic tamamlanmaz (test askida kalir).
class _Harness {
  _Harness._(this.location, this._container);

  final FakeLocationManager location;
  final ProviderContainer _container;

  static Future<_Harness> pump(
    WidgetTester tester, {
    bool serviceEnabled = true,
    LocationPermissionStatus permission = LocationPermissionStatus.granted,
    LocationPermissionStatus? permissionAfterRequest,
  }) async {
    final location = FakeLocationManager()
      ..serviceEnabled = serviceEnabled
      ..permission = permission
      ..permissionAfterRequest = permissionAfterRequest;
    final container = ProviderContainer(
      overrides: [locationManagerProvider.overrideWithValue(location)],
    );
    addTearDown(container.dispose);
    final harness = _Harness._(location, container);
    await tester.pumpWidget(harness.scoped(const _Host()));
    await tester.pump();
    return harness;
  }

  Widget scoped(Widget child) => UncontrolledProviderScope(
        container: _container,
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: child,
        ),
      );

  _HostState state(WidgetTester tester) => tester.state<_HostState>(find.byType(_Host));
}

void main() {
  testWidgets('konum beklenirken ekran kapanırsa setState çağrılmaz', (tester) async {
    final h = await _Harness.pump(tester);
    final state = h.state(tester);

    final pending = state.requestLocation();
    await tester.pump();
    expect(state.isRequestingLocation, isTrue);

    await tester.pumpWidget(h.scoped(const SizedBox.shrink()));
    h.location.position.complete(const LocationResult(lat: 41.0, lng: 29.0));

    await expectLater(pending, completes);
  });

  testWidgets('ekran açıkken konum gelince lat/lng yazılır', (tester) async {
    final h = await _Harness.pump(tester);
    final state = h.state(tester);

    final pending = state.requestLocation();
    await tester.pump();
    h.location.position.complete(const LocationResult(lat: 41.0, lng: 29.0));
    await pending;

    expect(state.lat, 41.0);
    expect(state.lng, 29.0);
    expect(state.locationGranted, isTrue);
    expect(state.isRequestingLocation, isFalse);
    expect(state.locationError, isNull);
  });

  testWidgets('servis kapalıysa çevrili hata, konum istenmez', (tester) async {
    final h = await _Harness.pump(tester, serviceEnabled: false);
    final state = h.state(tester);

    await state.requestLocation();

    expect(state.locationError, _en.get('location_service_disabled'));
    expect(state.locationGranted, isFalse);
    expect(state.isRequestingLocation, isFalse);
    expect(h.location.position.isCompleted, isFalse);
  });

  testWidgets('izin yoksa bir kez istenir; kalıcı ret hata, verilirse konum', (tester) async {
    final h = await _Harness.pump(
      tester,
      permission: LocationPermissionStatus.denied,
      permissionAfterRequest: LocationPermissionStatus.deniedForever,
    );
    final state = h.state(tester);

    await state.requestLocation();
    expect(h.location.requestPermissionCalls, 1);
    expect(state.locationError, _en.get('location_permission_denied_forever'));

    h.location.permissionAfterRequest = LocationPermissionStatus.granted;
    final pending = state.requestLocation();
    await tester.pump();
    h.location.position.complete(const LocationResult(lat: 1.0, lng: 2.0));
    await pending;

    expect(h.location.requestPermissionCalls, 2);
    expect(state.locationError, isNull);
    expect(state.lat, 1.0);
    expect(state.locationGranted, isTrue);
  });

  testWidgets('GPS hatası ham metin değil genel hata olarak gösterilir', (tester) async {
    final h = await _Harness.pump(tester);
    final state = h.state(tester);

    final pending = state.requestLocation();
    await tester.pump();
    h.location.position.completeError(Exception('CLLocationManager timeout'));
    await pending;

    expect(state.locationError, _en.get('error_general'));
    expect(state.locationGranted, isFalse);
  });
}
