import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/features/chat/widgets/new_match_avatar.dart';
import 'package:qulo_v2/features/chat/widgets/match_card.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logEvent(AnalyticsEvents.matchScreenView);
    Future.microtask(() => ref.read(matchListProvider.notifier).fetchMatches());
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchListProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('matches'),
      padding: EdgeInsets.zero,
      isLoading: matchesAsync is AsyncLoading,
      body: matchesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => ErrorRetryWidget(
          onRetry: () => ref.read(matchListProvider.notifier).fetchMatches(),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(matchListProvider.notifier).fetchMatches(),
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Icon(Icons.favorite_border, size: 64, color: theme.hintColor),
                  const SizedBox(height: AppSpacing.lg),
                  Center(child: Text(context.tr('no_matches'), style: theme.textTheme.titleMedium)),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Text(
                      context.tr('start_swiping'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            );
          }

          // New matches: no messages yet
          final newMatches = matches.where((m) => m.lastMessage == null).toList();

          // All matches sorted by most recent activity
          final sortedMatches = List<MatchModel>.from(matches)
            ..sort((a, b) {
              final aTime = a.lastMessageSentAt ?? a.matchedAt;
              final bTime = b.lastMessageSentAt ?? b.matchedAt;
              return bTime.compareTo(aTime);
            });

          return RefreshIndicator(
            onRefresh: () => ref.read(matchListProvider.notifier).fetchMatches(),
            child: CustomScrollView(
            slivers: [
              // ─── Top Section: New Matches Horizontal Scroll ───
              if (newMatches.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.sm, AppSpacing.pagePadding, AppSpacing.md),
                        child: Text(
                          context.tr('new_matches'),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                          itemCount: newMatches.length,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
                          itemBuilder: (context, index) {
                            final m = newMatches[index];
                            return NewMatchAvatar(
                              match: m,
                              onTap: () => _navigateToChat(m),
                            );
                          },
                        ),
                      ),
                      Divider(color: theme.colorScheme.outline, height: 1),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),

              // ─── Bottom Section: Chat List with Dark Cards ───
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final m = sortedMatches[index];
                    return MatchCard(
                      match: m,
                      onTap: () => _navigateToChat(m),
                    );
                  },
                  childCount: sortedMatches.length,
                ),
              ),
            ],
          ),
          );
        },
      ),
    );
  }

  void _navigateToChat(MatchModel m) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.matchOpenChat,
      params: {AnalyticsEvents.paramMatchUserId: m.user?.userId ?? ''},
    );
    ref.read(navigationServiceProvider).push(
      RouteNames.chat,
      params: {'matchId': m.matchId},
    );
  }
}
