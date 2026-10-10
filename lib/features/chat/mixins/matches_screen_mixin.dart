import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/features/chat/screens/matches_screen.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Eşleşmeler ekranının davranışı: yükleme, sıralama, sohbet/profil geçişleri.
mixin MatchesScreenMixin on ConsumerState<MatchesScreen> {
  void initMixin() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.matchScreenView);
    Future.microtask(refresh);
  }

  Future<void> refresh() => ref.read(matchListProvider.notifier).fetchMatches();

  /// Henüz mesajı olmayan yeni eşleşmeler (üst yatay şerit).
  List<MatchModel> newMatchesOf(List<MatchModel> matches) =>
      matches.where((m) => m.lastMessage == null).toList();

  /// Son etkinliğe göre sıralı tüm eşleşmeler.
  List<MatchModel> sortedByActivity(List<MatchModel> matches) => List<MatchModel>.from(matches)
    ..sort((a, b) {
      final aTime = a.lastMessageSentAt ?? a.matchedAt;
      final bTime = b.lastMessageSentAt ?? b.matchedAt;
      return bTime.compareTo(aTime);
    });

  void navigateToProfile(MatchModel m) {
    final userId = m.user?.userId;
    if (userId == null) return;
    ref.read(navigationServiceProvider).push(
          RouteNames.profileDetail,
          params: {'userId': userId},
          extra: ProfileDetailArgs(
            context: ProfileDetailContext.match,
            userId: userId,
            matchId: m.matchId,
          ),
        );
  }

  void navigateToChat(MatchModel m) {
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
