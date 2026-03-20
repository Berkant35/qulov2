import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key});

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> with LoadingMixin {
  final _analytics = AnalyticsManager.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final passport = ref.read(passportProvider);
      _analytics.logEvent(AnalyticsEvents.passportScreenView, params: {
        AnalyticsEvents.paramIsActive: passport.isActive ? 1 : 0,
      });
    });
  }

  Future<void> _openMapPicker() async {
    final nav = ref.read(navigationServiceProvider);
    final result = await nav.push<Map<String, dynamic>>(RouteNames.mapPicker);
    if (result == null || !mounted) return;

    final city = result['city'] as String?;
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;

    if (city == null || city.isEmpty) return;

    await withLoading(() async {
      final result = await ref.read(passportProvider.notifier).activate(city: city, lat: lat, lng: lng);
      result.when(
        success: (_) {
          _analytics.logEvent(AnalyticsEvents.passportActivate, params: {
            AnalyticsEvents.paramDestinationCity: city,
          });
        },
        failure: (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('passport_activate_failed'))),
            );
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final passport = ref.watch(passportProvider);
    final subscription = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);
    final isPremium = subscription.valueOrNull?.isPremium ?? false;

    // Premium gate
    if (!isPremium) {
      return AppScaffold(
        title: context.tr('passport'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QIcon(QIcons.icLock, size: 64, color: AppColors.textHint),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.tr('passport_premium_only'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr('passport_premium_desc'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => PaywallBottomSheetContent.show(ref, trigger: 'passport_locked'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
                    child: Text(context.tr('upgrade_to_premium')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: context.tr('passport'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.flight, size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            passport.isActive
                ? '${context.tr("passport_active")}: ${passport.city}'
                : context.tr('passport_explore'),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          if (!passport.isActive) ...[
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: isLoading ? null : _openMapPicker,
                icon: const Icon(Icons.map),
                label: isLoading
                    ? const SizedBox(height: 20, width: 20, child: AppLoadingWidget.small())
                    : Text(context.tr('passport_pick_on_map')),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flight_takeoff, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passport.city ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          context.tr('passport_active_desc'),
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        final city = ref.read(passportProvider).city ?? '';
                        withLoading(() async {
                          final result = await ref.read(passportProvider.notifier).deactivate();
                          result.when(
                            success: (_) {
                              _analytics.logEvent(AnalyticsEvents.passportDeactivate, params: {
                                AnalyticsEvents.paramDestinationCity: city,
                              });
                            },
                            failure: (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(context.tr('passport_deactivate_failed'))),
                                );
                              }
                            },
                          );
                        });
                      },
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: AppLoadingWidget.small())
                    : Text(context.tr('passport_deactivate')),
              ),
            ),
          ],

        ],
      ),
    );
  }
}
