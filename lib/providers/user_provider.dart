import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class UserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async => null;

  Future<void> fetchMe() async {
    state = const AsyncLoading();
    final result = await ref.read(userRepositoryProvider).getMe();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  Future<Result<UserModel>> updateProfile(Map<String, dynamic> data) async {
    final result = await ref.read(userRepositoryProvider).updateProfile(data);
    result.when(
      success: (updated) => state = AsyncData(updated),
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> updateDetails(Map<String, dynamic> data) async {
    final result = await ref.read(userRepositoryProvider).updateDetails(data);
    result.when(
      success: (_) => fetchMe(),
      failure: (_) {},
    );
    return result;
  }

  Future<void> updateLocation({required double lat, required double lng}) async {
    await ref.read(userRepositoryProvider).updateLocation(lat: lat, lng: lng);
  }

  Future<void> updatePushToken(String token) async {
    await ref.read(userRepositoryProvider).updatePushToken(token);
  }

  Future<Result<Map<String, dynamic>>> uploadPhoto(dynamic bytes, String mimeType) async {
    final result = await ref.read(userRepositoryProvider).uploadPhoto(bytes, mimeType);
    if (result.isSuccess) await fetchMe();
    return result;
  }

  Future<Result<void>> deletePhoto(int index) async {
    final result = await ref.read(userRepositoryProvider).deletePhoto(index);
    if (result.isSuccess) await fetchMe();
    return result;
  }

  Future<Result<Map<String, dynamic>>> boost() async {
    final result = await ref.read(userRepositoryProvider).boost();
    result.when(success: (_) => fetchMe(), failure: (_) {});
    return result;
  }

  Future<Result<void>> deleteAccount() async {
    return ref.read(userRepositoryProvider).deleteAccount();
  }

  Future<Result<Map<String, dynamic>>> claimBadgeReward(String level) async {
    final result = await ref.read(userRepositoryProvider).claimBadgeReward(level);
    result.when(success: (_) => fetchMe(), failure: (_) {});
    return result;
  }

  Future<Result<UserModel>> reorderPhotos(List<String> photos) async {
    final result = await ref.read(userRepositoryProvider).reorderPhotos(photos);
    result.when(
      success: (updated) => state = AsyncData(updated),
      failure: (_) {},
    );
    return result;
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, UserModel?>(UserNotifier.new);
