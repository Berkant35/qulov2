import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';
import 'package:qulo_v2/data/repositories/subscription_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

/// Logout sırasında provider'lar invalidate edilirken alttaki ekranlar hâlâ
/// dinlediği için notifier'lar token'sız istek atıyordu (401 → Crashlytics).
/// Kimliksizken ağa çıkılmamalı.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._status);
  final AuthStatus _status;

  @override
  AuthState build() => AuthState(status: _status);
}

class _CountingMatchRepository implements MatchRepository {
  int calls = 0;

  @override
  Future<Result<List<MatchModel>>> getMatches() async {
    calls++;
    return const Success(<MatchModel>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_CountingMatchRepository.${invocation.memberName}');
}

class _CountingSubscriptionRepository implements SubscriptionRepository {
  int calls = 0;

  @override
  Future<Result<SubscriptionInfo>> getStatus() async {
    calls++;
    return Success(SubscriptionInfo.free());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_CountingSubscriptionRepository.${invocation.memberName}');
}

ProviderContainer _unauthenticatedContainer({
  required _CountingMatchRepository matchRepo,
  required _CountingSubscriptionRepository subRepo,
}) {
  final container = ProviderContainer(overrides: [
    authProvider.overrideWith(() => _FakeAuthNotifier(AuthStatus.unauthenticated)),
    matchRepositoryProvider.overrideWithValue(matchRepo),
    subscriptionRepositoryProvider.overrideWithValue(subRepo),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('kimliksizken eşleşme listesi ağa çıkmaz, boş döner', () async {
    final matchRepo = _CountingMatchRepository();
    final container = _unauthenticatedContainer(
      matchRepo: matchRepo,
      subRepo: _CountingSubscriptionRepository(),
    );

    final matches = await container.read(matchListProvider.future);

    expect(matches, isEmpty);
    expect(matchRepo.calls, 0);
  });

  test('kimliksizken abonelik durumu ağa çıkmaz, free döner', () async {
    final subRepo = _CountingSubscriptionRepository();
    final container = _unauthenticatedContainer(
      matchRepo: _CountingMatchRepository(),
      subRepo: subRepo,
    );

    final info = await container.read(subscriptionProvider.future);

    expect(info.isPlus, isFalse);
    expect(info.isPremium, isFalse);
    expect(subRepo.calls, 0);
  });
}
