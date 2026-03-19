import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/match_service.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class MatchRepository implements IMatchRepository {
  final MatchService _service;

  MatchRepository(this._service);

  @override
  Future<Result<DiscoverResponse>> discover({int page = 1}) async {
    try {
      final response = await _service.discover(page);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<SwipeResponse>> swipe({required String targetId, required String action}) async {
    try {
      final response = await _service.swipe({
        'target_id': targetId,
        'action': action,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<List<MatchModel>>> getMatches() async {
    try {
      final response = await _service.getMatches();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<ProfileCardModel>> undoSwipe(String targetId) async {
    try {
      final response = await _service.undoSwipe(targetId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> unmatch(String matchId) async {
    try {
      await _service.unmatch(matchId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
