import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/pending_change_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class PendingChangesNotifier extends AsyncNotifier<List<PendingChangeModel>> {
  @override
  Future<List<PendingChangeModel>> build() async => [];

  Future<void> fetchPending() async {
    state = const AsyncLoading();
    final result = await ref.read(questionRepositoryProvider).getPendingChanges();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  Future<void> cancelChange(String changeId) async {
    await ref.read(questionRepositoryProvider).cancelPendingChange(changeId);
    await fetchPending();
  }
}

final pendingChangesProvider =
    AsyncNotifierProvider<PendingChangesNotifier, List<PendingChangeModel>>(
  PendingChangesNotifier.new,
);
