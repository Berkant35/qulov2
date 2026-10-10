import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/observers/route_change_notifier.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/repositories/quiz_repository.dart';
import 'package:qulo_v2/features/quiz/coach/quiz_power_coach_marks.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_state_mixin.dart';
import 'package:qulo_v2/features/quiz/screens/quiz_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

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

void main() {
  final cta = AppLocalizations(const Locale('en')).get('coach_cta_got_it');

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CoachMarkService.instance.forceClose());

  Future<_FakeQuizRepository> pumpQuiz(WidgetTester tester) async {
    final repo = _FakeQuizRepository();
    final container = ProviderContainer(overrides: [
      quizRepositoryProvider.overrideWithValue(repo),
      exchangeRepositoryProvider.overrideWithValue(FakeExchangeRepository()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorObservers: [RouteChangeObserver()],
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const _HostScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('ilk quiz: tur kapanmadan oturum açılmaz (sunucu süresi başlamaz)',
      (tester) async {
    final repo = await pumpQuiz(tester);

    expect(find.text(cta), findsOneWidget, reason: 'güç turu açık');
    expect(repo.startCalls, 0);

    await tester.tap(find.text(cta));
    await tester.pumpAndSettle();

    expect(repo.startCalls, 1);
  });

  testWidgets('turu görmüş kullanıcıda oturum hemen açılır', (tester) async {
    await CoachMarkService.instance.markSeen(quizPowersTourId);

    final repo = await pumpQuiz(tester);

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
