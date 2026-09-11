import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../helpers/fake_repositories.dart';

/// Ayarlardaki e-posta bildirim anahtari. Sunucu sozlesmesi: PATCH
/// `/users/me/notification-preferences` `{email_matches}` (user.validator.ts
/// `notificationPreferencesSchema`); sunucu `email_notifications_enabled`
/// kolonunu da gunceller, anahtar profilden (`emailNotificationsEnabled`) okur.
const _user = UserModel(id: 'u1', email: 'u1@qulo.test');

Future<(ProviderContainer, FakeUserRepository)> _setup({AppFailure? failure}) async {
  final repo = FakeUserRepository(_user, prefsFailure: failure);
  final container = ProviderContainer(overrides: [userRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(container.dispose);
  await container.read(userProvider.notifier).fetchMe();
  return (container, repo);
}

void main() {
  test('tercih sozlesmedeki alanla gider ve basarida profil tazelenir', () async {
    final (c, repo) = await _setup();

    final result = await c.read(userProvider.notifier).setEmailNotifications(false);

    expect(result.isSuccess, isTrue);
    expect(repo.lastPrefsBody, {'email_matches': false});
    expect(repo.getMeCallCount, 2, reason: 'ilk yukleme + kayit sonrasi tazeleme');
  });

  test('hata cagirana doner — profil tazelenmez, istek tek kez gider', () async {
    final (c, repo) = await _setup(failure: const NetworkFailure());

    final result = await c.read(userProvider.notifier).setEmailNotifications(false);

    expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
    expect(repo.prefsCallCount, 1);
    expect(repo.getMeCallCount, 1, reason: 'yalnizca ilk yukleme');
  });
}
