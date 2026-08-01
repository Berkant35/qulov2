import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/app_review_manager.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';
import 'package:qulo_v2/features/onboarding/widgets/premium_suggestion_sheet.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_state_mixin.dart';

/// Ekrandan cikis, kutlama sonrasi yonlendirme ve ilk eslesme paywall'i.
mixin QuizFlowMixin on QuizScreenStateMixin {
  Future<void> confirmExit() async {
    final nav = ref.read(navigationServiceProvider);
    final questionIndex =
        ref.read(quizProvider).currentQuestion?.questionNumber ?? 0;

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizExitAttempt,
      params: {AnalyticsEvents.paramQuestionIndex: questionIndex},
    );
    final confirm = await nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'quiz_exit',
        title: context.tr('quiz_exit_title'),
        message: context.tr('quiz_exit_message'),
        confirmText: context.tr('quiz_exit_confirm'),
        cancelText: context.tr('quiz_exit_cancel'),
        isDestructive: true,
      ),
    );
    if (confirm == true && mounted) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.quizExitConfirm);
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.quizAbandon,
        params: {AnalyticsEvents.paramQuestionIndex: questionIndex},
      );
      nav.go(RouteNames.discover);
    }
  }

  void onStartChat() {
    ref.invalidate(matchListProvider);
    _maybeShowFirstMatchPaywall(nextRoute: RouteNames.matches);
  }

  void onGoBack() {
    if (celebrationMatched) {
      _maybeShowFirstMatchPaywall(nextRoute: RouteNames.discover);
    } else {
      ref.read(navigationServiceProvider).go(RouteNames.discover);
      AppReviewManager.instance.tryShowReview(trigger: 'match_celebration');
    }
  }

  // Ilk eslesme celebration cikisinda paywall'i bir kez goster (onboarding
  // yerine buraya ertelendi — carousel artik auth oncesi). Flag zaten set ise
  // (2. + eslesme) dogrudan yonlendir + mevcut review davranisini koru; ayni
  // turda paywall + review birlikte acilmasin diye review'i sadece bu dalda cagir.
  Future<void> _maybeShowFirstMatchPaywall({required String nextRoute}) async {
    final nav = ref.read(navigationServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown =
        prefs.getBool(AnalyticsEvents.flagPaywallFirstMatch) ?? false;

    if (alreadyShown) {
      nav.go(nextRoute);
      AppReviewManager.instance.tryShowReview(trigger: 'match_celebration');
      return;
    }

    await prefs.setBool(AnalyticsEvents.flagPaywallFirstMatch, true);
    FunnelEvents.logAuthed(
      AnalyticsEvents.paywallShown,
      params: {AnalyticsEvents.paramTrigger: 'first_match'},
    );

    if (!mounted) return;
    nav.showAppBottomSheet(
      CustomBottomSheet(
        name: 'premium_suggestion',
        maxHeightFactor: 0.85,
        builder: (context) => const PremiumSuggestionSheet(),
      ),
    ).then((_) {
      if (mounted) nav.go(nextRoute);
    });
  }
}
