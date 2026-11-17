import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/questions/mixins/question_create_screen_mixin.dart';
import 'package:qulo_v2/features/questions/screens/question_create_screen.dart';
import 'package:qulo_v2/features/questions/widgets/question_create_bottom_bar.dart';
import 'package:qulo_v2/features/questions/widgets/question_image_rejected_note.dart';
import 'package:qulo_v2/features/questions/widgets/question_media_section.dart';
import 'package:qulo_v2/features/questions/widgets/question_step_question.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Ses/fotoğraf bölümü yalnız sunucu `mediaQuestionsEnabled: true` derse
/// görünür (fail-closed). Kapalıyken soru oluşturma ekranı eskisi gibi kalır.
void main() {
  setUp(() => AnalyticsManager.debugEventSink = (_, _) {});
  tearDown(() => AnalyticsManager.debugEventSink = null);

  Future<void> pumpScreen(
    WidgetTester tester, {
    required bool mediaEnabled,
    FakeQuestionRepository? repo,
    QuestionModel? edit,
  }) async {
    final container = ProviderContainer(overrides: [
      mediaQuestionsEnabledProvider.overrideWithValue(mediaEnabled),
      questionRepositoryProvider.overrideWithValue(repo ?? FakeQuestionRepository()),
      userRepositoryProvider.overrideWithValue(
        FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test')),
      ),
      navigationServiceProvider.overrideWithValue(FakeNavigationService()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: QuestionCreateScreen(editQuestion: edit),
      ),
    ));
    await tester.pump();
  }

  testWidgets('mediaQuestionsEnabled=false → ses/fotoğraf bölümü yok', (tester) async {
    await pumpScreen(tester, mediaEnabled: false);

    expect(find.byType(QuestionStepQuestion), findsOneWidget, reason: 'ekran gerçekten çizildi');
    expect(find.byType(QuestionMediaSection), findsNothing);
  });

  testWidgets('mediaQuestionsEnabled=true → bölüm soru adımında görünür', (tester) async {
    await pumpScreen(tester, mediaEnabled: true);

    expect(find.byType(QuestionMediaSection), findsOneWidget);
  });

  testWidgets('reddedilen görsel notu kapatılabilir (kayıtta ret durumu temizlenir)', (tester) async {
    final en = AppLocalizations(const Locale('en'));
    const edit = QuestionModel(
      id: 'q1', userId: 'u1', orderNum: 1, questionText: 'Soru?', correctAnswer: 1,
      answer1: 'A', answer2: 'B', answer3: 'C', answer4: 'D',
      imageStatus: QuestionImageStatus.rejected,
    );
    await pumpScreen(tester, mediaEnabled: true, edit: edit);
    final note = find.text(en.get('question_image_rejected'));
    await tester.ensureVisible(note);
    expect(note, findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(QuestionImageRejectedNote),
      matching: find.byType(IconButton),
    ));
    await tester.pump();

    expect(note, findsNothing);
  });

  testWidgets('medya yüklenirken ilerleme metni Kaydet\'e basılan adımda (3. adım) görünür', (tester) async {
    final en = AppLocalizations(const Locale('en'));
    final repo = FakeQuestionRepository()..voiceUploadGate = Completer<void>();
    await pumpScreen(tester, mediaEnabled: true, repo: repo);
    final state = tester.state(find.byType(QuestionCreateScreen)) as QuestionCreateScreenMixin;
    state
      ..questionTextController.text = 'En sevdiğim şehir hangisi?'
      ..answer1Controller.text = 'İzmir'
      ..answer2Controller.text = 'Roma'
      ..answer3Controller.text = 'Lima'
      ..answer4Controller.text = 'Oslo'
      ..onVoiceRecorded('/tmp/q_voice.m4a', 5);
    state.goNext();
    await tester.pumpAndSettle();
    state.goNext();
    await tester.pumpAndSettle();
    expect(state.currentStep, 2);

    await tester.tap(find.text(en.get('question_create_save')));
    await tester.pump();
    await tester.pump();

    expect(repo.voiceUploads, hasLength(1), reason: 'metin kaydedildi, ses yükleniyor');
    final label = find.descendant(
      of: find.byType(QuestionCreateBottomBar),
      matching: find.text(en.get('question_media_uploading')),
    );
    expect(label.hitTestable(), findsOneWidget);

    repo.voiceUploadGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text(en.get('question_media_uploading')), findsNothing);
  });
}
