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
