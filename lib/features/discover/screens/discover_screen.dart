import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';
import 'package:qulo_v2/core/widgets/question_gate_banner.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/features/discover/mixins/discover_screen_mixin.dart';
import 'package:qulo_v2/features/discover/widgets/discover_card_view.dart';
import 'package:qulo_v2/features/discover/widgets/discover_empty_state.dart';
import 'package:qulo_v2/features/discover/widgets/discover_location_error.dart';
import 'package:qulo_v2/features/discover/widgets/passport_badge.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_host.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with DiscoverScreenMixin {
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
    final discoverState = ref.watch(discoverProvider);
    final locationState = ref.watch(locationProvider);
    final isInitialLoad = locationState.lat == null && locationState.error == null;

    return AppScaffold(
      title: context.tr('discover'),
      padding: EdgeInsets.zero,
      isLoading: discoverState is AsyncLoading || locationState.isLoading || isInitialLoad || (discoverState.valueOrNull?.isPrefetching == true && (discoverState.valueOrNull?.cards.isEmpty ?? false)),
      actions: const [PassportBadge()],
      body: (locationState.isLoading || isInitialLoad)
          ? const SizedBox.shrink()
          : locationState.error != null
              ? DiscoverLocationError(error: locationState.error!)
              : discoverState.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => ErrorRetryWidget(
                onRetry: () => ref.read(discoverProvider.notifier).loadCards(),
              ),
              data: (discover) {
                if (locationState.error != null) {
                  return DiscoverLocationError(error: locationState.error!);
                }

                if (!discover.initialized) return const SizedBox.shrink();

                if (discover.cards.isEmpty) {
                  if (discover.isPrefetching) {
                    return const SizedBox.shrink();
                  }
                  onCardsEmpty();
                  return const DiscoverEmptyState();
                }

                final user = ref.watch(userProvider).valueOrNull;
                final hasMinQuestions = (user?.questionCount ?? 0) >= AppConstants.minQuestions;

                return Column(
                  children: [
                    const PageMessageHost(page: 'discover'),
                    if (!hasMinQuestions)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pagePadding, AppSpacing.sm, AppSpacing.pagePadding, 0,
                        ),
                        child: QuestionGateBanner(
                          questionCount: user?.questionCount ?? 0,
                          profileCompletion: user?.profileCompletion ?? 0,
                          onAddQuestions: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                        ),
                      ),
                    Expanded(
                      child: DiscoverCardView(
                        card: discover.cards.first,
                        onSwipeRight: () => onSwipeRight(discover.cards.first.userId),
                        onSwipeLeft: () => onSwipeLeft(discover.cards.first.userId),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
