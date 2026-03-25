import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class UserLanguagesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async => [];

  /// Fetch languages from userProvider (single source of truth)
  void syncFromUser() {
    final user = ref.read(userProvider).valueOrNull;
    if (user != null && user.preferredLanguages.isNotEmpty) {
      state = AsyncData(user.preferredLanguages);
    }
  }

  /// Fetch languages from dedicated API endpoint
  Future<void> fetch() async {
    state = const AsyncLoading();
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.getUserLanguages();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (error) => AsyncError(error, StackTrace.current),
    );
  }

  /// Save languages via dedicated API + sync user_languages table
  Future<void> save(List<String> languages) async {
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.setUserLanguages(languages);
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (error) => AsyncError(error, StackTrace.current),
    );
  }
}

final userLanguagesProvider =
    AsyncNotifierProvider<UserLanguagesNotifier, List<String>>(
  UserLanguagesNotifier.new,
);
