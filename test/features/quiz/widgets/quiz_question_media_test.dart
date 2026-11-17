import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/quiz_audio_player.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_question_content.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_question_media.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Sesli/görselli soru (2.0.19): çözen sesi duyar / görseli görür; sayaç medya hazır olana
/// (ses bitti / görsel yüklendi — hata da "hazır") ya da `mediaHoldSeconds` dolana dek
/// taban sürede bekler. Ses bir kez kendiliğinden çalar, "Tekrar dinle" ile yeniden çalar.
/// Oynatıcı soru başına ayrı örnek: kart kapanınca durur ve bırakılır (video-player-guard).
final _en = AppLocalizations(const Locale('en'));
const _voiceUrl = 'https://media.test/v.m4a';
const _imageUrl = 'https://media.test/i.jpg';

class _FakeQuizAudioPlayer implements QuizAudioPlayer {
  final _completed = StreamController<void>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final played = <String>[];
  bool failLoad = false;
  int stopCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  bool emitPlaying = true;
  bool disposed = false;
  final _position = StreamController<Duration>.broadcast();

  void tick(Duration position) => _position.add(position);

  void finish() {
    _playing.add(false);
    _completed.add(null);
  }

  @override
  Stream<void> get completedStream => _completed.stream;

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Future<void> pause() async {
    pauseCalls++;
    _playing.add(false);
  }

  @override
  Future<void> resume() async {
    resumeCalls++;
    _playing.add(true);
  }

  /// Her çalmanın kullanıcı isteği olup olmadığı (`played` ile aynı sırada).
  final userInitiated = <bool>[];

  @override
  Future<void> playFromStart(String url, {bool userInitiated = false}) async {
    played.add(url);
    this.userInitiated.add(userInitiated);
    if (failLoad) throw Exception('load failed');
    if (emitPlaying) _playing.add(true);
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _completed.close();
    await _playing.close();
    await _position.close();
  }
}

/// Testin yükleme sonucunu elle verdiği görsel (ağ yok).
class _ControlledImage extends ImageProvider<_ControlledImage> {
  final completer = Completer<ImageInfo>();

  @override
  Future<_ControlledImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_ControlledImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(completer.future);
}

class _Harness {
  _Harness(this.tester);

  final WidgetTester tester;
  final players = <_FakeQuizAudioPlayer>[];
  final image = _ControlledImage();
  var readyCalls = 0;
  bool failNextLoad = false;
  bool emitPlaying = true;

  _FakeQuizAudioPlayer get player => players.last;

  List<Override> get overrides => [
        quizAudioPlayerFactoryProvider.overrideWithValue(() {
          final p = _FakeQuizAudioPlayer()
            ..failLoad = failNextLoad
            ..emitPlaying = emitPlaying;
          players.add(p);
          return p;
        }),
        quizMediaImageProviderFactoryProvider.overrideWithValue((_) => image),
      ];

  Widget app(Widget child) => ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Scaffold(body: child),
        ),
      );

  Future<void> show({String? voiceUrl, String? imageUrl}) async {
    await tester.pumpWidget(app(
      QuizQuestionMedia(
        voiceUrl: voiceUrl,
        voiceDurationMs: voiceUrl == null ? null : 4000,
        imageUrl: imageUrl,
        onReady: () => readyCalls++,
      ),
    ));
    // Çeviriler + oynatıcı akışları bir mikro görev sonra.
    await tester.pump();
  }

  Future<void> loadImage() async {
    final img = await tester.runAsync(() => createTestImage(width: 2, height: 2));
    image.completer.complete(ImageInfo(image: img!));
    await tester.pump();
  }

  Future<void> failImage() async {
    image.completer.completeError(Exception('404'));
    await tester.pump();
  }
}

QuizQuestionModel _question({String? voiceUrl, String? imageUrl}) => QuizQuestionModel(
      sessionId: 's1',
      questionNumber: 1,
      totalQuestions: 1,
      questionId: 'q1',
      questionText: 'Q1?',
      answers: const [
        QuizAnswerOption(index: 0, text: 'A'),
        QuizAnswerOption(index: 1, text: 'B'),
      ],
      timeLimitSeconds: 10,
      remainingSeconds: 15,
      voiceUrl: voiceUrl,
      voiceDurationMs: voiceUrl == null ? null : 4000,
      imageUrl: imageUrl,
      mediaExtraSeconds: 5,
    );

