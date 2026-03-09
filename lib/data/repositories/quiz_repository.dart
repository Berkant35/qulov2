import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/quiz_service.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/models/quiz_summary_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class QuizRepository implements IQuizRepository {
  final QuizService _service;

  QuizRepository(this._service);

  @override
  Future<Result<QuizStartResponse>> startSession(String targetId) async {
    try {
      final response = await _service.startSession({'target_id': targetId});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<QuizQuestionModel>> getCurrentQuestion(String sessionId) async {
    try {
      final response = await _service.getCurrentQuestion(sessionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<QuizAnswerResponse>> answerQuestion(
    String sessionId, {
    int? selectedAnswer,
    String? powerUsed,
    int? timeSpent,
  }) async {
    try {
      final response = await _service.answerQuestion(sessionId, {
        if (selectedAnswer != null) 'selected_answer': selectedAnswer,
        if (powerUsed != null) 'power_used': powerUsed,
        if (timeSpent != null) 'time_spent': timeSpent,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<QuizAnswerResponse>> rescueWithSkip(String sessionId) async {
    try {
      final response = await _service.rescueWithSkip(sessionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<QuizAnswerResponse>> failSession(String sessionId) async {
    try {
      final response = await _service.failSession(sessionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<QuizResultModel>> getSessionResult(String sessionId) async {
    try {
      final response = await _service.getSessionResult(sessionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<QuizSummaryModel?>> getMatchQuizSummary(String matchId) async {
    try {
      final data = await _service.getMatchQuizSummary(matchId);
      return Success(data);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
