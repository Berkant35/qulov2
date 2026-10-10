import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
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

  group('UserNotifier.applyBalance', () {
    test('sunucunun bildirdiği üç bakiyeyi yazar, diğer alanlara dokunmaz', () async {
      final c = _container();
      await c.read(userProvider.notifier).fetchMe();

      c.read(userProvider.notifier).applyBalance(const DiamondBalance(green: 1, purple: 2, rainbow: 3));

      final user = c.read(userProvider).valueOrNull!;
      expect(user.greenDiamonds, 1);
      expect(user.purpleDiamonds, 2);
      expect(user.rainbowDiamonds, 3);
      expect(user.email, 'u1@qulo.test');
    });

    test('kullanıcı yüklenmemişse no-op', () {
      final c = _container();
      c.read(userProvider.notifier).applyBalance(const DiamondBalance(green: 1, purple: 2, rainbow: 3));
      expect(c.read(userProvider).valueOrNull, isNull);
    });
  });

  group('UserNotifier.reorderPhotos', () {
    const rainbowUser = UserModel(
      id: 'u1',
      email: 'u1@qulo.test',
      photos: ['a.jpg', 'b.jpg'],
      rainbowDiamonds: 12,
      rainbowEnabled: true,
    );

    ({ProviderContainer c, FakeUserRepository repo}) setUp({AppFailure? reorderFailure}) {
      final repo = FakeUserRepository(rainbowUser, reorderFailure: reorderFailure);
      final c = ProviderContainer(overrides: [userRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      return (c: c, repo: repo);
    }

    test('başarıda profil getMe ile tazelenir — PATCH yanıtı Rainbow alanlarını silmez', () async {
      final (:c, :repo) = setUp();
      await c.read(userProvider.notifier).fetchMe();
      final before = repo.getMeCallCount;

      final result = await c.read(userProvider.notifier).reorderPhotos(['b.jpg', 'a.jpg']);

      expect(repo.reorderPhotosCallCount, 1);
      expect(repo.getMeCallCount, before + 1);
      final user = c.read(userProvider).valueOrNull!;
      expect(user.rainbowEnabled, isTrue);
      expect(user.rainbowDiamonds, 12);
      expect((result as Success<UserModel>).data.photos, ['b.jpg', 'a.jpg'], reason: 'çağırana PATCH sonucu döner');
    });

    test('hatada getMe çağrılmaz, durum değişmez', () async {
      final (:c, :repo) = setUp(reorderFailure: const NetworkFailure());
      await c.read(userProvider.notifier).fetchMe();
      final before = repo.getMeCallCount;

      final result = await c.read(userProvider.notifier).reorderPhotos(['b.jpg', 'a.jpg']);

      expect(result.isSuccess, isFalse);
      expect(repo.getMeCallCount, before);
      expect(c.read(userProvider).valueOrNull, rainbowUser);
    });
  });
}
