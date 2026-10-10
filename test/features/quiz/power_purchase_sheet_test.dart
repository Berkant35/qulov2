import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/power_purchase.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/diamond_buy_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_quantity_stepper.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/quiz/widgets/power_purchase_sheet.dart';
import 'package:qulo_v2/features/quiz/widgets/power_sheet_balance_row.dart';
import 'package:qulo_v2/features/quiz/widgets/power_sheet_power_row.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../helpers/fake_repositories.dart';

const _half = ExchangeRatePower(name: 'HALF', baseCost: 10, greenCost: 30, purpleCost: 10);

/// Sayfanın açtığı alt sayfaları (paywall) kaydeder. Gerçek paywall RevenueCat +
/// router ister; burada yalnız "paywall açılması istendi mi" sorusu sınanır.
class _RecordingNavigationService implements NavigationService {
  final openedSheets = <String>[];

  @override
  Future<T?> showAppBottomSheet<T>(AppBottomSheet sheet) async {
    openedSheets.add(sheet.name);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_RecordingNavigationService.${invocation.memberName}');
}

typedef _Harness = ({
  FakeExchangeRepository exchange,
  FakeUserRepository users,
  _RecordingNavigationService nav,
});

/// [asModal]: sayfa, uygulamadaki gibi (`power_inventory_grid.dart`) bir host
/// sayfanın üstünde `showModalBottomSheet` ile açılır — kapanması (pop) gözlenebilir.
/// [textScale]: cihazın yazı boyutu ayarı (erişilebilirlik).
Future<_Harness> _pump(
  WidgetTester tester, {
  required bool rainbowEnabled,
  AppFailure? buyFailure,
  bool asModal = false,
  double textScale = 1,
  ExchangeRatePower power = _half,
}) async {
  final exchange = FakeExchangeRepository(
    rates: RatesResponse(convertRatio: 3, powers: [power]),
    buyPowerFailure: buyFailure,
  );
  final users = FakeUserRepository(
    UserModel(id: 'u1', email: 'u1@qulo.test', rainbowEnabled: rainbowEnabled),
  );
  final nav = _RecordingNavigationService();
  final container = ProviderContainer(overrides: [
    exchangeRepositoryProvider.overrideWithValue(exchange),
    diamondRepositoryProvider.overrideWithValue(
      FakeDiamondRepository(balance: const DiamondBalance(green: 4, purple: 75, rainbow: 12)),
    ),
    userRepositoryProvider.overrideWithValue(users),
    navigationServiceProvider.overrideWithValue(nav),
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: asModal
          ? const Scaffold(body: SizedBox.expand())
          : const Scaffold(body: SingleChildScrollView(child: PowerPurchaseSheet())),
    ),
  ));
  await tester.pump();
  if (asModal) {
    showModalBottomSheet<void>(
      context: tester.element(find.byType(Scaffold)),
      isScrollControlled: true,
      builder: (_) => const PowerPurchaseSheet(),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // açılış animasyonu
  }
  await tester.pump(const Duration(milliseconds: 100));
  return (exchange: exchange, users: users, nav: nav);
}

/// Satın alma butonuna dokunur; hata yanıtı + snackbar/pop animasyonu işlenir.
Future<void> _buy(WidgetTester tester, DiamondType type) async {
  await tester.tap(_buyButton(type));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Finder _rainbowIn(Finder parent) => find.descendant(
      of: parent,
      matching: find.byWidgetPredicate((w) => w is DiamondIcon && w.type == DiamondType.rainbow),
    );

Finder _buyButton(DiamondType type) => find.byWidgetPredicate(
      (w) => w is DiamondBuyButton && w.type == type,
    );

const _insufficient = ServerFailure(code: 'INSUFFICIENT_DIAMONDS', statusCode: 400);
const _rainbowUnavailable = ServerFailure(code: 'RAINBOW_NOT_AVAILABLE', statusCode: 403);

void main() {
  testWidgets('rainbow açıkken bakiye satırında Rainbow ve güçte Rainbow fiyatı', (tester) async {
    await _pump(tester, rainbowEnabled: true);

    expect(_rainbowIn(find.byType(PowerSheetBalanceRow)), findsOneWidget);
    expect(find.descendant(of: find.byType(PowerSheetBalanceRow), matching: find.text('12')), findsOneWidget);
    expect(_buyButton(DiamondType.rainbow), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rainbow kapalıyken hiçbir yerde Rainbow yok', (tester) async {
    await _pump(tester, rainbowEnabled: false);

    expect(_rainbowIn(find.byType(PowerSheetBalanceRow)), findsNothing);
    expect(_buyButton(DiamondType.rainbow), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Rainbow ile alım RAINBOW gönderir', (tester) async {
    final h = await _pump(tester, rainbowEnabled: true);

    await tester.tap(_buyButton(DiamondType.rainbow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(h.exchange.lastBuyDiamondType, 'RAINBOW');
    await tester.pumpWidget(const SizedBox());
  });

  group('satın alma hataları (para yolu)', () {
    testWidgets('Rainbow + yetersiz elmas → snackbar; sayfa açık kalır, paywall açılmaz', (tester) async {
      final h = await _pump(tester, rainbowEnabled: true, buyFailure: _insufficient, asModal: true);

      await _buy(tester, DiamondType.rainbow);

      expect(h.exchange.lastBuyDiamondType, 'RAINBOW');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Purchase failed'), findsOneWidget);
      expect(find.byType(PowerPurchaseSheet), findsOneWidget, reason: 'Rainbow satın alınamaz; sayfa kapanmamalı');
      expect(h.nav.openedSheets, isEmpty, reason: 'paywall yalnız mor için');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('mor + yetersiz elmas → sayfa kapanır ve paywall açılır', (tester) async {
      final h = await _pump(tester, rainbowEnabled: true, buyFailure: _insufficient, asModal: true);
      expect(find.byType(PowerPurchaseSheet), findsOneWidget);

      await _buy(tester, DiamondType.purple);

      expect(h.exchange.lastBuyDiamondType, 'PURPLE');
      expect(find.byType(PowerPurchaseSheet), findsNothing, reason: 'sayfa pop edilmeli');
      expect(h.nav.openedSheets, ['paywall']);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('RAINBOW_NOT_AVAILABLE → açıklayıcı snackbar + bayrak için getMe tazelenir', (tester) async {
      final h = await _pump(tester, rainbowEnabled: true, buyFailure: _rainbowUnavailable, asModal: true);
      expect(h.users.getMeCallCount, 1, reason: 'kurulumdaki fetchMe');

      await _buy(tester, DiamondType.rainbow);

      expect(find.text('Rainbow Diamonds are not available for your account right now.'), findsOneWidget);
      expect(h.users.getMeCallCount, 2);
      expect(find.byType(PowerPurchaseSheet), findsOneWidget);
      expect(h.nav.openedSheets, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('dar telefon yerleşimi (360×780 dp, yazı %130, Rainbow açık → 3 fiyat çipi)', () {
    /// Sayfayı küçük bir Android ekranında açar ve adedi [quantity]'ye çıkarır.
    Future<void> pumpNarrow(WidgetTester tester, ExchangeRatePower power, int quantity) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _pump(tester, rainbowEnabled: true, asModal: true, textScale: 1.3, power: power);
      final plus = find.descendant(of: find.byType(PowerQuantityStepper), matching: find.byIcon(Icons.add));
      for (var q = 1; q < quantity; q++) {
        await tester.tap(plus);
        await tester.pump();
      }
    }

    /// Etiket tek satırda, tam genişlikte — sütun ezilmemiş (eskiden 0 px'e iniyordu).
    void expectLabelOnOneLine(WidgetTester tester, String label) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.size.width, greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5));
    }

    void expectChipsInsideRow(WidgetTester tester) {
      final row = tester.getRect(find.byType(PowerSheetPowerRow));
      for (final type in DiamondType.values) {
        final chip = tester.getRect(_buyButton(type));
        expect(chip.left >= row.left && chip.right <= row.right, isTrue, reason: '$type çipi satır dışına taşıyor: $chip / $row');
      }
    }

    testWidgets('4 haneli fiyat (yeşil 30 × 34 = 1020) → taşma yok, etiket tek satır', (tester) async {
      await pumpNarrow(tester, _half, 34);

      expect(tester.widget<DiamondBuyButton>(_buyButton(DiamondType.green)).cost, 1020);
      expect(tester.takeException(), isNull);
      expect(find.text('50/50'), findsOneWidget);
      expectLabelOnOneLine(tester, '50/50');
      expectChipsInsideRow(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sunucu sınırı (maliyet 500 × adet 50 = 25000) → çipler alt satıra kayar, taşma yok', (tester) async {
      const priciest = ExchangeRatePower(name: 'HALF', baseCost: 500, greenCost: 500, purpleCost: 500);
      await pumpNarrow(tester, priciest, powerPurchaseMaxQuantity);

      expect(tester.widget<DiamondBuyButton>(_buyButton(DiamondType.rainbow)).cost, 25000);
      expect(tester.takeException(), isNull);
      expectLabelOnOneLine(tester, '50/50');
      expectChipsInsideRow(tester);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
