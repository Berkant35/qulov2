import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/identity/identity_sheet_launcher.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../helpers/fake_navigation.dart';
import '../../helpers/fake_repositories.dart';

class _OpenButton extends ConsumerWidget {
  const _OpenButton(this.results);

  final List<bool> results;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    onPressed: () async =>
        results.add(await IdentitySheetLauncher.open(ref, entryPoint: 'profile_banner')),
    child: const Text('open'),
  );
}

Future<({FakeUserRepository repo, FakeNavigationService nav, List<bool> results})> _pump(
  WidgetTester tester, {
  AppFailure? getFailure,
}) async {
  final repo = FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'))
    ..identity = const IdentityModel(orientationLabels: ['gay'])
    ..identityGetFailure = getFailure;
  final nav = FakeNavigationService();
  final results = <bool>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(repo),
        navigationServiceProvider.overrideWithValue(nav),
      ],
      child: MaterialApp(home: Material(child: _OpenButton(results))),
    ),
  );
  return (repo: repo, nav: nav, results: results);
}

void main() {
  testWidgets(
    'kimlik yüklenemediyse sayfa açılmaz ve kayıt çağrısı olmaz; sonraki açılış yeniden dener',
    (tester) async {
      final h = await _pump(
        tester,
        getFailure: const ServerFailure(code: 'SERVER_ERROR', statusCode: 500),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      expect(h.nav.sheets, isEmpty);
      expect(h.repo.identityCalls, isEmpty);
      expect(h.results, [false], reason: 'çağıran hata göstersin diye açılmadı bilgisi döner');

      // Ağ düzelince aynı düğme sayfayı açar (hata önbelleğe takılıp kalmaz).
      h.repo.identityGetFailure = null;
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      expect(h.nav.sheets, ['identity_editor']);
      expect(h.results, [false, true]);
    },
  );

  testWidgets('kimlik yüklüyse sayfa identity_editor adıyla açılır', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    expect(h.nav.sheets, ['identity_editor']);
    expect(h.results, [true]);
  });
}
