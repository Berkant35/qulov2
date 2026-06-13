import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';

class UserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async => null;

  Future<void> fetchMe() async {
    // Preserve previous value during loading so UI doesn't flash to 0
    final previous = state.valueOrNull;
    state = previous != null
        ? const AsyncLoading<UserModel?>().copyWithPrevious(AsyncData(previous))
        : const AsyncLoading();
    final result = await ref.read(userRepositoryProvider).getMe();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  /// Returns the old completionRewardsClaimed map (snapshot before any update).
  Map<String, dynamic> get currentRewardsClaimed =>
      Map<String, dynamic>.from(state.value?.completionRewardsClaimed ?? {});

  Future<Result<UserModel>> updateProfile(Map<String, dynamic> data) async {
    final result = await ref.read(userRepositoryProvider).updateProfile(data);
    if (result.isSuccess) {
      await fetchMe();
    } else {
      result.when(
        success: (_) {},
        failure: (f) => dev.log('updateProfile failed: $f', name: 'UserNotifier'),
      );
    }
    return result;
  }

  /// Compares old and new completionRewardsClaimed to find newly claimed milestones.
  List<int> detectNewMilestones(Map<String, dynamic> oldClaimed) {
    final newClaimed = state.value?.completionRewardsClaimed ?? {};
    final milestones = <int>[];
    for (final m in [25, 50, 75, 100]) {
      if (newClaimed[m.toString()] == true && oldClaimed[m.toString()] != true) {
        milestones.add(m);
      }
    }
    return milestones;
  }

  Future<Result<void>> updateDetails(Map<String, dynamic> data) async {
    final result = await ref.read(userRepositoryProvider).updateDetails(data);
    if (result.isSuccess) {
      await fetchMe();
    } else {
      result.when(
        success: (_) {},
        failure: (f) => dev.log('updateDetails failed: $f', name: 'UserNotifier'),
      );
    }
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
    result.when(
      success: (_) => fetchMe(),
      failure: (f) => dev.log('boost failed: $f', name: 'UserNotifier'),
    );
    return result;
  }

  Future<Result<void>> deleteAccount() async {
    return ref.read(userRepositoryProvider).deleteAccount();
  }

  Future<Result<Map<String, dynamic>>> claimBadgeReward(String level) async {
    final result = await ref.read(userRepositoryProvider).claimBadgeReward(level);
    result.when(
      success: (_) => fetchMe(),
      failure: (f) => dev.log('claimBadgeReward failed: $f', name: 'UserNotifier'),
    );
    return result;
  }

  Future<Result<UserModel>> reorderPhotos(List<String> photos) async {
    final result = await ref.read(userRepositoryProvider).reorderPhotos(photos);
    result.when(
      success: (updated) => state = AsyncData(updated),
      failure: (f) => dev.log('reorderPhotos failed: $f', name: 'UserNotifier'),
    );
    return result;
  }

  Future<Result<Map<String, dynamic>>> setInterests(List<String> interests) async {
    final result = await ref.read(userRepositoryProvider).setInterests(interests);
    if (result.isSuccess) {
      await fetchMe();
    } else {
      result.when(
        success: (_) {},
        failure: (f) => dev.log('setInterests failed: $f', name: 'UserNotifier'),
      );
    }
    return result;
  }

  Future<Result<Map<String, dynamic>>> quickAssignQuestions() async {
    final result = await ref.read(userRepositoryProvider).quickAssignQuestions();
    if (result.isSuccess) {
      await fetchMe();
      // Invalidate question provider so question list refreshes
      ref.invalidate(questionProvider);
    } else {
      result.when(
        success: (_) {},
        failure: (f) => dev.log('quickAssignQuestions failed: $f', name: 'UserNotifier'),
      );
    }
    return result;
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, UserModel?>(UserNotifier.new);
