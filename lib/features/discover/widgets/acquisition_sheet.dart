import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/discover/mixins/acquisition_sheet_mixin.dart';
import 'package:qulo_v2/features/discover/widgets/acquisition_channel_tile.dart';
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
            error: (_, __) => Center(
              child: Text(
                context.tr('acq_error'),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            data: (channels) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in channels)
                  AcquisitionChannelTile(
                    channel: c,
                    selected: selectedChannel?.id == c.id,
                    onTap: () => selectChannel(c),
                  ),
                if (isFreeformSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: TextField(
                      controller: freeformController,
                      decoration: InputDecoration(
                        hintText: context.tr('acq_other_hint'),
                      ),
                      maxLength: AppConstants.acquisitionFreeformMaxLength,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: (selectedChannel == null || submitting)
                ? null
                : () => submit(skip: false),
            child: submitting
                ? const AppLoadingWidget.small()
                : Text(context.tr('acq_continue')),
          ),
          TextButton(
            onPressed: submitting ? null : () => submit(skip: true),
            child: Text(context.tr('acq_skip')),
          ),
        ],
      ),
    );
  }
}
