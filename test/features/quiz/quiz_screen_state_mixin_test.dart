import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/observers/route_change_notifier.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/quiz_repository.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/quiz/coach/quiz_power_coach_marks.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_state_mixin.dart';
import 'package:qulo_v2/features/quiz/screens/quiz_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

import '../../helpers/fake_navigation.dart';
import '../../helpers/fixed_user_notifier.dart';
import '../../helpers/fake_repositories.dart';

/// İlk quiz'de güç turu oturum AÇILMADAN gösterilir. Eskiden tur ilk sorunun
/// üstünde açılıyor, yalnız istemci sayacını durduruyordu; sunucunun
/// `expires_at`'ı (soru süreleri toplamı + 10 sn) işlemeye devam ediyordu →
/// yavaş okuyan kullanıcı ilk quiz'inde TIME_UP alabiliyordu.
class _HostScreen extends QuizScreen {
  const _HostScreen() : super(targetId: 'target-1');

  @override
  ConsumerState<QuizScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<QuizScreen> with QuizScreenStateMixin {
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
  Widget build(BuildContext context) => const Scaffold(body: Text('quiz'));
}

/// `power-demo` route'unu gerçek bir Navigator rotası olarak açar: tur overlay'i route-aware
/// gizlenir/geri gelir. Demo "kapanınca" (pop) `push` Future'ı tamamlanır — `await nav.push` gibi.
class _RouteNav extends FakeNavigationService {
  _RouteNav(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<T?> push<T extends Object?>(String name, {Map<String, String>? params, Object? extra}) {
    pushes.add((name: name, extra: extra));
    return navigatorKey.currentState!.push<T>(
      MaterialPageRoute<T>(builder: (_) => const Scaffold(body: Text('demo'))),
    );
  }
}

typedef _Quiz = ({_FakeQuizRepository repo, _RouteNav nav, GlobalKey<NavigatorState> navigatorKey});

void main() {
  final l10n = AppLocalizations(const Locale('en'));
  final cta = l10n.get('coach_cta_got_it');
  final tryPowers = l10n.get('power_demo_try');

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CoachMarkService.instance.forceClose());

  Future<_Quiz> pumpQuiz(WidgetTester tester, {bool demoEnabled = true, UserModel? user}) async {
    final repo = _FakeQuizRepository();
    final navigatorKey = GlobalKey<NavigatorState>();
    final nav = _RouteNav(navigatorKey);
    final container = ProviderContainer(overrides: [
      quizRepositoryProvider.overrideWithValue(repo),
      exchangeRepositoryProvider.overrideWithValue(FakeExchangeRepository()),
      navigationServiceProvider.overrideWithValue(nav),
      powerDemoEnabledProvider.overrideWithValue(demoEnabled),
      if (user != null) userProvider.overrideWith(() => FixedUserNotifier(user)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [RouteChangeObserver()],
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const _HostScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return (repo: repo, nav: nav, navigatorKey: navigatorKey);
  }

  testWidgets('ilk quiz: tur kapanmadan oturum açılmaz (sunucu süresi başlamaz)',
      (tester) async {
    final repo = (await pumpQuiz(tester)).repo;

    expect(find.text(cta), findsOneWidget, reason: 'güç turu açık');
    expect(repo.startCalls, 0);

    await tester.tap(find.text(cta));
    await tester.pumpAndSettle();

    expect(repo.startCalls, 1);
  });

  // Demo, turun ÜSTÜNE açılır; turu kapatıp sonra açmak `runTour`u bitirir → `startSession` demo
  // sırasında açılır → sunucu süresi (`expires_at`) akar → quiz FAILED. Oturum yalnız demodan
  // dönüp turu bitirince açılmalı.
  testWidgets('tur kartındaki Güçleri dene → demo route push, startCalls 0', (tester) async {
    final q = await pumpQuiz(tester);

    await tester.tap(find.text(tryPowers));
    await tester.pumpAndSettle();

    expect(q.nav.pushes, hasLength(1));
    expect(q.nav.pushes.single.name, RouteNames.powerDemo);
    expect(q.nav.pushes.single.extra, PowerDemoEntryPoint.quizIntro);
    expect(find.text('demo'), findsOneWidget, reason: 'demo turun üstünde açık');
    // Tur overlay'i route-aware: demo üstteyken kart (ve CTA'sı) görünmez — demoya basılı kalmaz,
    // yanlışlıkla CTA'ya basılıp oturum (sunucu süresi) açılamaz.
    expect(find.text(cta), findsNothing, reason: 'tur kartı demo sürerken gizli');
    expect(CoachMarkService.instance.isTourActive, isTrue, reason: 'tur kapatılmadı');
    expect(q.repo.startCalls, 0, reason: 'demo sürerken oturum (sunucu süresi) başlamaz');
  });

  testWidgets('demodan pop → hâlâ 0; tur CTA → 1', (tester) async {
    final q = await pumpQuiz(tester);
    await tester.tap(find.text(tryPowers));
    await tester.pumpAndSettle();

    q.navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('demo'), findsNothing);
    expect(find.text(cta), findsOneWidget, reason: 'demodan dönünce tur kartı hâlâ açık');
    expect(q.repo.startCalls, 0, reason: 'demodan dönmek oturumu açmaz; CTA açar');

    await tester.tap(find.text(cta));
    await tester.pumpAndSettle();

    expect(q.repo.startCalls, 1);
  });

  testWidgets('küçük ekranda (375×667) bağlantı + cüzdan satırlı tur kartı taşmaz, düğmeler görünür', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Yeni hesaba 30 başlangıç moru verilir: cüzdan satırı gerçekte hep görünür.
    await pumpQuiz(tester, user: const UserModel(id: 'u1', email: 'u1@qulo.test', purpleDiamonds: 30));

    expect(tester.takeException(), isNull);
    final screen = tester.getRect(find.byType(MaterialApp));
    for (final label in [tryPowers, cta]) {
      final rect = tester.getRect(find.text(label));
      expect(screen.contains(rect.center), isTrue, reason: '"$label" ekranın içinde');
    }
  });

  testWidgets('anahtar kapalı → tur kartında Güçleri dene bağlantısı yok', (tester) async {
    final q = await pumpQuiz(tester, demoEnabled: false);

    expect(find.text(cta), findsOneWidget, reason: 'tur kartı yine açık');
    expect(find.text(tryPowers), findsNothing);
    expect(q.nav.pushes, isEmpty);
  });

  testWidgets('turu görmüş kullanıcıda oturum hemen açılır', (tester) async {
    await CoachMarkService.instance.markSeen(quizPowersTourId);

    final repo = (await pumpQuiz(tester)).repo;

    expect(find.text(cta), findsNothing);
    expect(repo.startCalls, 1);
  });
}

class _FakeQuizRepository implements QuizRepository {
  int startCalls = 0;

  // Hata dönüşü soru yükleme/sayaç zincirini başlatmaz — test yalnız
  // oturumun NE ZAMAN açıldığını ölçer.
  @override
  Future<Result<QuizStartResponse>> startSession(String targetId) async {
    startCalls++;
    return const Failure(NetworkFailure());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeQuizRepository.${invocation.memberName}');
}
