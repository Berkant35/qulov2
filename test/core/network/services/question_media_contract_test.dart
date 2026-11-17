import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/network/interceptors/request_timeout_interceptor.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/match_service.dart';
import 'package:qulo_v2/core/network/services/question_service.dart';
import 'package:qulo_v2/core/network/services/quiz_service.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/repositories/question_repository.dart';

import '../../../helpers/scripted_http_adapter.dart';

/// Sesli/gorselli soru (2.0.19) — sunucu JSON'u GERCEK Retrofit servisinden
/// (`_QuestionService`, `_QuizService`, `_MatchService`) gecer; yalniz "sunucu"
/// sahtedir (ScriptedHttpAdapter). Fake servis kullanan testler parser'i hic
/// calistirmadigi icin yukleme yanitinin sekil uyumsuzlugu (final review C1:
/// sunucu 4 medya alani donuyordu, `QuestionModel.fromJson` `id` isterken
/// patliyordu) gozden kacti. Fikstürler qulo-server'in gercek yanitlariyla
/// ayni sekildedir (`withOwnerMedia`, `quiz.service.getCurrentQuestion`,
/// `discover-question-info`).

const _voiceUrl =
    'https://x.supabase.co/storage/v1/object/sign/question-media/u1/q1/voice-1.m4a?token=t';
const _imageUrl =
    'https://x.supabase.co/storage/v1/object/sign/question-media/u1/q1/image-1.jpg?token=t';

/// GET /questions/me ogesi = yukleme yaniti (sunucu `withOwnerMedia([row])[0]`):
/// tum soru kolonlari, ham `voice_path`/`image_path` YOK.
Map<String, dynamic> _ownerQuestion({
  String? voiceUrl,
  int? voiceDurationMs,
  String? imageUrl,
  String? imageStatus,
}) =>
    {
      'id': 'q1',
      'user_id': 'u1',
      'order_num': 1,
      'question_text': 'En sevdigim sarki hangisi?',
      'correct_answer': 2,
      'answer_1': 'A',
      'answer_2': 'B',
      'answer_3': 'C',
      'answer_4': 'D',
      'hint_text': null,
      'category': 'music',
      'time_limit': 30,
      'locale': 'tr',
      'stats_correct': 0,
      'stats_wrong': 0,
      'stats_solve_count': 0,
      'created_at': '2026-11-09T10:00:00.000Z',
      'voice_url': voiceUrl,
      'voice_duration_ms': voiceDurationMs,
      'image_url': imageUrl,
      'image_status': imageStatus,
    };

/// Duzeltme oncesi sunucu yanit sekli (yalniz `ownerMedia`): RED kaniti icin.
const _legacyMediaOnly = {
  'voice_url': _voiceUrl,
  'voice_duration_ms': 4200,
  'image_url': null,
  'image_status': null,
};

class _Harness {
  _Harness(Object Function(RequestOptions o) body, {int status = 201})
      : adapter = ScriptedHttpAdapter(
          (o) async => jsonResponse(status, body(o)),
        ) {
    dio = scriptedDio(adapter)..interceptors.add(RequestTimeoutInterceptor());
  }

  final ScriptedHttpAdapter adapter;
  late final Dio dio;

  QuestionRepository get repo =>
      QuestionRepository(QuestionService(dio), NetworkManager.instance);
}

