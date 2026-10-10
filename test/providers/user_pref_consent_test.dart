import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../helpers/fake_repositories.dart';

void main() {
  Future<(ProviderContainer, FakeUserRepository)> harness() async {
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'));
    final container = ProviderContainer(overrides: [userRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    // Riverpod 3 izlenmeyen provider'ı duraklatır — dinleyici tutulur.
    container.listen(userProvider, (_, _) {});
    await container.read(userProvider.future);
    return (container, repo);
  }

  test('başarıda sunucuya durum + tercih gider ve kullanıcı tazelenir', () async {
    final (container, repo) = await harness();
    final before = repo.getMeCallCount;

    final result = await container.read(userProvider.notifier)
        .setPrefConsent(status: PrefConsent.granted, genderPref: 'WOMAN');

    expect(result.isSuccess, isTrue);
    expect(repo.prefConsentCalls.single, (status: 'GRANTED', genderPref: 'WOMAN'));
    expect(repo.getMeCallCount, before + 1);
  });

  test('hata olursa kullanıcı tazelenmez, hata döner', () async {
    final (container, repo) = await harness();
    repo.prefConsentFailure = const ServerFailure(code: 'CONSENT_RELOCK', statusCode: 409);
    final before = repo.getMeCallCount;

    final result = await container.read(userProvider.notifier).setPrefConsent(status: PrefConsent.granted);

    expect(result.isFailure, isTrue);
    expect(repo.getMeCallCount, before);
  });
}
