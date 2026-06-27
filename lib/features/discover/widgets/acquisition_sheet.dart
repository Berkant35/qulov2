import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/acquisition_channel_model.dart';
import 'package:qulo_v2/providers/acquisition_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class AcquisitionSheet extends ConsumerStatefulWidget {
  const AcquisitionSheet({super.key});

  @override
  ConsumerState<AcquisitionSheet> createState() => _AcquisitionSheetState();
}

class _AcquisitionSheetState extends ConsumerState<AcquisitionSheet> {
  String? _selectedId;
  bool _selectedFreeform = false;
  final _freeformController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _freeformController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool skip}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final result = await ref.read(acquisitionProvider.notifier).submit(
          channelId: skip ? null : _selectedId,
          skipped: skip,
          freeformText: _selectedFreeform ? _freeformController.text.trim() : null,
        );
    if (!mounted) return;
    result.when(
      success: (_) => ref.read(userProvider.notifier).fetchMe(),
      failure: (_) {},
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(acquisitionProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                  _ChannelTile(
                    channel: c,
                    selected: _selectedId == c.id,
                    onTap: () => setState(() {
                      _selectedId = c.id;
                      _selectedFreeform = c.isFreeform;
                    }),
                  ),
                if (_selectedFreeform)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: TextField(
                      controller: _freeformController,
                      decoration: InputDecoration(
                        hintText: context.tr('acq_other_hint'),
                      ),
                      maxLength: 280,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: (_selectedId == null || _submitting)
                ? null
                : () => _submit(skip: false),
            child: _submitting
                ? const AppLoadingWidget.small()
                : Text(context.tr('acq_continue')),
          ),
          TextButton(
            onPressed: _submitting ? null : () => _submit(skip: true),
            child: Text(context.tr('acq_skip')),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final AcquisitionChannel channel;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.cardPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (channel.emoji != null) ...[
                Text(channel.emoji!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(child: Text(channel.label)),
              if (selected) Icon(Icons.check_circle, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
