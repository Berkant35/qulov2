import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/url_launcher_manager.dart';
import 'package:qulo_v2/data/models/app_config_model.dart';
import 'package:qulo_v2/features/splash/mixins/splash_screen_mixin.dart';
import 'package:qulo_v2/features/splash/splash_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';

import '../../helpers/fake_navigation.dart';

/// İsteğe bağlı güncelleme dialog'u açıkken splash kapanırsa (soğuk açılışta
/// deep link) eskiden "Güncelle" onayı `ref.read` StateError'ına düşüyor,
/// mağaza açılmıyordu.
class _HostSplash extends SplashScreen {
  const _HostSplash();

  @override
  ConsumerState<SplashScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<SplashScreen> with TickerProviderStateMixin, SplashScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

const _storeUrl = 'https://apps.apple.com/app/qulo';

class _OptionalUpdateConfig extends AppConfigNotifier {
  @override
  Future<UpdateStatus> checkVersion() async {
    state = state.copyWith(
      config: const AppConfigModel(
        minVersion: '2.0.0',
        latestVersion: '2.0.16',
        storeUrl: _storeUrl,
        isMaintenance: false,
        isForceUpdateEnabled: false,
      ),
    );
    return UpdateStatus.optionalUpdate;
  }

  @override
  Future<bool> isOptionalUpdateDismissed() async => false;
}

class _StaticEconomy extends EconomyConfigNotifier {
  @override
  Future<void> fetch() async {}
}

class _FakeUrlLauncher implements UrlLauncherManager {
  final launched = <String>[];

  @override
  Future<bool> launch(String url, {LaunchMode mode = LaunchMode.externalApplication}) async {
    launched.add(url);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeUrlLauncher.${invocation.memberName}');
}

void main() {
  setUp(() => AnalyticsManager.debugEventSink = (_, __) {});
  tearDown(() => AnalyticsManager.debugEventSink = null);

  testWidgets('güncelleme dialog\'u açıkken splash kapanırsa "Güncelle" yine mağazayı açar', (tester) async {
    final nav = FakeNavigationService()..dialogGate = Completer<void>();
    final launcher = _FakeUrlLauncher();
    final container = ProviderContainer(overrides: [
      navigationServiceProvider.overrideWithValue(nav),
      urlLauncherManagerProvider.overrideWithValue(launcher),
      appConfigProvider.overrideWith(_OptionalUpdateConfig.new),
      economyConfigProvider.overrideWith(_StaticEconomy.new),
    ]);
    addTearDown(container.dispose);
    Widget app(Widget home) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [AppLocalizationsDelegate()],
            supportedLocales: const [Locale('en')],
            locale: const Locale('en'),
            home: home,
          ),
        );

    await tester.pumpWidget(app(const _HostSplash()));
    await tester.pump();
    await tester.pump();
    expect(nav.dialogs, ['optional_update']);
    await tester.pumpWidget(app(const SizedBox()));
    nav.dialogGate!.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(launcher.launched, [_storeUrl]);
  });
}
