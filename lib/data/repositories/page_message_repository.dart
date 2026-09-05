import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/page_message_service.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';

class PageMessageRepository {
  final PageMessageRetrofitService _service;

  PageMessageRepository(this._service);

  Future<Result<List<PageMessageModel>>> getMessages() async {
    try {
      final response = await _service.getMessages();
      final raw = response['messages'];
      if (raw is! List) return const Success([]);
      final list = raw
          .whereType<Map<String, dynamic>>()
          .map(PageMessageModel.fromJson)
          .toList();
      return Success(list);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<void> trackEvent(String id, String event) async {
    try {
      await _service.trackEvent(id, {'event': event});
    } on DioException {
      // event tracking best-effort; sessizce yut
    }
  }
}
