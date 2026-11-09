import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';
import 'package:qulo_v2/features/profile_detail/mixins/profile_details_grid_mixin.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_detail_chip.dart';

class ProfileDetailsGrid extends StatelessWidget with ProfileDetailsGridWidgetMixin {
  final UserDetailsModel details;
  const ProfileDetailsGrid({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final chips = detailChips(context, details);
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('details'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final chip in chips) ProfileDetailChip(chip: chip)],
          ),
        ],
      ),
    );
  }
}
