import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/data/repositories/subscription_repository.dart';
import 'package:qulo_v2/features/ads/domain/ad_audience.dart';
import 'package:qulo_v2/features/ads/providers/ad_audience_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

/// VIP (aktif Plus/Premium) reklam görmez; durum bilinmiyorsa da görmez (fail-closed).
class _AuthedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository(this.result);
  Result<SubscriptionInfo> result;
  int calls = 0;

  @override
  Future<Result<SubscriptionInfo>> getStatus() async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeSubscriptionRepository.${invocation.memberName}');
}

class _FixedSubscription extends SubscriptionNotifier {
  _FixedSubscription(this.info);
  final SubscriptionInfo info;

  @override
  Future<SubscriptionInfo> build() async => info;
}

const _plus = SubscriptionInfo(plan: 'plus', status: 'active', isActive: true);
const _premium = SubscriptionInfo(plan: 'premium', status: 'active', isActive: true);
const _expired = SubscriptionInfo(plan: 'plus', status: 'expired', isActive: false);

Future<AdAudience> _audience({
  required Result<SubscriptionInfo> serverStatus,
  SubscriptionInfo providerInfo = const SubscriptionInfo(),
  bool adsEnabled = true,
  bool authed = true,
  _FakeSubscriptionRepository? repo,
}) async {
  final container = ProviderContainer(overrides: [
    adsEnabledProvider.overrideWithValue(adsEnabled),
    if (authed) authProvider.overrideWith(_AuthedNotifier.new),
    subscriptionRepositoryProvider.overrideWithValue(repo ?? _FakeSubscriptionRepository(serverStatus)),
    subscriptionProvider.overrideWith(() => _FixedSubscription(providerInfo)),
  ]);
  addTearDown(container.dispose);
  container.listen(subscriptionProvider, (_, _) {});
  await container.read(subscriptionProvider.future);
  return container.read(adAudienceProvider.future);
}

void main() {
  group('audienceFromStatus', () {
    test('aktif abonelik → vip (Plus ve Premium)', () {
      expect(audienceFromStatus(const Success(_plus)), AdAudience.vip);
      expect(audienceFromStatus(const Success(_premium)), AdAudience.vip);
    });

    test('süresi dolmuş / abonelik yok → free', () {
      expect(audienceFromStatus(const Success(_expired)), AdAudience.free);
      expect(audienceFromStatus(Success(SubscriptionInfo.free())), AdAudience.free);
    });

    test('hata → unknown (fail-closed; free DEĞİL)', () {
      expect(audienceFromStatus(const Failure(NetworkFailure())), AdAudience.unknown);
    });
  });

  group('adAudienceProvider', () {
    test('sunucu aboneliksiz derse free', () async {
      expect(await _audience(serverStatus: Success(SubscriptionInfo.free())), AdAudience.free);
    });

    test('sunucu aktif abonelik derse vip', () async {
      expect(await _audience(serverStatus: const Success(_plus)), AdAudience.vip);
    });

    test('abonelik sorgusu ağ hatasıyla düşerse unknown — abone "ücretsiz" sanılmaz', () async {
      expect(await _audience(serverStatus: const Failure(NetworkFailure())), AdAudience.unknown);
    });

    test('uygulamanın abonelik provider\'ı aktif diyorsa sunucuya sorulmadan vip', () async {
      final repo = _FakeSubscriptionRepository(Success(SubscriptionInfo.free()));

      final a = await _audience(
        serverStatus: Success(SubscriptionInfo.free()),
        providerInfo: _premium,
        repo: repo,
      );

      expect(a, AdAudience.vip);
      expect(repo.calls, 0);
    });

    test('uzaktan anahtar kapalıyken HİÇ istek atılmaz', () async {
      final repo = _FakeSubscriptionRepository(Success(SubscriptionInfo.free()));

      final a = await _audience(serverStatus: Success(SubscriptionInfo.free()), adsEnabled: false, repo: repo);

      expect(a, AdAudience.unknown);
      expect(repo.calls, 0);
    });

    test('oturum yokken unknown ve istek yok', () async {
      final repo = _FakeSubscriptionRepository(Success(SubscriptionInfo.free()));

      final a = await _audience(serverStatus: Success(SubscriptionInfo.free()), authed: false, repo: repo);

      expect(a, AdAudience.unknown);
      expect(repo.calls, 0);
    });
  });
}
