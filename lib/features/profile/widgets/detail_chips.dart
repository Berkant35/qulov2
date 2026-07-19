import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/profile/mixins/detail_chips_mixin.dart';
import 'package:qulo_v2/features/profile/widgets/detail_chip_item.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';

class DetailChips extends ConsumerWidget with DetailChipsWidgetMixin {
  final UserModel user;
  final bool isOwnProfile;
  final VoidCallback? onTap;

  const DetailChips({
    super.key,
    required this.user,
    this.isOwnProfile = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? locationLabel;
    if (isOwnProfile) {
      final passport = ref.watch(passportProvider);
      final location = ref.watch(locationProvider);
      locationLabel = passport.isActive && passport.city != null
          ? '${location.city ?? "?"} → ${passport.city}'
          : location.city;
    }

    final chips = buildChips(
      context,
      details: user.details,
      locationLabel: locationLabel,
    );

    return GestureDetector(
      onTap: onTap,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: chips.map((chip) => DetailChipItem(chip: chip)).toList(),
      ),
    );
  }
}
