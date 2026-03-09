import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/data/models/match_model.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  @override
  void initState() {
    super.initState();
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
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: theme.hintColor),
                  const SizedBox(height: AppSpacing.lg),
                  Text(context.tr('no_matches'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr('start_swiping'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // ─── Top Section: New Matches Horizontal Scroll ───
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
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
                        itemBuilder: (context, index) {
                          final m = matches[index];
                          final u = m.user;
                          final photo = u?.photos?.isNotEmpty == true ? u!.photos!.first : null;

                          return GestureDetector(
                            onTap: () => ref.read(navigationServiceProvider).go(
                              RouteNames.chat,
                              params: {'matchId': m.matchId},
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: theme.colorScheme.surface,
                                    backgroundImage: photo != null
                                        ? CachedNetworkImageProvider(photo)
                                        : null,
                                    child: photo == null
                                        ? Icon(Icons.person, color: theme.hintColor)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    u?.name ?? '?',
                                    style: theme.textTheme.labelSmall,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
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
                    final m = matches[index];
                    return _MatchCard(
                      match: m,
                      onTap: () => ref.read(navigationServiceProvider).go(
                        RouteNames.chat,
                        params: {'matchId': m.matchId},
                      ),
                    );
                  },
                  childCount: matches.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  const _MatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final u = match.user;
    final photo = u?.photos?.isNotEmpty == true ? u!.photos!.first : null;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              backgroundImage: photo != null ? CachedNetworkImageProvider(photo) : null,
              child: photo == null
                  ? Icon(Icons.person, color: theme.hintColor)
                  : null,
            ),
            if (u?.isOnline == true)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          u?.name ?? context.tr('unknown_user'),
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          u?.city ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: u?.isOnline == true
            ? Text(
                context.tr('online'),
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.secondary),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
