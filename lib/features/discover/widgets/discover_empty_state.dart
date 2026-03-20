import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class DiscoverEmptyState extends ConsumerStatefulWidget {
  const DiscoverEmptyState({super.key});

  @override
  ConsumerState<DiscoverEmptyState> createState() => _DiscoverEmptyStateState();
}

class _DiscoverEmptyStateState extends ConsumerState<DiscoverEmptyState> {
  late double _radius;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).valueOrNull;
    _radius = (user?.matchRadiusKm ?? 50).toDouble();
  }

  Future<void> _updateRadiusAndSearch() async {
    setState(() => _isSearching = true);

    await ref.read(userProvider.notifier).updateProfile({
      'match_radius_km': _radius.round(),
    });

    await ref.read(discoverProvider.notifier).loadCards();

    if (mounted) setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passport = ref.watch(passportProvider);
    final subscription = ref.watch(subscriptionProvider);
    final isPremium = subscription.valueOrNull?.isPremium ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QIcon(QIcons.icCompassOff, size: 64, color: context.appColors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('no_more_profiles'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('no_more_profiles_hint'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Inline radius slider
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.appColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: context.appColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('match_radius'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_radius.round()} km',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _radius,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _radius = val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '5 km',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.appColors.textHint,
                        ),
                      ),
                      Text(
                        '200 km',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.appColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isSearching ? null : _updateRadiusAndSearch,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: _isSearching
                          ? const AppLoadingWidget.small()
                          : Text(context.tr('search_again')),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Passport hints
            if (passport.isActive) ...[
              TextButton.icon(
                onPressed: () => ref
                    .read(navigationServiceProvider)
                    .push(RouteNames.passport),
                icon: const Icon(Icons.flight, size: 16),
                label: Text(context.tr('passport_change_city')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ] else if (isPremium) ...[
              TextButton.icon(
                onPressed: () => ref
                    .read(navigationServiceProvider)
                    .push(RouteNames.passport),
                icon: const Icon(Icons.flight, size: 16),
                label: Text(context.tr('passport_explore_hint')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ] else ...[
              TextButton.icon(
                onPressed: () => ref
                    .read(navigationServiceProvider)
                    .push(RouteNames.subscription),
                icon: const Icon(Icons.flight, size: 16),
                label: Text(context.tr('passport_premium_explore_hint')),
                style: TextButton.styleFrom(
                  foregroundColor: context.appColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
