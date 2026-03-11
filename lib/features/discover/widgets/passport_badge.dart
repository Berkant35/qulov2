import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/passport_provider.dart';

class PassportBadge extends ConsumerWidget {
  const PassportBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passport = ref.watch(passportProvider);
    if (!passport.isActive) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              passport.city ?? '',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
