import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';
import 'package:qulo_v2/features/discover/mixins/discover_screen_mixin.dart';
import 'package:qulo_v2/features/discover/screens/discover_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';

import '../../helpers/fake_location_manager.dart';

/// Crashlytics 2.0.12 `discover_screen_mixin.dart:127` — "Cannot use ref after
/// the widget was disposed": konum alinirken (izin diyalogu + GPS) ekran
/// kapaniyor (setup-gate redirect / sekme), await sonrasi `ref.read` patliyor.
/// riverpod 2.6.1 bunu assert degil StateError olarak atar — release'de de.
class _HostScreen extends DiscoverScreen {
  const _HostScreen();

  @override
  ConsumerState<DiscoverScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<DiscoverScreen> with DiscoverScreenMixin {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('konum beklenirken ekran kapanırsa ref kullanılmaz', (tester) async {
    final location = FakeLocationManager();
    final container = ProviderContainer(
      overrides: [locationManagerProvider.overrideWithValue(location)],
    );
    addTearDown(container.dispose);

    Widget scoped(Widget child) =>
        UncontrolledProviderScope(container: container, child: MaterialApp(home: child));

    await tester.pumpWidget(scoped(const _HostScreen()));
    final state = tester.state<_HostState>(find.byType(_HostScreen));

    final pending = state.initLocationAndDiscover();
    await tester.pump();

    await tester.pumpWidget(scoped(const SizedBox.shrink()));
    location.position.completeError(Exception('gps'));

    await expectLater(pending, completes);
  });

  testWidgets(
      'Discover girişinde konum izni SORULMAZ; karttan izin verilince deste yüklenir',
      (tester) async {
    final location = FakeLocationManager()
      ..permission = LocationPermissionStatus.denied;
    final repo = _CountingMatchRepository();
    final container = ProviderContainer(overrides: [
      locationManagerProvider.overrideWithValue(location),
      matchRepositoryProvider.overrideWithValue(repo),
      userRepositoryProvider.overrideWithValue(_NoopUserRepository()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: _HostScreen()),
    ));
    final state = tester.state<_HostState>(find.byType(_HostScreen));
    state.listenLocationRecovery();

    final init = state.initLocationAndDiscover();
    await tester.pump();
    await init;

    expect(location.requestPermissionCalls, 0, reason: 'soğuk sistem istemi yok');
    expect(container.read(locationProvider).error, LocationErrors.permissionDenied);
    expect(repo.discoverCalls, 0);

    // Kullanıcı "konumu paylaş"a dokundu, sistem isteminde izin verdi.
    location.permissionAfterRequest = LocationPermissionStatus.granted;
    location.position.complete(const LocationResult(lat: 41, lng: 29));
    final ask = container.read(locationProvider.notifier).getCurrentLocation();
    await tester.pump();
    await ask;
    await tester.pump();

    expect(location.requestPermissionCalls, 1);
    expect(repo.discoverCalls, 1, reason: 'izin gelince deste yüklenmeli');
  });

  testWidgets(
      'initMixin: auth öncesi oynanan güç demosunun sonucu ilk Discover girişinde raporlanır',
      (tester) async {
    SharedPreferences.setMockInitialValues({'power_demo_outcome_v1': 'skipped:2'});
    // logAuthedOnce AnalyticsForwarder'a da yazar (15 sn'lik zamanlayıcı kurar).
    AnalyticsForwarder.instance.setEnabled(false);
    final events = <({String name, Map<String, Object>? params})>[];
    AnalyticsManager.debugEventSink =
        (name, params) => events.add((name: name, params: params));
    addTearDown(() {
      AnalyticsManager.debugEventSink = null;
      AnalyticsForwarder.instance.setEnabled(true);
    });
    final container = ProviderContainer(overrides: [
      locationManagerProvider.overrideWithValue(
        FakeLocationManager()..permission = LocationPermissionStatus.denied,
      ),
      matchRepositoryProvider.overrideWithValue(_CountingMatchRepository()),
      userRepositoryProvider.overrideWithValue(_NoopUserRepository()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: _HostScreen()),
    ));
    tester.state<_HostState>(find.byType(_HostScreen)).initMixin();
    await tester.pump();
    await tester.pump();

    final outcome = events.where((e) => e.name == AnalyticsEvents.powerDemoOutcome);
    expect(outcome, hasLength(1));
    expect(outcome.single.params, {'outcome': 'skipped', 'from_step': 2});
  });
}

class _CountingMatchRepository implements MatchRepository {
  int discoverCalls = 0;

  @override
  Future<Result<DiscoverResponse>> discover({int page = 1}) async {
    discoverCalls++;
    return const Success(DiscoverResponse(cards: [], page: 1, hasMore: false));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_CountingMatchRepository.${invocation.memberName}');
}

class _NoopUserRepository implements UserRepository {
  @override
  Future<Result<void>> updateLocation({
    required double lat,
    required double lng,
    String? city,
    String? country,
  }) async =>
      const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_NoopUserRepository.${invocation.memberName}');
}