void main() {
  late Directory tmp;
  late File voiceFile;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('qmedia');
    voiceFile = File('${tmp.path}/voice.m4a')
      ..writeAsBytesSync(Uint8List.fromList([0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70]));
  });

  tearDown(() async => tmp.delete(recursive: true));

  group('POST /questions/me/:order/voice — gercek parser', () {
    test('sunucunun guncel soru yaniti QuestionModel olarak parse edilir', () async {
      final h = _Harness(
        (_) => _ownerQuestion(voiceUrl: _voiceUrl, voiceDurationMs: 4200),
      );

      final result = await h.repo.uploadVoice(1, voiceFile, 4200);

      expect(result, isA<Success<QuestionModel>>());
      final q = (result as Success<QuestionModel>).data;
      expect(q.id, 'q1');
      expect(q.orderNum, 1);
      expect(q.voiceUrl, _voiceUrl);
      expect(q.voiceDurationMs, 4200);
      expect(q.imageUrl, isNull);
      expect(q.imageStatus, isNull);
      expect(h.adapter.requests.single.path, '/questions/me/1/voice');
    });

    test('eski 4 alanli medya yaniti parse EDILEMEZ (C1 kok nedeni — sozlesme kilidi)',
        () async {
      final h = _Harness((_) => _legacyMediaOnly);

      final result = await h.repo.uploadVoice(1, voiceFile, 4200);

      expect(result, isA<Failure<QuestionModel>>());
    });

    test('uzun yanit siniri uygulanir (genel 15 sn degil)', () async {
      final h = _Harness(
        (_) => _ownerQuestion(voiceUrl: _voiceUrl, voiceDurationMs: 4200),
      );

      await h.repo.uploadVoice(1, voiceFile, 4200);

      expect(
        h.adapter.requests.single.receiveTimeout,
        AppDurations.mediaUploadReceiveTimeout,
      );
    });
  });

  group('POST /questions/me/:order/image — gercek parser', () {
    for (final (status, url, expected) in [
      ('approved', _imageUrl, QuestionImageStatus.approved),
      ('pending', _imageUrl, QuestionImageStatus.pending),
      ('rejected', null, QuestionImageStatus.rejected),
    ]) {
      test('image_status=$status parse edilir', () async {
        final h = _Harness(
          (_) => _ownerQuestion(imageUrl: url, imageStatus: status),
        );

        final result =
            await h.repo.uploadImage(1, Uint8List.fromList([1, 2, 3]), 'image/jpeg');

        expect(result, isA<Success<QuestionModel>>());
        final q = (result as Success<QuestionModel>).data;
        expect(q.id, 'q1');
        expect(q.imageUrl, url);
        expect(q.imageStatus, expected);
        expect(q.voiceUrl, isNull);
      });
    }

    test('uzun yanit siniri uygulanir (senkron moderasyon <= 8 sn)', () async {
      final h = _Harness(
        (_) => _ownerQuestion(imageUrl: _imageUrl, imageStatus: 'approved'),
      );

      await h.repo.uploadImage(1, Uint8List.fromList([1]), 'image/png');

      expect(
        h.adapter.requests.single.receiveTimeout,
        AppDurations.mediaUploadReceiveTimeout,
      );
    });
  });

  group('GET /questions/me — gercek parser', () {
    test('medyali ve medyasiz ogeler parse edilir; isaretsiz istekte uzun sinir yok',
        () async {
      final h = _Harness(
        (_) => [
          _ownerQuestion(voiceUrl: _voiceUrl, voiceDurationMs: 1000),
          {..._ownerQuestion(), 'id': 'q2', 'order_num': 2}
            ..removeWhere((k, _) => k.startsWith('voice_') || k.startsWith('image_')),
        ],
        status: 200,
      );

      final result = await h.repo.getMyQuestions();

      final list = (result as Success<List<QuestionModel>>).data;
      expect(list.map((q) => q.voiceUrl), [_voiceUrl, null]);
      expect(list.last.imageStatus, isNull);
      expect(h.adapter.requests.single.receiveTimeout, isNot(AppDurations.mediaUploadReceiveTimeout));
    });
  });

  group('GET /quiz/:sessionId — gercek parser', () {
    final legacy = <String, dynamic>{
      'session_id': 's1',
      'question_number': 1,
      'total_questions': 3,
      'question_id': 'q1',
      'question_text': 'Soru?',
      'answers': [
        {'index': 2, 'text': 'B'},
        {'index': 1, 'text': 'A'},
        {'index': 4, 'text': 'D'},
        {'index': 3, 'text': 'C'},
      ],
      'has_hint': false,
      'time_limit_seconds': 30,
      'expires_at': '2026-11-09T10:00:45.000Z',
      'remaining_seconds': 45,
      'used_powers': <String>[],
    };

    test('medya anahtarlari varken alanlar dolar', () async {
      final h = _Harness(
        (_) => {
          ...legacy,
          'voice_url': _voiceUrl,
          'voice_duration_ms': 4200,
          'image_url': _imageUrl,
          'media_extra_seconds': 15,
        },
        status: 200,
      );

      final q = await QuizService(h.dio).getCurrentQuestion('s1');

      expect(q.voiceUrl, _voiceUrl);
      expect(q.voiceDurationMs, 4200);
      expect(q.imageUrl, _imageUrl);
      expect(q.mediaExtraSeconds, 15);
      expect(q.answers, hasLength(4));
    });

    test('kapi kapali (anahtar yok, eski sozlesme) → null / 0', () async {
      final h = _Harness((_) => legacy, status: 200);

      final q = await QuizService(h.dio).getCurrentQuestion('s1');

      expect(q.voiceUrl, isNull);
      expect(q.voiceDurationMs, isNull);
      expect(q.imageUrl, isNull);
      expect(q.mediaExtraSeconds, 0);
    });
  });

  group('GET /matches/discover — question_info rozetleri', () {
    test('has_voice / has_image varken dolar, yokken false', () async {
      final h = _Harness(
        (_) => {
          'cards': [
            {
              'user_id': 'u2',
              'question_count': 3,
              'question_info': {
                'count': 3,
                'categories': ['music'],
                'avg_difficulty': 'medium',
                'languages': ['tr'],
                'has_voice': true,
                'has_image': false,
              },
            },
            {
              'user_id': 'u3',
              'question_count': 2,
              'question_info': {
                'count': 2,
                'categories': <String>[],
                'avg_difficulty': 'easy',
                'languages': ['tr'],
              },
            },
          ],
          'page': 1,
          'has_more': false,
        },
        status: 200,
      );

      final res = await MatchService(h.dio).discover(1);

      expect(res.cards.first.questionInfo?.hasVoice, isTrue);
      expect(res.cards.first.questionInfo?.hasImage, isFalse);
      expect(res.cards.last.questionInfo?.hasVoice, isFalse);
      expect(res.cards.last.questionInfo?.hasImage, isFalse);
    });
  });
}
