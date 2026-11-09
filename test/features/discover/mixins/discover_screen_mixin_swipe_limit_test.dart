import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';
import 'package:qulo_v2/features/discover/mixins/discover_screen_mixin.dart';
import 'package:qulo_v2/features/discover/screens/discover_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';

import '../../../helpers/fake_navigation.dart';

/// Reddi günlük hak (403 DAILY_LIMIT_EXCEEDED) yüzünden sunucuya düşmeyen kart
/// desteye döner; paywall'u EKRAN açar — kart görünümü uçuş animasyonundan
/// sonra ağaçtan çıktığı için sinyal orada dinlenemez.
class _HostScreen extends DiscoverScreen {
  const _HostScreen();

  @override
  ConsumerState<DiscoverScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<DiscoverScreen> with DiscoverScreenMixin {
  @override
  void initState() {
    super.initState();
    listenSwipeLimit();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('red gunluk hakka takilinca swipe_limit paywall\'u bir kez acilir', (tester) async {
    AnalyticsManager.debugEventSink = (_, _) {};
    addTearDown(() => AnalyticsManager.debugEventSink = null);
    final repo = _LimitedMatchRepository();
    final nav = FakeNavigationService();
    final container = ProviderContainer(overrides: [
      matchRepositoryProvider.overrideWithValue(repo),
      navigationServiceProvider.overrideWithValue(nav),
    ]);
    addTearDown(container.dispose);
    await container.read(discoverProvider.future);
    await container.read(discoverProvider.notifier).loadCards();

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: _HostScreen()),
    ));
    expect(nav.sheets, isEmpty);

    container.read(discoverProvider.notifier).rejectCard('a');
    await tester.pump();
    await tester.pump();

    expect(nav.sheets, ['paywall']);

    // Ilgisiz durum degisimi (yeniden yukleme) paywall'u tekrar acmaz.
    await container.read(discoverProvider.notifier).loadCards();
    await tester.pump();
    expect(nav.sheets, ['paywall']);
  });
}

class _LimitedMatchRepository implements MatchRepository {
  @override
  Future<Result<DiscoverResponse>> discover({int page = 1}) async => Success(DiscoverResponse(
        cards: [
          for (final id in ['a', 'b', 'c', 'd', 'e'])
            ProfileCardModel(userId: id, questionCount: 2, distanceKm: 10, distanceTier: 0),
        ],
        page: 1,
        hasMore: true,
      ));

  @override
  Future<Result<SwipeResponse>> swipe({required String targetId, required String action}) async =>
      const Failure(ServerFailure(code: 'DAILY_LIMIT_EXCEEDED', statusCode: 403));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_LimitedMatchRepository.${invocation.memberName}');
}
