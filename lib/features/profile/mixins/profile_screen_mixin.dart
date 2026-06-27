import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/discover/widgets/acquisition_sheet.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/profile/screens/profile_screen.dart';

mixin ProfileScreenMixin on ConsumerState<ProfileScreen> {
  bool _acqTried = false;

  void initMixin() {
    Future.microtask(() {
      ref.read(userProvider.notifier).fetchMe();
      final exchangeState = ref.read(exchangeProvider);
      if (exchangeState.rates == null) {
        ref.read(exchangeProvider.notifier).fetchAll();
      }
    });
    // "Bizi nereden duydunuz?" anketi: kullanıcı (yeni ya da mevcut) profile'a
    // gelince, henüz cevaplamadıysa tek seferlik sorulur. Discover yerine burada
    // gösterilir (discover'da coach-mark/sayfa mesajı çakışması olabiliyor).
    // fetchMe asenkron olduğu için user yüklendiğinde tetiklemek üzere dinlenir.
    ref.listenManual(userProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user == null || user.acquisitionAnswered) return;
      _maybeOpenAcquisition();
    }, fireImmediately: true);
    AnalyticsManager.instance.logEvent(AnalyticsEvents.profileViewOwn);
  }

  /// Henüz cevaplanmamış anketi tek seferlik açar. Başka bir overlay
  /// (coach-mark) aktifse o turda açmaz.
  void _maybeOpenAcquisition() {
    if (_acqTried) return;
    if (CoachMarkService.instance.isTourActive) return;
    _acqTried = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(navigationServiceProvider).showAppBottomSheet<void>(
            CustomBottomSheet(
              name: 'acquisition',
              isDismissible: false,
              enableDrag: false,
              maxHeightFactor: 0.85,
              builder: (_) => const AcquisitionSheet(),
            ),
          );
    });
  }

  void disposeMixin() {
    // Reserved for future cleanup
  }

  // ─── Label Helpers ───

  String genderPrefLabel(BuildContext context, String? pref) {
    return switch (pref) {
      'MAN' => context.tr('men'),
      'WOMAN' => context.tr('women'),
      'BOTH' => context.tr('both'),
      _ => '',
    };
  }

  String relationshipGoalLabel(BuildContext context, String? goal) {
    return switch (goal) {
      'SERIOUS' => context.tr('serious_relationship'),
      'FRIENDSHIP' => context.tr('friendship'),
      _ => context.tr('not_sure'),
    };
  }

  String languageFlag(String code) {
    return switch (code) {
      'tr' => 'TR',
      'en' => 'EN',
      'de' => 'DE',
      'fr' => 'FR',
      'ar' => 'AR',
      'ru' => 'RU',
      'es' => 'ES',
      _ => code.toUpperCase(),
    };
  }

  // ─── Callbacks ───

  void navigateTo(String route) {
    ref.read(navigationServiceProvider).go(route);
  }

  void pushTo(String route) {
    ref.read(navigationServiceProvider).push(route);
  }

  void openPerformance() {
    navigateTo(RouteNames.performance);
  }

  void openSettings() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.profileSettingsOpen);
    navigateTo(RouteNames.settings);
  }

  void onPreviewProfile() {
    ref.read(navigationServiceProvider).push(
      RouteNames.profilePreview,
      extra: 'profile_screen',
    );
  }

  Future<void> handleClaimReward(String level) async {
    final result = await ref.read(userProvider.notifier).claimBadgeReward(level);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('badge_reward_claimed'))),
        );
      },
      failure: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('badge_claim_failed'))),
        );
      },
    );
  }
}
