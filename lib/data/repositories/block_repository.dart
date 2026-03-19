import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/block_service.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class BlockRepository implements IBlockRepository {
  final BlockService _service;

  BlockRepository(this._service);

  @override
  Future<Result<void>> blockUser(String blockedId) async {
    try {
      await _service.blockUser({'blocked_id': blockedId});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> unblockUser(String blockedId) async {
    try {
      await _service.unblockUser(blockedId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
