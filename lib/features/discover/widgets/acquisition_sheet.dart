import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/discover/mixins/acquisition_sheet_mixin.dart';
import 'package:qulo_v2/features/discover/widgets/acquisition_channel_list.dart';
import 'package:qulo_v2/features/discover/widgets/acquisition_unavailable.dart';
import 'package:qulo_v2/providers/acquisition_provider.dart';
class AcquisitionSheet extends ConsumerStatefulWidget {
  const AcquisitionSheet({super.key});

  @override
  ConsumerState<AcquisitionSheet> createState() => _AcquisitionSheetState();
}

class _AcquisitionSheetState extends ConsumerState<AcquisitionSheet>
    with AcquisitionSheetMixin {
  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(acquisitionProvider);
    return SingleChildScrollView(
      // Klavye (freeform TextField) açılınca içeriği yukarı iter → yazılan görünür.
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('acq_title'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('acq_subtitle'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          channelsAsync.when(
            loading: () => const Center(child: AppLoadingWidget.large()),
            error: (_, __) => AcquisitionUnavailable(onDismiss: dismiss),
            // Provider hatayı boş listeye çeviriyor; Atla kalktığı için burada
            // çıkış yolu şart — sonraki Discover girişinde yeniden sorulur.
            data: (channels) => channels.isEmpty
                ? AcquisitionUnavailable(onDismiss: dismiss)
                : AcquisitionChannelList(
                    channels: channels,
                    selectedId: selectedChannel?.id,
                    onSelect: selectChannel,
                    freeformController:
                        isFreeformSelected ? freeformController : null,
                    submitting: submitting,
                    onSubmit:
                        (selectedChannel == null || submitting) ? null : submit,
                  ),
          ),
        ],
      ),
    );
  }
}
