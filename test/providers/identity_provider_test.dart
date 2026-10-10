import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/identity_provider.dart';

import '../helpers/fake_repositories.dart';

void main() {
  Future<(ProviderContainer, FakeUserRepository)> harness({IdentityModel? initial}) async {
    final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'))
      ..identity = initial ?? IdentityModel.empty;
    final container = ProviderContainer(overrides: [userRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    container.listen(identityProvider, (_, __) {});
    await container.read(identityProvider.future);
    return (container, repo);
  }

  test('yükler', () async {
    final (container, _) = await harness(initial: const IdentityModel(orientationLabels: ['gay']));
    expect(container.read(identityProvider).value?.orientationLabels, ['gay']);
  });

  test('save rıza bayrağıyla gönderir ve durumu sunucu yanıtıyla günceller', () async {
    final (container, repo) = await harness();
    const next = IdentityModel(orientationLabels: ['bisexual']);
    final r = await container.read(identityProvider.notifier).save(next, consent: true);
    expect(r.isSuccess, isTrue);
    expect(repo.identityCalls.single, (identity: next, consent: true));
    expect(container.read(identityProvider).value, next);
  });

  test('mevcut etiketi düzenleme de rıza bayrağıyla gider (sunucu her kayıtta ister)', () async {
    final (container, repo) = await harness(initial: const IdentityModel(orientationLabels: ['gay']));
    const next = IdentityModel(orientationLabels: ['gay', 'queer'], showOrientationLabels: true);
    await container.read(identityProvider.notifier).save(next, consent: true);
    expect(repo.identityCalls.single, (identity: next, consent: true));
  });

  test('dolu etiket rızasız gönderilemez: ağa gitmeden IDENTITY_CONSENT_REQUIRED, durum değişmez', () async {
    final (container, repo) = await harness(initial: const IdentityModel(orientationLabels: ['gay']));
    final r = await container.read(identityProvider.notifier).save(const IdentityModel(orientationLabels: ['queer']), consent: false);
    expect(r, isA<Failure<IdentityModel>>());
    expect(((r as Failure<IdentityModel>).failure as ServerFailure).code, 'IDENTITY_CONSENT_REQUIRED');
    expect(repo.identityCalls, isEmpty);
    expect(container.read(identityProvider).value?.orientationLabels, ['gay']);
  });

  test('clear boş model + rızasız gönderir', () async {
    final (container, repo) = await harness(initial: const IdentityModel(orientationLabels: ['gay']));
    await container.read(identityProvider.notifier).clear();
    expect(repo.identityCalls.single, (identity: IdentityModel.empty, consent: false));
    expect(container.read(identityProvider).value?.isEmpty, isTrue);
  });

  test('sunucu hatası: durum değişmez, hata döner', () async {
    final (container, repo) = await harness(initial: const IdentityModel(orientationLabels: ['gay']));
    repo.identityFailure = const ServerFailure(code: 'IDENTITY_INVALID_LABEL', statusCode: 400);
    final r = await container.read(identityProvider.notifier).save(const IdentityModel(orientationLabels: ['queer']), consent: true);
    expect(r.isFailure, isTrue);
    expect(repo.identityCalls, hasLength(1));
    expect(container.read(identityProvider).value?.orientationLabels, ['gay']);
  });
}
