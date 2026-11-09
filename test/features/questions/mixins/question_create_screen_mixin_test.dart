import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/questions/mixins/question_create_screen_mixin.dart';
import 'package:qulo_v2/features/questions/screens/question_create_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Soru kaydı sürerken kullanıcı geri dönerse ekran kapanır. Başarıda eskiden
/// `ref.read(...).pop()` StateError atıyordu; servisi önceden yakalamak da
/// yanlış olurdu — kapalı ekranın yerine ALTINDAKİ ekranı kapatırdı.
class _HostCreate extends QuestionCreateScreen {
  const _HostCreate();

  @override
  ConsumerState<QuestionCreateScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<QuestionCreateScreen> with QuestionCreateScreenMixin {
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

void main() {
  final events = <String>[];

  setUp(() {
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

  Future<(_HostState, ProviderContainer, FakeQuestionRepository, FakeNavigationService)> pump(
    WidgetTester tester,
  ) async {
    final questions = FakeQuestionRepository();
    final nav = FakeNavigationService();
    final container = ProviderContainer(overrides: [
      questionRepositoryProvider.overrideWithValue(questions),
      userRepositoryProvider.overrideWithValue(FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test'))),
      navigationServiceProvider.overrideWithValue(nav),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(app(container, const _HostCreate()));
    await tester.pump();
    final state = tester.state<_HostState>(find.byType(_HostCreate))
      ..questionTextController.text = 'En sevdiğim şehir hangisi?'
      ..answer1Controller.text = 'İzmir'
      ..answer2Controller.text = 'Roma'
      ..answer3Controller.text = 'Lima'
      ..answer4Controller.text = 'Oslo';
    return (state, container, questions, nav);
  }

  testWidgets('kayıt sürerken ekran kapanırsa: soru kaydedilir, alttaki ekran kapatılmaz', (tester) async {
    final (state, container, questions, nav) = await pump(tester);
    questions.createGate = Completer<void>();

    final saving = state.save();
    await tester.pump();
    expect(questions.createCallCount, 1);
    await tester.pumpWidget(app(container, const SizedBox()));
    questions.createGate!.complete();
    await saving;

    expect(tester.takeException(), isNull);
    expect(questions.createdBodies, hasLength(1));
    expect(nav.pops, 0);
    expect(events, contains(AnalyticsEvents.questionCreateComplete));
  });

  testWidgets('açık ekranda başarılı kayıt ekranı kapatır', (tester) async {
    final (state, _, questions, nav) = await pump(tester);

    await state.save();

    expect(questions.createdBodies, hasLength(1));
    expect(nav.pops, 1);
  });
}
