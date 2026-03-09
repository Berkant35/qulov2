import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/power_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class PowerNotifier extends AsyncNotifier<List<PowerModel>> {
  @override
  Future<List<PowerModel>> build() async => [];

  Future<void> fetchPowers() async {
    state = const AsyncLoading();
    final result = await ref.read(powerRepositoryProvider).getPowers();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }
}

final powerProvider = AsyncNotifierProvider<PowerNotifier, List<PowerModel>>(PowerNotifier.new);
