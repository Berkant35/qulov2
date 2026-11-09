import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/notification_manager.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/notifications/mixins/push_permission_offer_mixin.dart';
import 'package:qulo_v2/features/profile/mixins/questions_screen_mixin.dart';
import 'package:qulo_v2/features/profile/screens/questions_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Soru silme onayı açıkken ekran kapanırsa (401 çıkışı, deep link) eskiden
/// `.then` içindeki `ref.read` StateError atıyordu: onaylanan silme gitmiyordu.
class _HostQuestions extends QuestionsScreen {
  const _HostQuestions();

  @override
  ConsumerState<QuestionsScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<QuestionsScreen>
    with PushPermissionOfferMixin<QuestionsScreen>, QuestionsScreenMixin {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

const _question = QuestionModel(
  id: 'q3',
  userId: 'u1',
  orderNum: 3,
  questionText: 'En sevdiğim şehir?',
  correctAnswer: 1,
  answer1: 'İzmir',
  answer2: 'Roma',
  answer3: 'Lima',
  answer4: 'Oslo',
);

void main() {
  setUp(() => AnalyticsManager.debugEventSink = (_, __) {});
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

  testWidgets('silme onayı açıkken ekran kapanırsa onaylanan silme yine gider', (tester) async {
    final questions = FakeQuestionRepository(questions: const [_question]);
    final nav = FakeNavigationService()..dialogGate = Completer<void>();
    final container = ProviderContainer(overrides: [
      questionRepositoryProvider.overrideWithValue(questions),
      userRepositoryProvider.overrideWithValue(FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'))),
      navigationServiceProvider.overrideWithValue(nav),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(app(container, const _HostQuestions()));
    await tester.pump();
    final state = tester.state<_HostState>(find.byType(_HostQuestions));

    final deleting = state.deleteQuestion(_question);
    await tester.pump();
    expect(nav.dialogs, ['delete_question']);
    await tester.pumpWidget(app(container, const SizedBox()));
    nav.dialogGate!.complete();
    await deleting;

    expect(tester.takeException(), isNull);
    expect(questions.deletedOrderNums, [3]);
  });

  group('soru kutlaması → bildirim izni (2.0.18)', () {
    Future<_HostState> pumpHost(WidgetTester tester, _OrderedNav nav, {bool canRequest = true}) async {
      final container = ProviderContainer(overrides: [
        questionRepositoryProvider.overrideWithValue(FakeQuestionRepository(questions: const [_question])),
        userRepositoryProvider.overrideWithValue(FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'))),
        navigationServiceProvider.overrideWithValue(nav),
        notificationManagerProvider.overrideWithValue(_FakeNotificationManager(canRequest)),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(app(container, const _HostQuestions()));
      await tester.pump();
      return tester.state<_HostState>(find.byType(_HostQuestions));
    }

    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('2. soru kaydedilince: kutlama → izin açıklaması (soru metniyle) → Keşfet', (tester) async {
      final nav = _OrderedNav();
      final state = await pumpHost(tester, nav);

      state.checkCelebration(const [_question]);
      await tester.pump();
      state.checkCelebration(const [_question, _question]);
      await tester.pumpAndSettle();

      expect(nav.log, ['dialog:question_celebration', 'sheet:push_permission_prompt', 'go:${RouteNames.discover}'],
          reason: 'açıklama soru ekranında açılır, Keşfet\'e geçiş sonra');
    });

    testWidgets('açıklama daha önce gösterildiyse (ömür boyu bir kez) yalnız kutlama + Keşfet', (tester) async {
      SharedPreferences.setMockInitialValues({'qulo_push_preprompt_shown_count': 1});
      final nav = _OrderedNav();
      final state = await pumpHost(tester, nav);

      await state.showCelebrationDialog();

      expect(nav.log, ['dialog:question_celebration', 'go:${RouteNames.discover}']);
    });

    testWidgets('izin zaten varsa (sistem soramıyor) açıklama gösterilmez', (tester) async {
      final nav = _OrderedNav();
      final state = await pumpHost(tester, nav, canRequest: false);

      await state.showCelebrationDialog();

      expect(nav.log, ['dialog:question_celebration', 'go:${RouteNames.discover}']);
    });

    testWidgets('kutlama "Keşfet\'e git" olmadan kapatılırsa izin yine sorulur, Keşfet\'e gidilmez', (tester) async {
      final nav = _OrderedNav(confirmAnswer: false);
      final state = await pumpHost(tester, nav);

      await state.showCelebrationDialog();

      expect(nav.log, ['dialog:question_celebration', 'sheet:push_permission_prompt']);
    });
  });
}

/// Diyalog / sheet / yönlendirme sırası tek listede.
class _OrderedNav extends FakeNavigationService {
  _OrderedNav({super.confirmAnswer});

  final log = <String>[];

  @override
  Future<T?> showAppDialog<T>(AppDialog dialog) {
    log.add('dialog:${dialog.name}');
    return super.showAppDialog<T>(dialog);
  }

  @override
  Future<T?> showAppBottomSheet<T>(AppBottomSheet sheet) {
    log.add('sheet:${sheet.name}');
    return super.showAppBottomSheet<T>(sheet);
  }

  @override
  void go(String name, {Map<String, String>? params, Object? extra}) {
    log.add('go:$name');
    super.go(name, params: params, extra: extra);
  }
}

class _FakeNotificationManager implements NotificationManager {
  _FakeNotificationManager(this._canRequest);

  final bool _canRequest;

  @override
  Future<bool> canRequestPermission() async => _canRequest;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNotificationManager.${invocation.memberName}');
}
