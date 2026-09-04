import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../helpers/fake_repositories.dart';

const _user = UserModel(
  id: 'u1',
  email: 'u1@qulo.test',
  purpleDiamonds: 50,
  greenDiamonds: 7,
);

ProviderContainer _container() {
  final container = ProviderContainer(overrides: [
    userRepositoryProvider.overrideWithValue(FakeUserRepository(_user)),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('UserNotifier.spendPurpleLocally', () {
    test('moru düşer, diğer alanlara dokunmaz', () async {
      final c = _container();
      await c.read(userProvider.notifier).fetchMe();

      c.read(userProvider.notifier).spendPurpleLocally(15);

      final user = c.read(userProvider).valueOrNull!;
      expect(user.purpleDiamonds, 35);
      expect(user.greenDiamonds, 7);
      expect(user.email, 'u1@qulo.test');
    });

    test('sıfırın altına inmez', () async {
      final c = _container();
      await c.read(userProvider.notifier).fetchMe();

      c.read(userProvider.notifier).spendPurpleLocally(80);

      expect(c.read(userProvider).valueOrNull!.purpleDiamonds, 0);
    });

    test('sıfır veya negatif miktar no-op', () async {
      final c = _container();
      await c.read(userProvider.notifier).fetchMe();

      c.read(userProvider.notifier).spendPurpleLocally(0);
      c.read(userProvider.notifier).spendPurpleLocally(-5);

      expect(c.read(userProvider).valueOrNull!.purpleDiamonds, 50);
    });

    test('kullanıcı yüklenmemişse sessizce geçer', () {
      final c = _container();

      c.read(userProvider.notifier).spendPurpleLocally(5);

      expect(c.read(userProvider).valueOrNull, isNull);
    });
  });
}
