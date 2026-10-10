import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/rainbow_flag.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../helpers/fixed_user_notifier.dart';

class _Probe extends ConsumerWidget {
  const _Probe();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Text(
        '${ref.watchRainbowEnabled()}|${ref.watchGiftCardsVisible()}',
        textDirection: TextDirection.ltr,
      );
}

Future<String> _read(WidgetTester tester, {required bool enabled, required bool redeemed}) async {
  // Aynı testte ardışık pumpWidget çağrıları arasında eski ProviderScope
  // Element'i (ve içindeki ProviderContainer) State güncellemesiyle hayatta
  // kalır — yeni overrides `didUpdateWidget` ile her zaman uygulanmıyor
  // (kanıt: aynı senaryo tek başına çalışıyor, ardışık ikinci çağrıda önceki
  // override sızıyor). Aradaki boş pumpWidget eski Element'i tamamen söker.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(ProviderScope(
    overrides: [
      userProvider.overrideWith(() => FixedUserNotifier(UserModel(
            id: 'u1', email: 'u1@qulo.test', rainbowEnabled: enabled, hasRewardRedemptions: redeemed,
          ))),
    ],
    child: const _Probe(),
  ));
  await tester.pumpAndSettle();
  return tester.widget<Text>(find.byType(Text)).data!;
}

void main() {
  testWidgets('bayrak matrisi', (tester) async {
    expect(await _read(tester, enabled: false, redeemed: false), 'false|false');
    expect(await _read(tester, enabled: false, redeemed: true), 'false|true');
    expect(await _read(tester, enabled: true, redeemed: false), 'true|true');
  });
}
