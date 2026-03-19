import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/pending_change_model.dart';

class PendingChangesNotifier extends AsyncNotifier<List<PendingChangeModel>> {
  @override
  Future<List<PendingChangeModel>> build() async => [];

  
}

final pendingChangesProvider =
    AsyncNotifierProvider<PendingChangesNotifier, List<PendingChangeModel>>(
  PendingChangesNotifier.new,
);
