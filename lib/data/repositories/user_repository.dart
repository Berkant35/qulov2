import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/user_service.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/models/notification_preferences_model.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class UserRepository implements IUserRepository {
  final UserService _service;
  final NetworkManager _network;

  UserRepository(this._service, this._network);

  @override
  Future<Result<UserModel>> getMe() async {
    try {
      final response = await _service.getMe();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<UserModel>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _service.updateProfile(data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<UserDetailsModel>> updateDetails(Map<String, dynamic> data) async {
    try {
      final response = await _service.updateDetails(data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> updateLocation({required double lat, required double lng, String? city}) async {
    try {
      final data = <String, dynamic>{'lat': lat, 'lng': lng};
      if (city != null) data['city'] = city;
      await _service.updateLocation(data);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> updatePushToken(String token) async {
    try {
      await _service.updatePushToken({'push_token': token});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  DateTime? _lastHeartbeat;
  static const Duration _heartbeatDebounce = Duration(minutes: 5);

  @override
  Future<Result<void>> heartbeat() async {
    if (_lastHeartbeat != null &&
        DateTime.now().difference(_lastHeartbeat!) < _heartbeatDebounce) {
      return const Success(null);
    }
    _lastHeartbeat = DateTime.now();
    try {
      await _service.heartbeat();
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> uploadPhoto(Uint8List bytes, String mimeType) async {
    final ext = mimeType == 'image/png' ? 'png' : 'jpg';
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(
        bytes,
        filename: 'photo.$ext',
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    return _network.upload('/users/me/photos', data: formData);
  }

  @override
  Future<Result<Map<String, dynamic>>> deletePhoto(int index) async {
    return _network.delete('/users/me/photos/$index');
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _service.deleteAccount();
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> boost() async {
    return _network.post('/users/me/boost');
  }

  @override
  Future<Result<Map<String, dynamic>>> claimBadgeReward(String level) async {
    return _network.post('/users/me/claim-badge-reward', data: {'level': level});
  }

  @override
  Future<Result<UserModel>> reorderPhotos(List<String> photos) async {
    try {
      final response = await _service.updateProfile({'photos': photos});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<PublicProfileModel>> getPublicProfile(String userId) async {
    try {
      final response = await _service.getPublicProfile(userId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<NotificationPreferencesModel>> getNotificationPreferences() async {
    try {
      final response = await _service.getNotificationPreferences();
      final model = NotificationPreferencesModel.fromJson(
        response as Map<String, dynamic>,
      );
      return Success(model);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<NotificationPreferencesModel>> updateNotificationPreferences(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _service.updateNotificationPreferences(body);
      final model = NotificationPreferencesModel.fromJson(
        response as Map<String, dynamic>,
      );
      return Success(model);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<List<String>>> getUserLanguages() async {
    final result = await _network.get<Map<String, dynamic>>('/users/me/languages');
    return result.when(
      success: (data) => Success(List<String>.from(data['languages'] ?? [])),
      failure: (f) => Failure(f),
    );
  }

  Future<Result<List<String>>> setUserLanguages(List<String> languages) async {
    final result = await _network.put<Map<String, dynamic>>(
      '/users/me/languages',
      data: {'languages': languages},
    );
    return result.when(
      success: (data) => Success(List<String>.from(data['languages'] ?? [])),
      failure: (f) => Failure(f),
    );
  }
}
