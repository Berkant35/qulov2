import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/purchase_outcome.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/features/diamonds/mixins/subscription_comparison_screen_mixin.dart';
import 'package:qulo_v2/features/diamonds/screens/subscription_comparison_screen.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

import '../../../helpers/fake_navigation.dart';

/// Plan karşılaştırma ekranından abonelik (para): vazgeçme sessiz (2.0.18 — eskiden
/// "satın alma başarısız" çıkıyordu), gerçek hata mesajlı, başarı kutlama + Elmaslar.
class _Host extends SubscriptionComparisonScreen {
  const _Host();

  @override
  ConsumerState<SubscriptionComparisonScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<SubscriptionComparisonScreen> with SubscriptionComparisonScreenMixin {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _ScriptedSubscription extends SubscriptionNotifier {
  _ScriptedSubscription(this.outcome);

  final PurchaseOutcome outcome;
  final purchased = <String>[];

  @override
  Future<SubscriptionInfo> build() async => SubscriptionInfo.free();

  @override
  Future<PurchaseOutcome> purchaseByProductId(String productId) async {
    purchased.add(productId);
    return outcome;
  }
}

void main() {
  setUp(() => AnalyticsManager.debugEventSink = (_, __) {});
  tearDown(() => AnalyticsManager.debugEventSink = null);

  Future<(_HostState, FakeNavigationService)> pump(WidgetTester tester, PurchaseOutcome outcome) async {
    final nav = FakeNavigationService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        subscriptionProvider.overrideWith(() => _ScriptedSubscription(outcome)),
        navigationServiceProvider.overrideWithValue(nav),
      ],
      child: const MaterialApp(
        localizationsDelegates: [AppLocalizationsDelegate()],
        supportedLocales: [Locale('en')],
        locale: Locale('en'),
        home: Scaffold(body: _Host()),
      ),
    ));
    await tester.pump();
    return (tester.state<_HostState>(find.byType(_Host)), nav);
  }

  testWidgets('vazgeçme: mesaj yok, kutlama yok, ekran yerinde', (tester) async {
    final (state, nav) = await pump(tester, PurchaseOutcome.cancelled);

    await state.handlePurchase('plus');
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
    expect(nav.dialogs, isEmpty);
    expect(nav.gos, isEmpty);
  });

  testWidgets('gerçek hata: "satın alma başarısız"', (tester) async {
    final (state, nav) = await pump(tester, PurchaseOutcome.failed);

    await state.handlePurchase('premium');
    await tester.pump();

    expect(find.text('Purchase failed'), findsOneWidget);
    expect(nav.dialogs, isEmpty);
  });

  testWidgets('başarı: kutlama, sonra Elmaslar ekranı', (tester) async {
    final (state, nav) = await pump(tester, PurchaseOutcome.success);

    await state.handlePurchase('plus');
    await tester.pump();

    expect(nav.dialogs, ['subscription_celebration']);
    expect(nav.pops, 1);
    expect(nav.gos, [RouteNames.diamonds]);
    expect(find.byType(SnackBar), findsNothing);
  });
}
