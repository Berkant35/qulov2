import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/repositories/block_repository.dart';
import 'package:qulo_v2/features/profile_detail/mixins/profile_detail_screen_mixin.dart';
import 'package:qulo_v2/features/profile_detail/screens/profile_detail_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_navigation.dart';

/// Profil detayında engelleme: onay dialog'u açıkken ekran kapanırsa
/// (401 çıkışı, deep link) eskiden `.then` içindeki `ref.read` StateError
/// atıyordu — kullanıcının onayladığı engel sunucuya hiç gitmiyordu.
class _HostDetail extends ProfileDetailScreen {
  const _HostDetail() : super(userId: 'u-2');

  @override
  ConsumerState<ProfileDetailScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<ProfileDetailScreen> with ProfileDetailScreenMixin {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _FakeBlocks implements BlockRepository {
  final blocked = <String>[];

  @override
  Future<Result<void>> blockUser(String blockedId) async {
    blocked.add(blockedId);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeBlocks.${invocation.memberName}');
}

void main() {
  late FakeNavigationService nav;
  late _FakeBlocks blocks;
  late ProviderContainer container;

  Widget app(Widget home) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: home,
        ),
      );

  setUp(() {
    AnalyticsManager.debugEventSink = (_, __) {};
    nav = FakeNavigationService();
    blocks = _FakeBlocks();
    container = ProviderContainer(overrides: [
      navigationServiceProvider.overrideWithValue(nav),
      blockRepositoryProvider.overrideWithValue(blocks),
    ]);
    addTearDown(container.dispose);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  testWidgets('onay açıkken ekran kapanırsa onaylanan engel yine gider; kapalı ekran pop edilmez',
      (tester) async {
    await tester.pumpWidget(app(const _HostDetail()));
    await tester.pump();
    final state = tester.state<_HostState>(find.byType(_HostDetail));
    nav.dialogGate = Completer<void>();

    state.onBlock();
    await tester.pump();
    expect(nav.dialogs, ['block_user']);
    await tester.pumpWidget(app(const SizedBox()));
    nav.dialogGate!.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(blocks.blocked, ['u-2']);
    expect(nav.pops, 0);
  });

  testWidgets('açık ekranda onaylanan engel ekranı "blocked" ile kapatır', (tester) async {
    await tester.pumpWidget(app(const _HostDetail()));
    await tester.pump();
    final state = tester.state<_HostState>(find.byType(_HostDetail));

    state.onBlock();
    await tester.pump();

    expect(blocks.blocked, ['u-2']);
    expect(nav.pops, 1);
  });
}
