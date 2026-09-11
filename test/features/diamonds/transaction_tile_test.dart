import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/features/diamonds/widgets/transaction_tile.dart';
import 'package:qulo_v2/features/performance/widgets/diamond_transaction_tile.dart';

/// Elmas gecmisi satirlari kullaniciya ic kod gostermez.
///
/// Eskiden elmas ekrani (`DiamondsScreen` → `DiamondsTransactionHistory` →
/// `TransactionTile`) sebebi ve turu ham basiyordu: "PROFILE_COMPLETION",
/// "PURPLE". Performans ekrani tam eslesme aradigi icin "POWER_USED:HALF"
/// satirini "power used:half" yaziyordu.
///
/// `AppLocalizationsDelegate.load` async: ilk karede ceviriler hazir degil,
/// bu yuzden `pumpWidget`'tan sonra bir `pump` daha gerekir.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(body: Column(children: [child])),
  ));
  await tester.pump();
}

DiamondTransaction _tx(String reason, {String type = 'PURPLE', int amount = 50}) =>
    DiamondTransaction(
      id: 'tx-1',
      userId: 'u1',
      type: type,
      amount: amount,
      reason: reason,
      createdAt: '2026-09-10T18:22:04.123+00:00',
    );

void main() {
  group('TransactionTile (elmas ekrani)', () {
    testWidgets('sebep ve tur yerel etiketle gosterilir, ham kod yok', (tester) async {
      await _pump(tester, TransactionTile(transaction: _tx('PROFILE_COMPLETION')));

      expect(find.text('Profile Completion'), findsOneWidget);
      expect(find.text('Purple Diamonds'), findsOneWidget);
      expect(find.text('PROFILE_COMPLETION'), findsNothing);
      expect(find.text('PURPLE'), findsNothing);
    });

    testWidgets('ek almis odul sebebi ve yesil tur', (tester) async {
      await _pump(
        tester,
        TransactionTile(transaction: _tx('POWER_REWARD:ORACLE', type: 'GREEN', amount: 2)),
      );

      expect(find.text('Power Reward'), findsOneWidget);
      expect(find.text('Green Diamonds'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });
  });

  group('DiamondTransactionTile (performans ekrani)', () {
    testWidgets('ek almis sebep etiketlenir — "power used:half" yazmaz', (tester) async {
      await _pump(tester, DiamondTransactionTile(transaction: _tx('POWER_USED:HALF', amount: -23)));

      expect(find.text('Power Used'), findsOneWidget);
      expect(find.text('power used:half'), findsNothing);
      expect(find.text('-23'), findsOneWidget);
    });

    testWidgets('bilinmeyen sebep genel etikete duser', (tester) async {
      await _pump(tester, DiamondTransactionTile(transaction: _tx('SOMETHING_NEW')));

      expect(find.text('Diamond Transaction'), findsOneWidget);
      expect(find.text('something new'), findsNothing);
    });
  });
}
