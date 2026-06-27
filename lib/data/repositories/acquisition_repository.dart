import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/acquisition_service.dart';
import 'package:qulo_v2/data/models/acquisition_channel_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class AcquisitionRepository implements IAcquisitionRepository {
  final AcquisitionService _service;

  AcquisitionRepository(this._service);

  @override
  Future<Result<List<AcquisitionChannel>>> getChannels() async {
    try {
      final response = await _service.getChannels();
      final list = (response['channels'] as List)
          .map((e) => AcquisitionChannel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(list);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  @override
  Future<Result<void>> submitAnswer({
    String? channelId,
    bool skipped = false,
    String? freeformText,
  }) async {
    try {
      await _service.submitAnswer({
        if (channelId != null) 'channel_id': channelId,
        if (skipped) 'skipped': true,
        if (freeformText != null && freeformText.isNotEmpty)
          'freeform_text': freeformText,
      });
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
