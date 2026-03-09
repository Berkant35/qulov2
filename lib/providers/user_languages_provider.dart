import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class UserLanguagesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async => [];

  Future<void> fetch() async {
    state = const AsyncLoading();
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.getUserLanguages();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (error) => AsyncError(error, StackTrace.current),
    );
  }

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
