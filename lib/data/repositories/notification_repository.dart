import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/notification_service.dart';
import 'package:qulo_v2/data/models/notification_model.dart';

class NotificationRepository {
  final NotificationRetrofitService _service;

  NotificationRepository(this._service);

  Future<Result<List<NotificationModel>>> getNotifications(
    int page,
    int limit,
  ) async {
    try {
      final response = await _service.getNotifications(page, limit);
      final list = (response['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(list);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<int>> getUnreadCount() async {
    try {
      final response = await _service.getUnreadCount();
      return Success((response['unreadCount'] as num?)?.toInt() ?? 0);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> trackClick(String id) async {
    try {
      await _service.trackClick(id);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
