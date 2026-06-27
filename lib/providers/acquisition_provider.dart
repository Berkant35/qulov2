import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/acquisition_channel_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class AcquisitionNotifier extends AsyncNotifier<List<AcquisitionChannel>> {
  @override
  Future<List<AcquisitionChannel>> build() async {
    final result = await ref.read(acquisitionRepositoryProvider).getChannels();
    return result.when(
      success: (data) => data,
      failure: (_) => <AcquisitionChannel>[],
    );
  }

  Future<Result<void>> submit({
    String? channelId,
    bool skipped = false,
    String? freeformText,
  }) {
    return ref.read(acquisitionRepositoryProvider).submitAnswer(
          channelId: channelId,
          skipped: skipped,
          freeformText: freeformText,
        );
  }
}

final acquisitionProvider =
    AsyncNotifierProvider<AcquisitionNotifier, List<AcquisitionChannel>>(
  AcquisitionNotifier.new,
);
