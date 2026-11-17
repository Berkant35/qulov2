import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/questions/mixins/question_create_screen_mixin.dart';
import 'package:qulo_v2/features/questions/mixins/question_media_mixin.dart';
import 'package:qulo_v2/features/questions/screens/question_create_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Sesli/görselli soru taslağı: metin önce kaydedilir, medya ardından sırayla
/// yüklenir. Medya hatası metin sorusunu ASLA silmez; bayrak kapandıysa bölüm
/// gizlenir ve tek mesaj gösterilir.
class _Host extends QuestionCreateScreen {
  const _Host({super.editQuestion});

  @override
  ConsumerState<QuestionCreateScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<QuestionCreateScreen>
    with QuestionMediaMixin, QuestionCreateScreenMixin {
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

  // Scaffold: snackbar'lar gorunsun diye (gercek ekranda AppScaffold).
  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox());
}

class _FakePicker implements ImagePickerManager {
  _FakePicker(this.result);

  final PickedImage? result;
  final sources = <ImageSource>[];

  @override
  Future<PickedImage?> pickAndCrop(
    BuildContext context,
    ImageSource source, {
    double maxWidth = 1080,
    int imageQuality = 85,
  }) async {
    sources.add(source);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakePicker.${invocation.memberName}');
}

final _en = AppLocalizations(const Locale('en'));

QuestionModel _existing({
  String? voiceUrl,
  int? voiceDurationMs,
  String? imageUrl,
  QuestionImageStatus? imageStatus,
}) =>
    QuestionModel(
      id: 'q_existing',
      userId: 'u1',
      orderNum: 2,
      questionText: 'En sevdiğim şehir hangisi?',
      correctAnswer: 1,
      answer1: 'İzmir',
      answer2: 'Roma',
      answer3: 'Lima',
      answer4: 'Oslo',
      voiceUrl: voiceUrl,
      voiceDurationMs: voiceDurationMs,
      imageUrl: imageUrl,
      imageStatus: imageStatus,
    );

void main() {
  final events = <({String name, Map<String, Object>? params})>[];
  setUp(() {
    events.clear();
    AnalyticsManager.debugEventSink = (name, params) => events.add((name: name, params: params));
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  Future<({_HostState state, FakeQuestionRepository repo, FakeNavigationService nav})> pump(
    WidgetTester tester, {
    FakeQuestionRepository? repo,
    QuestionModel? edit,
    _FakePicker? picker,
  }) async {
    final questions = repo ?? FakeQuestionRepository();
    final nav = FakeNavigationService();
    final container = ProviderContainer(overrides: [
      questionRepositoryProvider.overrideWithValue(questions),
      userRepositoryProvider.overrideWithValue(
        FakeUserRepository(UserModel(id: 'u1', email: 'u1@qulo.test')),
      ),
      navigationServiceProvider.overrideWithValue(nav),
      if (picker != null) imagePickerManagerProvider.overrideWithValue(picker),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: _Host(editQuestion: edit),
      ),
    ));
    await tester.pump();
    final state = tester.state<_HostState>(find.byType(_Host));
    if (edit == null) {
      state
        ..questionTextController.text = 'En sevdiğim şehir hangisi?'
        ..answer1Controller.text = 'İzmir'
        ..answer2Controller.text = 'Roma'
        ..answer3Controller.text = 'Lima'
        ..answer4Controller.text = 'Oslo';
    }
    return (state: state, repo: questions, nav: nav);
  }

  Future<void> saveAndSettle(WidgetTester tester, _HostState state) async {
    await state.save();
    await tester.pump();
  }

  group('kaydetme sonrası medya yükleme', () {
    testWidgets('ses: metin kaydından SONRA uploadVoice doğru durationMs ile çağrılır', (tester) async {
      final h = await pump(tester);
      h.state.onVoiceRecorded('/tmp/q_voice.m4a', 7);

      await saveAndSettle(tester, h.state);

      expect(h.repo.createdBodies, hasLength(1));
      expect(h.repo.voiceUploads, hasLength(1));
      expect(h.repo.voiceUploads.single.orderNum, h.repo.createdBodies.single['order_num']);
      expect(h.repo.voiceUploads.single.path, '/tmp/q_voice.m4a');
      expect(h.repo.voiceUploads.single.durationMs, 7000);
      expect(h.nav.pops, 1);
    });

    testWidgets('ses süresi sunucu aralığında: 0 sn → 1000 ms, 15 sn → 15000 ms', (tester) async {
      final h = await pump(tester);

      h.state.onVoiceRecorded('/tmp/a.m4a', 0);
      expect(h.state.mediaDraft.voiceDurationMs, 1000);
      h.state.onVoiceRecorded('/tmp/b.m4a', 15);
      expect(h.state.mediaDraft.voiceDurationMs, 15000);
      h.state.onVoiceRecorded('/tmp/c.m4a', 99);
      expect(h.state.mediaDraft.voiceDurationMs, 15000);
    });

    testWidgets('ses yükleme hatası: soru silinmez, metin kaydı kalır, tek hata mesajı', (tester) async {
      final repo = FakeQuestionRepository()..voiceFailures.add(const NetworkFailure());
      final h = await pump(tester, repo: repo);
      h.state.onVoiceRecorded('/tmp/q_voice.m4a', 5);

      await saveAndSettle(tester, h.state);

      expect(repo.createdBodies, hasLength(1), reason: 'metin sorusu kaydedildi');
      expect(repo.deletedOrderNums, isEmpty, reason: 'medya hatası soruyu silmemeli');
      expect(find.text(_en.get('question_media_upload_failed')), findsOneWidget);
      expect(h.nav.pops, 1, reason: 'kayıtlı soru tekrar oluşturulmasın diye ekran kapanır');
    });

    testWidgets('409 çakışma: liste bir kez yenilenir, yükleme yeni sıra numarasıyla bir kez tekrarlanır', (tester) async {
      // Kayıt sırasında soru başka sıraya kaydı (ör. başka cihazdan silme).
      final repo = FakeQuestionRepository(questions: [
        _existing().copyWithOrder(id: 'created_0', orderNum: 3),
      ])
        ..voiceFailures.add(const ServerFailure(code: 'QUESTION_MEDIA_CONFLICT', statusCode: 409));
      final h = await pump(tester, repo: repo);
      h.state.onVoiceRecorded('/tmp/q_voice.m4a', 5);

      await saveAndSettle(tester, h.state);

      final createdOrder = repo.createdBodies.single['order_num'] as int;
      expect(createdOrder, isNot(3));
      expect(repo.voiceUploads.map((u) => u.orderNum), [createdOrder, 3]);
      expect(find.text(_en.get('question_media_upload_failed')), findsNothing);
    });

    testWidgets('409 iki kez: yalnız bir tekrar, sonra yükleme hatası mesajı', (tester) async {
      const conflict = ServerFailure(code: 'QUESTION_MEDIA_CONFLICT', statusCode: 409);
      final repo = FakeQuestionRepository()..voiceFailures.addAll([conflict, conflict, conflict]);
      final h = await pump(tester, repo: repo);
      h.state.onVoiceRecorded('/tmp/q_voice.m4a', 5);

      await saveAndSettle(tester, h.state);

      expect(repo.voiceUploads, hasLength(2));
      expect(find.text(_en.get('question_media_upload_failed')), findsOneWidget);
    });

    testWidgets('FEATURE_DISABLED: kalan yükleme denenmez, bölüm gizlenir, tek "kullanılamıyor" mesajı', (tester) async {
      final repo = FakeQuestionRepository()
        ..voiceFailures.add(const ServerFailure(code: 'FEATURE_DISABLED', statusCode: 403));
      final h = await pump(tester, repo: repo);
      h.state
        ..onVoiceRecorded('/tmp/q_voice.m4a', 5)
        ..setImageDraft(Uint8List.fromList([1, 2, 3]), 'image/jpeg');

      await saveAndSettle(tester, h.state);

      expect(repo.imageUploads, isEmpty);
      expect(repo.createdBodies, hasLength(1));
      expect(h.state.mediaFeatureDisabled, isTrue);
      expect(h.state.showMediaSection(true), isFalse);
      expect(find.text(_en.get('question_media_unavailable')), findsOneWidget);
      expect(find.text(_en.get('question_media_upload_failed')), findsNothing);
    });

    testWidgets('görsel reddedildi (image_url null): question_image_rejected mesajı', (tester) async {
      final repo = FakeQuestionRepository()..imageUploadStatus = QuestionImageStatus.rejected;
      final h = await pump(tester, repo: repo);
      h.state.setImageDraft(Uint8List.fromList([1, 2, 3]), 'image/png');

      await saveAndSettle(tester, h.state);

      expect(repo.imageUploads.single.mimeType, 'image/png');
      expect(find.text(_en.get('question_image_rejected')), findsOneWidget);
    });

    testWidgets('görsel inceleniyor (pending): inceleme bildirimi', (tester) async {
      final repo = FakeQuestionRepository()..imageUploadStatus = QuestionImageStatus.pending;
      final h = await pump(tester, repo: repo);
      h.state.setImageDraft(Uint8List.fromList([1, 2, 3]), 'image/jpeg');

      await saveAndSettle(tester, h.state);

      expect(find.text(_en.get('question_image_in_review_notice')), findsOneWidget);
    });

    testWidgets('taslak boşsa medya uç noktası hiç çağrılmaz', (tester) async {
      final h = await pump(tester);

      await saveAndSettle(tester, h.state);

      expect(h.repo.voiceUploads, isEmpty);
      expect(h.repo.imageUploads, isEmpty);
      expect(h.repo.removedMedia, isEmpty);
      expect(h.nav.pops, 1);
    });

    testWidgets('metin kaydı başarısızsa medya yüklenmez', (tester) async {
      final repo = FakeQuestionRepository(createFailures: {0: const NetworkFailure()});
      final h = await pump(tester, repo: repo);
      h.state.onVoiceRecorded('/tmp/q_voice.m4a', 5);

      await saveAndSettle(tester, h.state);

      expect(repo.voiceUploads, isEmpty);
      expect(h.nav.pops, 0);
    });
  });

  group('analitik', () {
    List<String> names() => events.map((e) => e.name).toList();

    testWidgets('ses yüklenince question_voice_added (duration_ms)', (tester) async {
      final h = await pump(tester);
      h.state.onVoiceRecorded('/tmp/q_voice.m4a', 7);

      await saveAndSettle(tester, h.state);

      final e = events.singleWhere((e) => e.name == AnalyticsEvents.questionVoiceAdded);
      expect(e.params, {AnalyticsEvents.paramDurationMs: 7000});
    });

    testWidgets('görsel yüklenince question_image_added', (tester) async {
      final h = await pump(tester);
      h.state.setImageDraft(Uint8List.fromList([1, 2, 3]), 'image/jpeg');

      await saveAndSettle(tester, h.state);

      expect(names(), contains(AnalyticsEvents.questionImageAdded));
    });

    testWidgets('ses yükleme BAŞARISIZSA question_voice_added yollanmaz', (tester) async {
      final repo = FakeQuestionRepository()..voiceFailures.add(const NetworkFailure());
      final h = await pump(tester, repo: repo);
      h.state.onVoiceRecorded('/tmp/q_voice.m4a', 5);

      await saveAndSettle(tester, h.state);

      expect(names(), isNot(contains(AnalyticsEvents.questionVoiceAdded)));
    });

    testWidgets('kaldırma başarılıysa question_media_removed (type)', (tester) async {
      final edit = _existing(voiceUrl: 'https://signed.test/old', voiceDurationMs: 4000);
      final h = await pump(tester, repo: FakeQuestionRepository(questions: [edit]), edit: edit);
      h.state.removeVoice();

      await saveAndSettle(tester, h.state);

      final e = events.singleWhere((e) => e.name == AnalyticsEvents.questionMediaRemoved);
      expect(e.params, {AnalyticsEvents.paramType: AnalyticsEvents.mediaTypeVoice});
    });
  });

  group('düzenleme modu', () {
    testWidgets('mevcut ses kaldırılırsa removeMedia(voice) çağrılır, yükleme yok', (tester) async {
      final edit = _existing(voiceUrl: 'https://signed.test/old', voiceDurationMs: 4000);
      final repo = FakeQuestionRepository(questions: [edit]);
      final h = await pump(tester, repo: repo, edit: edit);
      expect(h.state.voicePreviewSource, 'https://signed.test/old');

      h.state.removeVoice();
      expect(h.state.voicePreviewSource, isNull);
      await saveAndSettle(tester, h.state);

      expect(repo.removedMedia, [(orderNum: 2, kind: QuestionMediaKind.voice)]);
      expect(repo.voiceUploads, isEmpty);
    });

    testWidgets('sunucudaki görsel durumu: pending → İnceleniyor, rejected → ret metni', (tester) async {
      final pending = await pump(
        tester,
        edit: _existing(imageUrl: 'https://signed.test/img', imageStatus: QuestionImageStatus.pending),
      );
      expect(pending.state.imageInReview, isTrue);
      expect(pending.state.imagePreviewUrl, 'https://signed.test/img');

      final rejected = await pump(
        tester,
        edit: _existing(imageStatus: QuestionImageStatus.rejected),
      );
      expect(rejected.state.imageRejected, isTrue);
      expect(rejected.state.imagePreviewUrl, isNull);
    });

    testWidgets('reddedilen görsel kaldırılınca removeMedia(image) çağrılır, ret notu kalkar', (tester) async {
      // Sunucu reddedince yol boş, durum 'rejected' kalır; kaldırma çağrılmazsa
      // not her açılışta yeniden görünürdü (final review M1).
      final edit = _existing(imageStatus: QuestionImageStatus.rejected);
      final repo = FakeQuestionRepository(questions: [edit]);
      final h = await pump(tester, repo: repo, edit: edit);
      expect(h.state.imageRejected, isTrue);

      h.state.removeImage();
      expect(h.state.imageRejected, isFalse);
      await saveAndSettle(tester, h.state);

      expect(repo.removedMedia, [(orderNum: 2, kind: QuestionMediaKind.image)]);
      expect(repo.imageUploads, isEmpty);
    });
  });

  group('taslak toplama', () {
    testWidgets('fotoğraf: kaynak sheet\'i → pickAndCrop → taslakta bayt + mime', (tester) async {
      final picker = _FakePicker(PickedImage(
        bytes: Uint8List.fromList([9, 9]),
        mimeType: 'image/jpeg',
        fileName: 'x.jpg',
      ));
      final h = await pump(tester, picker: picker);
      h.nav.sheetAnswer = ImageSource.gallery;

      await h.state.pickQuestionImage();

      expect(h.nav.sheets, ['question_image_source']);
      expect(picker.sources, [ImageSource.gallery]);
      expect(h.state.mediaDraft.imageBytes, [9, 9]);
      expect(h.state.mediaDraft.imageMime, 'image/jpeg');
      expect(h.state.imagePreviewBytes, isNotNull);
    });

    testWidgets('kayıt başlat/tamamla: overlay bayrağı kapanır, yeni ses eskisinin kaldırma bayrağını siler', (tester) async {
      final edit = _existing(voiceUrl: 'https://signed.test/old', voiceDurationMs: 4000);
      final h = await pump(tester, edit: edit);

      h.state.removeVoice();
      expect(h.state.mediaDraft.removeVoice, isTrue);
      h.state.startVoiceRecording();
      expect(h.state.isRecordingVoice, isTrue);
      h.state.onVoiceRecorded('/tmp/new.m4a', 3);

      expect(h.state.isRecordingVoice, isFalse);
      expect(h.state.mediaDraft.removeVoice, isFalse);
      expect(h.state.voicePreviewSource, Uri.file('/tmp/new.m4a').toString());
      expect(h.state.voicePreviewSeconds, 3);
    });
  });
}

extension on QuestionModel {
  QuestionModel copyWithOrder({required String id, required int orderNum}) => QuestionModel(
        id: id,
        userId: userId,
        orderNum: orderNum,
        questionText: questionText,
        correctAnswer: correctAnswer,
        answer1: answer1,
        answer2: answer2,
        answer3: answer3,
        answer4: answer4,
      );
}