void main() {
  final replay = _en.get('quiz_voice_replay');
  final play = _en.get('quiz_voice_play');
  final pause = _en.get('quiz_voice_pause');

  group('QuizQuestionMedia — ses', () {
    testWidgets('bir kez kendiliğinden çalar; bitince onReady bir kez', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl);

      expect(h.player.played, [_voiceUrl]);
      expect(h.readyCalls, 0, reason: 'ses bitmeden sayaç bekler');

      h.player.finish();
      await tester.pump();
      expect(h.readyCalls, 1);
    });

    testWidgets('"Tekrar dinle" baştan çalar; ikinci bitiş onReady\'yi yinelemez', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl);
      h.player.finish();
      await tester.pump();

      await tester.tap(find.byTooltip(replay));
      await tester.pump();
      expect(h.player.played, [_voiceUrl, _voiceUrl]);
      // Kendiliğinden çalma sessiz moda uyar; dokunuş kullanıcı isteğidir (iOS playback).
      expect(h.player.userInitiated, [false, true]);

      h.player.finish();
      await tester.pump();
      expect(h.readyCalls, 1);
    });

    testWidgets('ses yüklenemezse "hazır" sayılır (sayaç tutulmaz)', (tester) async {
      final h = _Harness(tester)..failNextLoad = true;
      await h.show(voiceUrl: _voiceUrl);
      await tester.pump();

      expect(h.readyCalls, 1);
    });

    // Durdurma sırası + oturum geri yüklemesi `QuizAudioPlayer.dispose`'ta (quiz_audio_player_test).
    testWidgets('kart kapanınca oynatıcı bırakılır', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl);

      await tester.pumpWidget(h.app(const SizedBox()));

      expect(h.player.disposed, isTrue);
    });
  });

  group('QuizQuestionMedia — oynatıcı satırı', () {
    testWidgets('çalarken duraklat ikonu; dokunuş duraklatır, tekrar dokunuş sürdürür', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl);
      await tester.pump();

      await tester.tap(find.byTooltip(pause));
      await tester.pump();
      expect(h.player.pauseCalls, 1);
      expect(find.byTooltip(play), findsOneWidget);

      await tester.tap(find.byTooltip(play));
      await tester.pump();
      expect(h.player.resumeCalls, 1);
      expect(h.player.played, [_voiceUrl], reason: 'sürdürme baştan çalmaz');
      expect(find.byTooltip(pause), findsOneWidget);
    });

    testWidgets('duraklatmak onReady tetiklemez', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl);
      await tester.pump();

      await tester.tap(find.byTooltip(pause));
      await tester.pump();

      expect(h.readyCalls, 0);
    });

    testWidgets('bitince tekrar ikonu; dokunuş kullanıcı isteğiyle baştan çalar', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl);
      h.player.finish();
      await tester.pump();

      expect(find.byTooltip(replay), findsOneWidget);
      await tester.tap(find.byTooltip(replay));
      await tester.pump();

      expect(h.player.played, [_voiceUrl, _voiceUrl]);
      expect(h.player.userInitiated.last, isTrue);
      expect(find.byTooltip(pause), findsOneWidget);
    });

    testWidgets('yüklenirken düğmede küçük yükleme göstergesi, dokunuş etkisiz', (tester) async {
      // playingStream hiç true yollamaz: ses hâlâ yükleniyor.
      final hh = _Harness(tester)..emitPlaying = false;
      await hh.show(voiceUrl: _voiceUrl);

      expect(find.byType(AppLoadingWidget), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(hh.player.pauseCalls, 0);
      expect(hh.player.resumeCalls, 0);
    });

    testWidgets('yükleme hatasında satır gizlenir', (tester) async {
      final h = _Harness(tester)..failNextLoad = true;
      await h.show(voiceUrl: _voiceUrl);
      await tester.pump();

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('konum ilerledikçe kalan süre ve ilerleme güncellenir', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl);
      expect(find.text('0:04'), findsOneWidget);

      h.player.tick(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('0:03'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.25);
    });
  });

  group('QuizQuestionMedia — görsel', () {
    testWidgets('yüklenirken yer tutucu; yüklenince görsel + onReady', (tester) async {
      final h = _Harness(tester);
      await h.show(imageUrl: _imageUrl);

      expect(find.byType(AppLoadingWidget), findsOneWidget);
      expect(h.readyCalls, 0);

      await h.loadImage();

      expect(find.byType(AppLoadingWidget), findsNothing);
      expect(find.bySemanticsLabel(_en.get('quiz_question_image')), findsOneWidget);
      expect(h.readyCalls, 1);
      expect(h.players, isEmpty, reason: 'sessiz soruda oynatıcı kurulmaz');
    });

    testWidgets('görsel kırpılmaz (contain) ve ekran yüksekliğinin %40\'ını aşmaz', (tester) async {
      final h = _Harness(tester);
      await h.show(imageUrl: _imageUrl);
      await h.loadImage();

      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
      final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final box = tester.getSize(find.byType(AspectRatio));
      expect(box.height, lessThanOrEqualTo(screenHeight * 0.4 + 0.01));
      expect(box.width / box.height, closeTo(3 / 4, 0.01));
    });

    testWidgets('yüklenemezse hiçbir şey göstermez ve "hazır" sayılır', (tester) async {
      final h = _Harness(tester);
      await h.show(imageUrl: _imageUrl);

      await h.failImage();

      expect(find.byType(AppLoadingWidget), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(h.readyCalls, 1);
    });

    testWidgets('ses + görsel: onReady ikisi de hazır olunca', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl, imageUrl: _imageUrl);

      await h.loadImage();
      expect(h.readyCalls, 0, reason: 'ses hâlâ çalıyor');

      h.player.finish();
      await tester.pump();
      expect(h.readyCalls, 1);
    });
  });

  group('analitik', () {
    final events = <({String name, Map<String, Object>? params})>[];
    setUp(() {
      events.clear();
      AnalyticsManager.debugEventSink = (name, params) => events.add((name: name, params: params));
    });
    tearDown(() => AnalyticsManager.debugEventSink = null);

    List<Map<String, Object>?> paramsOf(String name) =>
        events.where((e) => e.name == name).map((e) => e.params).toList();

    testWidgets('quiz_voice_played kart kapanırken TEK kez, son değerlerle (completed + replays)', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl);
      h.player.finish();
      await tester.pump();
      await tester.tap(find.byTooltip(replay));
      await tester.pump();
      h.player.finish();
      await tester.pump();
      await tester.tap(find.byTooltip(replay));
      await tester.pump();
      expect(paramsOf(AnalyticsEvents.quizVoicePlayed), isEmpty, reason: 'kart açıkken yollanmaz');

      await tester.pumpWidget(h.app(const SizedBox()));

      expect(paramsOf(AnalyticsEvents.quizVoicePlayed), [
        {AnalyticsEvents.paramCompleted: true, AnalyticsEvents.paramReplays: 2},
      ]);
    });

    testWidgets('ses bitmeden kapanırsa completed=false, replays=0', (tester) async {
      final h = _Harness(tester);
      await h.show(voiceUrl: _voiceUrl);

      await tester.pumpWidget(h.app(const SizedBox()));

      expect(paramsOf(AnalyticsEvents.quizVoicePlayed), [
        {AnalyticsEvents.paramCompleted: false, AnalyticsEvents.paramReplays: 0},
      ]);
    });

    testWidgets('sessiz soruda quiz_voice_played yok', (tester) async {
      final h = _Harness(tester);
      await h.show(imageUrl: _imageUrl);
      await h.loadImage();

      await tester.pumpWidget(h.app(const SizedBox()));

      expect(paramsOf(AnalyticsEvents.quizVoicePlayed), isEmpty);
    });

    testWidgets('ses yüklenemezse quiz_media_load_failed(type=voice); played yollanmaz', (tester) async {
      final h = _Harness(tester)..failNextLoad = true;
      await h.show(voiceUrl: _voiceUrl);
      await tester.pump();

      await tester.pumpWidget(h.app(const SizedBox()));

      expect(paramsOf(AnalyticsEvents.quizMediaLoadFailed), [
        {AnalyticsEvents.paramType: AnalyticsEvents.mediaTypeVoice},
      ]);
      expect(paramsOf(AnalyticsEvents.quizVoicePlayed), isEmpty);
    });

    testWidgets('görsel yüklenemezse quiz_media_load_failed(type=image)', (tester) async {
      final h = _Harness(tester);
      await h.show(imageUrl: _imageUrl);

      await h.failImage();

      expect(paramsOf(AnalyticsEvents.quizMediaLoadFailed), [
        {AnalyticsEvents.paramType: AnalyticsEvents.mediaTypeImage},
      ]);
    });
  });

  group('quiz kartında medya + sayaç', () {
    Future<GlobalKey<QuizTimerState>> showContent(
      _Harness h,
      QuizQuestionModel q,
      List<int> selected,
    ) async {
      final timerKey = GlobalKey<QuizTimerState>();
      await h.tester.pumpWidget(h.app(
        QuizQuestionContent(
          question: q,
          timerKey: timerKey,
          sessionId: 's1',
          selectedAnswerIndex: null,
          oracleSuggestedIndex: null,
          removedIndices: const [],
          hintText: null,
          isSubmitting: false,
          timeExtendEffectToken: 0,
          skipEffectToken: 0,
          onTimeout: () {},
          onSelectAnswer: selected.add,
          onSubmitAnswer: () async {},
          onPowerUsed: (_) async {},
        ),
      ));
      await h.tester.pump();
      return timerKey;
    }

    testWidgets('ses biterse sayaç tutması biter (release), taban süreden sayar', (tester) async {
      final h = _Harness(tester);
      final timerKey = await showContent(h, _question(voiceUrl: _voiceUrl), []);

      await tester.pump(const Duration(seconds: 2));
      expect(timerKey.currentState!.remainingSeconds, 10, reason: 'ses çalarken tutulur');

      h.player.finish();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(timerKey.currentState!.remainingSeconds, 9);
    });

    testWidgets('şıklar ses çalarken tıklanabilir', (tester) async {
      final h = _Harness(tester);
      final selected = <int>[];
      await showContent(h, _question(voiceUrl: _voiceUrl), selected);

      await tester.tap(find.widgetWithText(AnswerButton, 'B'));
      await tester.pump();

      expect(selected, [1]);
    });

    testWidgets('görsel yüklenemezse kart metinle çözülür, sayaç hemen sayar', (tester) async {
      final h = _Harness(tester);
      final selected = <int>[];
      final timerKey = await showContent(h, _question(imageUrl: _imageUrl), selected);

      await h.failImage();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Q1?'), findsOneWidget);
      expect(timerKey.currentState!.remainingSeconds, 9);
      await tester.tap(find.widgetWithText(AnswerButton, 'A'));
      expect(selected, [0]);
    });

    testWidgets('görsel hiç yüklenmezse sayaç mediaHoldSeconds dolunca kendisi başlar', (tester) async {
      final h = _Harness(tester);
      final timerKey = await showContent(h, _question(imageUrl: _imageUrl), []);

      await tester.pump(const Duration(seconds: 5));
      expect(timerKey.currentState!.remainingSeconds, 10);
      await tester.pump(const Duration(seconds: 1));
      expect(timerKey.currentState!.remainingSeconds, 9);
    });

    testWidgets('medyasız soru: medya alanı yok, sayaç hemen sayar (eski davranış)', (tester) async {
      final h = _Harness(tester);
      final timerKey = await showContent(
        h,
        const QuizQuestionModel(
          sessionId: 's1',
          questionNumber: 1,
          totalQuestions: 1,
          questionId: 'q1',
          questionText: 'Q1?',
          answers: [QuizAnswerOption(index: 0, text: 'A')],
          timeLimitSeconds: 10,
        ),
        [],
      );

      expect(find.byType(QuizQuestionMedia), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(timerKey.currentState!.remainingSeconds, 9);
      expect(h.players, isEmpty);
    });
  });
}
