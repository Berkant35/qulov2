import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/diamond_buy_button.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/exchange/screens/exchange_screen.dart';
import 'package:qulo_v2/features/exchange/widgets/power_shop_card.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

import '../../helpers/fake_navigation.dart';
import '../../helpers/fake_repositories.dart';

/// Güç marketindeki TEK "Güçleri dene" ▶ ikonu: bölüm başlığının yanında, kart başına değil;
/// satın alma butonlarından ayrı dokunma alanında (yanlışlıkla harcama yok).
const _powers = [
  ExchangeRatePower(name: 'HALF', baseCost: 10, greenCost: 30, purpleCost: 10),
  ExchangeRatePower(name: 'HINT', baseCost: 6, greenCost: 18, purpleCost: 6),
];

class _Harness {
  final nav = FakeNavigationService();
  final exchange = FakeExchangeRepository(
    rates: const RatesResponse(convertRatio: 3, powers: _powers),
  );
  late final Finder demoIcon;

  Future<void> pump(WidgetTester tester, {required bool demoEnabled}) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final label = AppLocalizations(const Locale('en')).get('power_demo_try');
    demoIcon = find.byTooltip(label);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        exchangeRepositoryProvider.overrideWithValue(exchange),
        diamondRepositoryProvider.overrideWithValue(
          FakeDiamondRepository(balance: const DiamondBalance(green: 40, purple: 50)),
        ),
        userRepositoryProvider.overrideWithValue(FakeUserRepository(const UserModel(
          id: 'u1', email: 'u1@qulo.test', purpleDiamonds: 50, greenDiamonds: 40,
        ))),
        navigationServiceProvider.overrideWithValue(nav),
        powerDemoEnabledProvider.overrideWithValue(demoEnabled),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const ExchangeScreen(),
      ),
    ));
    // pumpAndSettle kullanılmaz: elmas parıltısı/envanter nabzı sonsuz animasyon.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('anahtar açık → ▶ görünür ve power-demo\'ya market ile gider', (tester) async {
    final h = _Harness();
    await h.pump(tester, demoEnabled: true);

    expect(h.demoIcon, findsOneWidget, reason: 'iki güç kartı var ama ▶ tek');
    await tester.tap(h.demoIcon);
    await tester.pump();

    expect(h.nav.pushes, hasLength(1));
    expect(h.nav.pushes.single.name, RouteNames.powerDemo);
    expect(h.nav.pushes.single.extra, PowerDemoEntryPoint.market);
  });

  testWidgets('anahtar kapalı → ▶ yok', (tester) async {
    final h = _Harness();
    await h.pump(tester, demoEnabled: false);

    expect(find.byType(PowerShopCard), findsNWidgets(2), reason: 'market yine açık');
    expect(h.demoIcon, findsNothing);
  });

  testWidgets('▶ satın alma butonlarını tetiklemez ve kartların içinde değil', (tester) async {
    final h = _Harness();
    await h.pump(tester, demoEnabled: true);

    expect(
      find.descendant(of: find.byType(PowerShopCard), matching: h.demoIcon),
      findsNothing,
      reason: '▶ kart başına değil; kartlardan ayrı dokunma alanı',
    );

    await tester.tap(h.demoIcon);
    await tester.pump(const Duration(milliseconds: 100));

    expect(h.exchange.buyPowerCallCount, 0);
    expect(h.exchange.lastBuyDiamondType, isNull);
    expect(find.byType(DiamondBuyButton), findsWidgets, reason: 'satın alma butonları yerinde');
  });
}
