import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';
import 'package:qulo_v2/features/chat/mixins/matches_screen_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/match_card.dart';
import 'package:qulo_v2/features/chat/widgets/matches_empty_view.dart';
import 'package:qulo_v2/features/chat/widgets/new_matches_strip.dart';
import 'package:qulo_v2/features/email_verification/widgets/email_verify_banner.dart';
import 'package:qulo_v2/providers/match_provider.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> with MatchesScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchListProvider);

    return AppScaffold(
      title: context.tr('matches'),
      padding: EdgeInsets.zero,
      isLoading: matchesAsync is AsyncLoading,
      body: matchesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => ErrorRetryWidget(onRetry: refresh),
        data: (matches) {
          if (matches.isEmpty) return MatchesEmptyView(onRefresh: refresh);

          final newMatches = newMatchesOf(matches);
          final sortedMatches = sortedByActivity(matches);

          return RefreshIndicator(
            onRefresh: refresh,
            child: CustomScrollView(
              slivers: [
                // Doğrulanmamış e-posta: mesaj kapısı burada hatırlatılır.
                const SliverToBoxAdapter(child: EmailVerifyBanner()),
                if (newMatches.isNotEmpty)
                  SliverToBoxAdapter(
                    child: NewMatchesStrip(matches: newMatches, onTap: navigateToChat),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final m = sortedMatches[index];
                      return MatchCard(
                        match: m,
                        onTap: () => navigateToChat(m),
                        onLongPress: () => navigateToProfile(m),
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
}
