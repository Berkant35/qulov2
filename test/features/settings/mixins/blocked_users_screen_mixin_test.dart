import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/repositories/block_repository.dart';
import 'package:qulo_v2/features/settings/mixins/blocked_users_screen_mixin.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_navigation.dart';

/// Engeli kaldırma: onay dialog'u açıkken ekran kapanırsa eskiden `ref.read`
/// StateError atıyordu — kullanıcının onayladığı işlem sunucuya hiç gitmiyordu.
class _FakeBlocks implements BlockRepository {
  final unblocked = <String>[];

  @override
  Future<Result<void>> unblockUser(String blockedId) async {
    unblocked.add(blockedId);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeBlocks.${invocation.memberName}');
}

int _listBuilds = 0;
final _listProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  _listBuilds++;
  return const ['u2'];
});

class _HostList extends ConsumerWidget with BlockedUsersScreenMixin {
  const _HostList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_listProvider);
    return TextButton(
      onPressed: () => confirmUnblock(context, ref, 'u2', _listProvider),
      child: const Text('unblock'),
    );
  }
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
          home: Material(child: home),
        ),
      );

  setUp(() {
    _listBuilds = 0;
    nav = FakeNavigationService();
    blocks = _FakeBlocks();
    container = ProviderContainer(overrides: [
      navigationServiceProvider.overrideWithValue(nav),
      blockRepositoryProvider.overrideWithValue(blocks),
    ]);
    addTearDown(container.dispose);
  });

  testWidgets('dialog açıkken ekran kapanırsa onaylanan işlem yine gider; ref kullanılmaz', (tester) async {
    await tester.pumpWidget(app(const _HostList()));
    await tester.pump();
    nav.dialogGate = Completer<void>();

    await tester.tap(find.text('unblock'));
    await tester.pump();
    expect(nav.dialogs, ['unblock_user']);
    await tester.pumpWidget(app(const SizedBox()));
    nav.dialogGate!.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(blocks.unblocked, ['u2']);
  });

  testWidgets('açık ekranda onaylanan işlem listeyi sunucudan tazeler', (tester) async {
    await tester.pumpWidget(app(const _HostList()));
    await tester.pump();
    expect(_listBuilds, 1);

    await tester.tap(find.text('unblock'));
    await tester.pump();
    await tester.pump();

    expect(blocks.unblocked, ['u2']);
    expect(_listBuilds, 2);
  });
}
