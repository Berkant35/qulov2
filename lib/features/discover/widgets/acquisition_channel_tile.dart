import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/acquisition_channel_model.dart';
import 'package:qulo_v2/features/discover/widgets/acquisition_channel_icon.dart';

class AcquisitionChannelTile extends StatelessWidget {
  const AcquisitionChannelTile({
    super.key,
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  final AcquisitionChannel channel;
  final bool selected;
  final VoidCallback onTap;

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
              width: selected ? AppSizes.borderSelected : AppSizes.borderThin,
            ),
          ),
          child: Row(
            children: [
              if (channel.hasIcon) ...[
                AcquisitionChannelIcon(channel: channel),
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
