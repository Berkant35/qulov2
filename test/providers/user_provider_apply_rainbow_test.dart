import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../helpers/fixed_user_notifier.dart';

void main() {
  test('applyRainbow yalnız Rainbow bakiyesini değiştirir', () async {
    final container = ProviderContainer(overrides: [
      userProvider.overrideWith(() => FixedUserNotifier(UserModel(
            id: 'u1', email: 'u1@qulo.test', greenDiamonds: 3, purpleDiamonds: 40, rainbowDiamonds: 1000,
            rainbowEnabled: true,
          ))),
    ]);
    addTearDown(container.dispose);
    await container.read(userProvider.future);
    container.read(userProvider.notifier).applyRainbow(949);
    final user = container.read(userProvider).requireValue!;
    expect(user.rainbowDiamonds, 949);
    expect(user.purpleDiamonds, 40);
    expect(user.greenDiamonds, 3);
    expect(user.rainbowEnabled, isTrue);
  });
}
