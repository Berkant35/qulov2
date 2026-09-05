import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/passport/mixins/passport_screen_mixin.dart';
import 'package:qulo_v2/features/passport/widgets/city_search_bar.dart';
import 'package:qulo_v2/features/passport/widgets/passport_active_card.dart';
import 'package:qulo_v2/features/passport/widgets/passport_premium_gate.dart';
import 'package:qulo_v2/features/passport/widgets/popular_city_grid.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key});

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen>
    with LoadingMixin, PassportScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passport = ref.watch(passportProvider);
    final subscription = ref.watch(subscriptionProvider);
    final isPremium = subscription.valueOrNull?.isPremium ?? false;

    if (!isPremium) {
      return AppScaffold(
        title: context.tr('passport'),
        body: const PassportPremiumGate(),
      );
    }

    if (passport.isActive && !isChangingCity) {
      return AppScaffold(
        title: context.tr('passport'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PassportActiveCard(city: passport.city ?? ''),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: isLoading ? null : () => onChangeCity(passport.city),
                icon: const Icon(Icons.swap_horiz),
                label: Text(context.tr('passport_change_city')),
                style: FilledButton.styleFrom(backgroundColor: context.appColors.primaryDark),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: isLoading ? null : () => onDeactivate(withLoading),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: AppLoadingWidget.small())
                    : Text(context.tr('passport_return_home')),
              ),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: context.tr('passport'),
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.flight, size: 48, color: context.appColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('passport_explore'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            CitySearchBar(onCitySelected: onSearchCitySelected),
            const SizedBox(height: AppSpacing.xl),
            PopularCityGrid(onCitySelected: onPopularCitySelected),
          ],
        ),
      ),
    );
  }
}
