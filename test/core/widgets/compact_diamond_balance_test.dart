import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/compact_diamond_balance.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../helpers/fixed_user_notifier.dart';

Future<void> _pump(WidgetTester tester, UserModel user) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [userProvider.overrideWith(() => FixedUserNotifier(user))],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: CompactDiamondBalance()),
    ),
  ));
  await tester.pump();
}

Finder _rainbowIcon() =>
    find.byWidgetPredicate((w) => w is DiamondIcon && w.type == DiamondType.rainbow);

void main() {
  testWidgets('rainbow kapalıyken yalnız mor ve yeşil (bakiye arka planda birikir)', (tester) async {
    await _pump(tester, const UserModel(
      id: 'u1', email: 'u1@qulo.test', purpleDiamonds: 50, greenDiamonds: 7, rainbowDiamonds: 37,
    ));

    expect(find.text('50'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('37'), findsNothing);
    expect(_rainbowIcon(), findsNothing);
  });

  testWidgets('rainbow açıkken üçüncü çip', (tester) async {
    await _pump(tester, const UserModel(
      id: 'u1', email: 'u1@qulo.test', purpleDiamonds: 50, greenDiamonds: 7,
      rainbowDiamonds: 37, rainbowEnabled: true,
    ));

    expect(find.text('37'), findsOneWidget);
    expect(_rainbowIcon(), findsOneWidget);
  });
}
