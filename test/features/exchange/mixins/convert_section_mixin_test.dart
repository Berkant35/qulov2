import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/diamonds/models/paywall_triggers.dart';
import 'package:qulo_v2/features/exchange/mixins/convert_section_mixin.dart';
import 'package:qulo_v2/features/exchange/widgets/convert_section.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Yesil → mor donusumde yesil yetersiz (403 `INSUFFICIENT_DIAMONDS`, ekrandaki
/// bakiye bayat): eskiden yalniz "satin alma basarisiz" yaziyordu. Kullanici
/// zaten mor istiyordu → teklif bu anda (`exchange_convert`). 2.0.18 P2-10.
void main() {
  late List<({String name, Map<String, Object>? params})> events;

  setUp(() {
    events = [];
    AnalyticsManager.debugEventSink = (name, params) => events.add((name: name, params: params));
    AnalyticsForwarder.debugTrackSink = (_, __, ___) {};
    AnalyticsForwarder.instance.setEnabled(false);
  });
  tearDown(() {
    AnalyticsManager.debugEventSink = null;
    AnalyticsForwarder.debugTrackSink = null;
    AnalyticsForwarder.instance.setEnabled(true);
  });

  testWidgets('yesil yetersiz → paywall exchange_convert, hata mesaji yok', (tester) async {
    final h = await _pump(tester, const ServerFailure(code: 'INSUFFICIENT_DIAMONDS', statusCode: 403));

    await h.state.onConvert();
    await tester.pump();

    expect(h.nav.sheets, ['paywall']);
    final shown = events.firstWhere((e) => e.name == AnalyticsEvents.paywallShown);
    expect(shown.params?[AnalyticsEvents.paramTrigger], PaywallTriggers.exchangeConvert);
    expect(find.text(h.context.tr('purchase_failed')), findsNothing);
    expect(h.state.converting, isFalse);
  });

  testWidgets('baska hata → paywall yok, "basarisiz" mesaji', (tester) async {
    final h = await _pump(tester, const ServerFailure(code: 'SERVER_ERROR', statusCode: 500));

    await h.state.onConvert();
    await tester.pump();

    expect(h.nav.sheets, isEmpty);
    expect(find.text(h.context.tr('purchase_failed')), findsOneWidget);
  });

  testWidgets('basari → paywall yok, "basarili" mesaji', (tester) async {
    final h = await _pump(tester, null);

    await h.state.onConvert();
    await tester.pump();

    expect(h.nav.sheets, isEmpty);
    expect(find.text(h.context.tr('purchase_success')), findsOneWidget);
  });
}

class _HostSection extends ConvertSection {
  const _HostSection();

  @override
  ConsumerState<ConvertSection> createState() => _HostState();
}

class _HostState extends ConsumerState<ConvertSection> with ConvertSectionMixin {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

Future<({FakeNavigationService nav, _HostState state, BuildContext context})> _pump(
  WidgetTester tester,
  AppFailure? convertFailure,
) async {
  final nav = FakeNavigationService();
  final container = ProviderContainer(overrides: [
    navigationServiceProvider.overrideWithValue(nav),
    exchangeRepositoryProvider.overrideWithValue(FakeExchangeRepository(convertFailure: convertFailure)),
    diamondRepositoryProvider.overrideWithValue(FakeDiamondRepository()),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: [AppLocalizationsDelegate()],
      supportedLocales: [Locale('en')],
      locale: Locale('en'),
      home: Scaffold(body: _HostSection()),
    ),
  ));
  await tester.pumpAndSettle();
  final element = tester.element(find.byType(_HostSection));
  return (nav: nav, state: tester.state<_HostState>(find.byType(_HostSection)), context: element);
}
