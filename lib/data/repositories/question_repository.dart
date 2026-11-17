import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/question_service.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class QuestionRepository implements IQuestionRepository {
  final QuestionService _service;
  final NetworkManager _network;

  QuestionRepository(this._service, this._network);

  @override
  Future<Result<List<QuestionModel>>> getMyQuestions() async {
    try {
      final response = await _service.getMyQuestions();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<QuestionModel>> createQuestion(Map<String, dynamic> data) async {
    try {
      final response = await _service.createQuestion(data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<QuestionModel>> updateQuestion(int orderNum, Map<String, dynamic> data) async {
    try {
      final response = await _service.updateQuestion(orderNum, data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> deleteQuestion(int orderNum) async {
    try {
      await _service.deleteQuestion(orderNum);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  /// Ses kaydi (m4a/aac, <=15 sn). `durationMs` sunucuda 1..15000 dogrulanir.
  Future<Result<QuestionModel>> uploadVoice(int orderNum, File file, int durationMs) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'voice.m4a',
          contentType: DioMediaType.parse('audio/mp4'),
        ),
        'duration_ms': durationMs.toString(),
      });
      return Success(await _service.uploadVoice(orderNum, form));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  /// Gorsel (jpeg/png/webp). Sunucu senkron moderasyon yapar; yanitta
  /// `image_status` approved/rejected/pending doner.
  Future<Result<QuestionModel>> uploadImage(int orderNum, Uint8List bytes, String mimeType) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'image.${_imageExtension(mimeType)}',
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      return Success(await _service.uploadImage(orderNum, form));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  Future<Result<void>> removeMedia(int orderNum, QuestionMediaKind kind) async {
    try {
      await _service.deleteMedia(orderNum, kind.wireName);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  static String _imageExtension(String mimeType) => switch (mimeType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => 'jpg',
      };

  @override
  Future<Result<List<QuestionModel>>> reorderQuestions(List<String> orderedIds) async {
    try {
      final response = await _service.reorderQuestions({'order': orderedIds});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<int>> getQuestionCount() async {
    return _network.get<int>(
      '/questions/count/me',
      parser: (json) {
        if (json is! Map<String, dynamic>) return 0;
        final count = json['count'];
        return count is int ? count : 0;
      },
    );
  }

  Future<Result<QuestionAnalyticsResponse>> getAnalytics() async {
    try {
      final data = await _service.getAnalytics();
      return Success(data);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<Map<String, dynamic>>> getWeeklyReport() async {
    try {
      final data = await _service.getWeeklyReport();
      return Success(data);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<Map<String, dynamic>>> getAiSuggestions(Map<String, dynamic> body) async {
    try {
      final data = await _service.getAiSuggestions(body);
      return Success(data);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
