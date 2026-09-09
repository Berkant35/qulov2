import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/discover/mixins/discover_scope_chip_mixin.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Aramanin hangi kapsamda oldugunu soyleyen ekran seviyesi chip.
///
/// Icerigi ustteki karttan turer: chip her zaman ekranda gorunen kartla
/// tutarli olur ve sunucuda ayrica kapsam state'i tutmak gerekmez.
class DiscoverScopeChip extends ConsumerWidget with DiscoverScopeChipMixin {
  const DiscoverScopeChip({super.key, required this.card});

  final ProfileCardModel card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expanded = isExpanded(card.distanceTier);
    final label = scopeLabel(
      context,
      distanceTier: card.distanceTier,
      distanceKm: card.distanceKm,
    );
    final accent = expanded ? context.appColors.primary : context.appColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          // Radius slider'i profil DUZENLEME ekraninda
          // (features/profile/widgets/edit_profile_preferences_section.dart:109).
          onTap: () => ref.read(navigationServiceProvider).push(RouteNames.editProfile),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: expanded
                  ? context.appColors.primary.withValues(alpha: 0.12)
                  : context.appColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: expanded ? context.appColors.primary : context.appColors.border,
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
