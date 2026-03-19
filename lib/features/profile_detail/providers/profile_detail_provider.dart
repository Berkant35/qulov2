import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

final profileDetailProvider = AsyncNotifierProvider.autoDispose
    .family<ProfileDetailNotifier, PublicProfileModel, String>(
  ProfileDetailNotifier.new,
);

class ProfileDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<PublicProfileModel, String> {
  @override
  Future<PublicProfileModel> build(String userId) => _fetch(userId);

  Future<PublicProfileModel> _fetch(String userId) {
    return ref
        .read(userRepositoryProvider)
        .getPublicProfile(userId)
        .then((result) => result.when(
              success: (data) => data,
              failure: (f) => throw f,
            ));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}
