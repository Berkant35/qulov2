import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/passport/mixins/map_confirm_screen_mixin.dart';
import 'package:qulo_v2/features/passport/screens/map_confirm_screen.dart';
import 'package:qulo_v2/providers/passport_provider.dart';

import '../../../helpers/fake_navigation.dart';

/// Pasaport etkinleştirme: istek sürerken "Geri" ile harita onayından
/// çıkılırsa başarıda yakalanmış servisle `pop` ALTTAKİ pasaport ekranını da
/// kapatıyordu. Haritanın kendisi (Google Maps) yerine aynı mixin host'ta.
class _HostConfirm extends MapConfirmScreen {
  const _HostConfirm()
      : super(cityName: 'Roma', country: 'Italy', flag: '🇮🇹', lat: 41.9, lng: 12.5);

  @override
  ConsumerState<MapConfirmScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<MapConfirmScreen>
    with LoadingMixin<MapConfirmScreen>, MapConfirmScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _GatedPassport extends PassportNotifier {
  Completer<void>? gate;
  final activated = <String>[];

  @override
  Future<Result<Map<String, dynamic>>> activate({
    required String city,
    required double lat,
    required double lng,
  }) async {
    activated.add(city);
    await gate?.future;
    return const Success({});
  }
}

void main() {
  final events = <String>[];
  late FakeNavigationService nav;
  late _GatedPassport passport;
  late ProviderContainer container;

  Widget app(Widget home) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: home,
        ),
      );

  setUp(() {
    events.clear();
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
    nav = FakeNavigationService();
    passport = _GatedPassport();
    container = ProviderContainer(overrides: [
      navigationServiceProvider.overrideWithValue(nav),
      passportProvider.overrideWith(() => passport),
    ]);
    addTearDown(container.dispose);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  testWidgets('istek sürerken ekrandan çıkılırsa: etkinleştirme tamamlanır, alttaki ekran kapatılmaz',
      (tester) async {
    await tester.pumpWidget(app(const _HostConfirm()));
    await tester.pump();
    final state = tester.state<_HostState>(find.byType(_HostConfirm));
    passport.gate = Completer<void>();

    final confirming = state.onConfirm();
    await tester.pump();
    expect(passport.activated, ['Roma']);
    await tester.pumpWidget(app(const SizedBox()));
    passport.gate!.complete();
    await confirming;

    expect(tester.takeException(), isNull);
    expect(nav.pops, 0);
    expect(events, contains(AnalyticsEvents.passportExploreStart));
  });

  testWidgets('açık ekranda başarı harita onayını kapatır', (tester) async {
    await tester.pumpWidget(app(const _HostConfirm()));
    await tester.pump();
    final state = tester.state<_HostState>(find.byType(_HostConfirm));

    await state.onConfirm();

    expect(nav.pops, 1);
  });
}
