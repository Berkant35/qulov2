import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/teleport_service.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/features/passport/data/popular_cities.dart';
import 'package:qulo_v2/features/passport/widgets/city_search_bar.dart';
import 'package:qulo_v2/features/passport/widgets/passport_active_card.dart';
import 'package:qulo_v2/features/passport/widgets/popular_city_grid.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key});

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> with LoadingMixin {
  final _analytics = AnalyticsManager.instance;
  bool _isChangingCity = false;

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

  void _navigateToConfirm({
    required String city,
    required String country,
    required String flag,
    required double lat,
    required double lng,
  }) {
    ref.read(navigationServiceProvider).push(
      RouteNames.mapConfirm,
      extra: {'cityName': city, 'country': country, 'flag': flag, 'lat': lat, 'lng': lng},
    );
  }

  void _onSearchCitySelected(TeleportCity city) {
    _analytics.logEvent(AnalyticsEvents.passportCitySearch, params: {
      AnalyticsEvents.paramDestinationCity: city.name,
    });
    final country = city.fullName.contains(',')
        ? city.fullName.split(',').last.trim()
        : city.fullName;
    _navigateToConfirm(city: city.name, country: country, flag: '🌍', lat: city.lat, lng: city.lng);
  }

  void _onPopularCitySelected(PopularCity city) {
    _analytics.logEvent(AnalyticsEvents.passportPopularCityTap, params: {
      AnalyticsEvents.paramDestinationCity: city.name,
    });
    _navigateToConfirm(city: city.name, country: city.country, flag: city.flag, lat: city.lat, lng: city.lng);
  }

  Future<void> _onDeactivate() async {
    final city = ref.read(passportProvider).city ?? '';
    await withLoading(() async {
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
                QIcon(QIcons.icLock, size: 64, color: context.appColors.textHint),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.tr('passport_premium_only'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr('passport_premium_desc'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => PaywallBottomSheetContent.show(ref, trigger: 'passport_locked'),
                    style: FilledButton.styleFrom(backgroundColor: context.appColors.primaryDark),
                    child: Text(context.tr('upgrade_to_premium')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Active state (but allow switching to search when _isChangingCity)
    if (passport.isActive && !_isChangingCity) {
      return AppScaffold(
        title: context.tr('passport'),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PassportActiveCard(city: passport.city ?? ''),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          _analytics.logEvent(AnalyticsEvents.passportChangeCity, params: {
                            AnalyticsEvents.paramFromCity: passport.city ?? '',
                          });
                          setState(() => _isChangingCity = true);
                        },
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(context.tr('passport_change_city')),
                  style: FilledButton.styleFrom(backgroundColor: context.appColors.primaryDark),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: isLoading ? null : _onDeactivate,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: AppLoadingWidget.small())
                      : Text(context.tr('passport_return_home')),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Search-first state (not active OR changing city)
    return AppScaffold(
      title: context.tr('passport'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.flight, size: 48, color: context.appColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('passport_explore'),
              style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            CitySearchBar(onCitySelected: _onSearchCitySelected),
            const SizedBox(height: AppSpacing.xl),
            PopularCityGrid(onCitySelected: _onPopularCitySelected),
          ],
        ),
      ),
    );
  }
}
