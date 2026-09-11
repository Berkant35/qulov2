import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/acquisition_channel_model.dart';
import 'package:qulo_v2/features/discover/widgets/acquisition_sheet.dart';
import 'package:qulo_v2/providers/acquisition_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// "Bizi nereden duydun" sheet'inin secim ve gonderim logic'i.
mixin AcquisitionSheetMixin on ConsumerState<AcquisitionSheet> {
  AcquisitionChannel? selectedChannel;
  bool submitting = false;
  final freeformController = TextEditingController();

  bool get isFreeformSelected => selectedChannel?.isFreeform ?? false;

  void disposeMixin() => freeformController.dispose();

  void selectChannel(AcquisitionChannel channel) =>
      setState(() => selectedChannel = channel);

  Future<void> submit({required bool skip}) async {
    if (submitting) return;
    setState(() => submitting = true);
    final result = await ref.read(acquisitionProvider.notifier).submit(
          channelId: skip ? null : selectedChannel?.id,
          skipped: skip,
          freeformText: isFreeformSelected ? freeformController.text.trim() : null,
        );
    if (!mounted) return;
    result.when(
      success: (_) => ref.read(userProvider.notifier).fetchMe(),
      failure: (_) {},
    );
    Navigator.of(context).pop();
  }
}
