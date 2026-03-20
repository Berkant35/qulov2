import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class PassportBadge extends ConsumerWidget {
  const PassportBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passport = ref.watch(passportProvider);
    final location = ref.watch(locationProvider);
    final isPassportActive = passport.isActive;
    final city = isPassportActive ? passport.city : location.city;

    if (city == null || city.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => ref.read(navigationServiceProvider).push(RouteNames.passport),
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: isPassportActive ? AppColors.primarySurface : AppColors.surfaceInput,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isPassportActive
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPassportActive ? Icons.flight : Icons.location_on,
                size: 14,
                color: isPassportActive ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                city,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isPassportActive ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
