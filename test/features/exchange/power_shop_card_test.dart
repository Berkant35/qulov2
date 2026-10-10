import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/diamond_buy_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/exchange/widgets/power_shop_card.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../helpers/fake_repositories.dart';

const _half = ExchangeRatePower(name: 'HALF', baseCost: 10, greenCost: 30, purpleCost: 10);
const _after = DiamondBalance(green: 40, purple: 50, rainbow: 40);

Future<({ProviderContainer container, FakeExchangeRepository exchange, FakeUserRepository user})>
    _setup(WidgetTester tester, {AppFailure? failure}) async {
  final exchange = FakeExchangeRepository(buyPowerFailure: failure, buyPowerBalance: _after);
  final user = FakeUserRepository(const UserModel(
    id: 'u1', email: 'u1@qulo.test', purpleDiamonds: 50, greenDiamonds: 40,
    rainbowDiamonds: 70, rainbowEnabled: true,
  ));
  final container = ProviderContainer(overrides: [
    exchangeRepositoryProvider.overrideWithValue(exchange),
    diamondRepositoryProvider.overrideWithValue(FakeDiamondRepository(balance: _after)),
    userRepositoryProvider.overrideWithValue(user),
  ]);
  addTearDown(container.dispose);
  await container.read(userProvider.notifier).fetchMe();

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: const Scaffold(body: PowerShopCard(power: _half, inventoryCount: 0)),
    ),
  ));
  await tester.pump();
  return (container: container, exchange: exchange, user: user);
}

Finder _buy(DiamondType type) =>
    find.byWidgetPredicate((w) => w is DiamondBuyButton && w.type == type);

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('Rainbow ile alım RAINBOW gönderir, AppBar bakiyesi sunucu değeriyle güncellenir', (tester) async {
    final s = await _setup(tester);

    await _tapAndSettle(tester, _buy(DiamondType.rainbow));

    expect(s.exchange.lastBuyDiamondType, 'RAINBOW');
    expect(s.container.read(userProvider).valueOrNull!.rainbowDiamonds, 40);
  });

  testWidgets('RAINBOW_NOT_AVAILABLE: uyarı gösterilir ve bayrak sunucudan tazelenir', (tester) async {
    final s = await _setup(
      tester,
      failure: const ServerFailure(code: 'RAINBOW_NOT_AVAILABLE', statusCode: 403),
    );

    await _tapAndSettle(tester, _buy(DiamondType.rainbow));

    expect(find.text('Rainbow Diamonds are not available for your account right now.'), findsOneWidget);
    expect(s.user.getMeCallCount, 2);
  });

  testWidgets('yetersiz Rainbow: "elmas al" yönlendirmesi yok (Rainbow satın alınamaz)', (tester) async {
    await _setup(
      tester,
      failure: const ServerFailure(
        code: 'INSUFFICIENT_DIAMONDS', statusCode: 403, params: {'required': 30, 'current': 5},
      ),
    );

    await _tapAndSettle(tester, _buy(DiamondType.rainbow));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
  });

  testWidgets('yetersiz mor: "elmas al" yönlendirmesi korunur', (tester) async {
    await _setup(
      tester,
      failure: const ServerFailure(
        code: 'INSUFFICIENT_DIAMONDS', statusCode: 403, params: {'required': 10, 'current': 5},
      ),
    );

    await _tapAndSettle(tester, _buy(DiamondType.purple));

    expect(find.byType(SnackBarAction), findsOneWidget);
  });
}
