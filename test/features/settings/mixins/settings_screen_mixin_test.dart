import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/app_info_manager.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/settings/mixins/settings_screen_mixin.dart';
import 'package:qulo_v2/features/settings/models/deletion_reason.dart';
import 'package:qulo_v2/features/settings/screens/settings_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Hesap silme: neden sayfası → yıkıcı onay → sil + çıkış. Onay dialog'u
/// açıkken ekran kapanırsa (401 çıkışı, deep link) eskiden `ref.read`
/// StateError atıyordu: kullanıcının onayladığı silme sunucuya HİÇ gitmiyordu.
class _HostSettings extends SettingsScreen {
  const _HostSettings();

  @override
  ConsumerState<SettingsScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<SettingsScreen> with SettingsScreenMixin {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _DeletingRepo extends FakeUserRepository {
  _DeletingRepo(super.user);

  final deletions = <({String? reasonCode, String? appVersion})>[];

  @override
  Future<Result<void>> deleteAccount({
    String? reasonCode,
    String? reasonText,
    String? appVersion,
    String? platform,
    String? locale,
  }) async {
    deletions.add((reasonCode: reasonCode, appVersion: appVersion));
    return const Success(null);
  }
}

class _FakeAppInfo implements AppInfoManager {
  @override
  Future<String> get version async => '2.0.15';

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeAppInfo.${invocation.memberName}');
}

class _CountingAuth extends AuthNotifier {
  int logouts = 0;

  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);

  @override
  Future<void> logout() async => logouts++;
}

void main() {
  final events = <String>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events.clear();
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  Widget app(ProviderContainer container, Widget home) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: home,
        ),
      );

  Future<(_HostState, ProviderContainer, _DeletingRepo, FakeNavigationService, _CountingAuth)> pump(
    WidgetTester tester,
  ) async {
    final repo = _DeletingRepo(UserModel(id: 'u1', email: 'u1@qulo.test'));
    final nav = FakeNavigationService()
      ..sheetAnswer = const DeleteReasonResult(reasonCode: 'few_matches');
    final auth = _CountingAuth();
    final container = ProviderContainer(overrides: [
      userRepositoryProvider.overrideWithValue(repo),
      navigationServiceProvider.overrideWithValue(nav),
      appInfoManagerProvider.overrideWithValue(_FakeAppInfo()),
      authProvider.overrideWith(() => auth),
    ]);
    addTearDown(container.dispose);
    await container.read(userProvider.notifier).fetchMe();
    await tester.pumpWidget(app(container, const _HostSettings()));
    await tester.pump();
    return (tester.state<_HostState>(find.byType(_HostSettings)), container, repo, nav, auth);
  }

  testWidgets('onay dialog\'u açıkken ekran kapanırsa onaylanan silme yine gider + çıkış yapılır',
      (tester) async {
    final (state, container, repo, nav, auth) = await pump(tester);
    nav.dialogGate = Completer<void>();

    final deleting = state.onDeleteAccount();
    await tester.pump();
    expect(nav.dialogs, ['delete_account']);
    await tester.pumpWidget(app(container, const SizedBox()));
    nav.dialogGate!.complete();
    await deleting;

    expect(tester.takeException(), isNull);
    expect(repo.deletions, [(reasonCode: 'few_matches', appVersion: '2.0.15')]);
    expect(auth.logouts, 1);
    expect(events, contains(AnalyticsEvents.settingsDeleteAccountReason));
  });

  testWidgets('neden sayfası kapatılırsa (iptal) hiçbir şey silinmez', (tester) async {
    final (state, _, repo, nav, auth) = await pump(tester);
    nav.sheetAnswer = null;

    await state.onDeleteAccount();

    expect(nav.dialogs, isEmpty);
    expect(repo.deletions, isEmpty);
    expect(auth.logouts, 0);
  });
}
