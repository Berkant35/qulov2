import 'dart:async';

import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/app_review_manager.dart';
import 'package:qulo_v2/features/notifications/mixins/push_permission_offer_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_state_mixin.dart';
import 'package:qulo_v2/features/quiz/screens/quiz_screen.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Ekrandan cikis, kutlama sonrasi yonlendirme ve bildirim izni.
mixin QuizFlowMixin on QuizScreenStateMixin, PushPermissionOfferMixin<QuizScreen> {
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
    _leaveCelebration(nextRoute: RouteNames.matches);
  }

  // Eslesme olmadan geri donus kotu bir an: ne bildirim izni ne degerlendirme
  // istemi sorulur (2026-09-25'e kadar soruluyordu).
  void onGoBack() {
    if (celebrationMatched) {
      _leaveCelebration(nextRoute: RouteNames.discover);
    } else {
      ref.read(navigationServiceProvider).go(RouteNames.discover);
    }
  }

  // Kutlama cikisinda once bildirim izni aciklamasi (uygunsa, omur boyu bir
  // kez): "biri sorularini cozunce / eslesmen cevap verince haber verelim" en
  // anlamli bu anda. Aciklama acildiysa degerlendirme istemi ust uste binmesin
  // diye Kesfet'e donuse ertelenir (ReturnReviewPromptMixin); acilmadiysa hemen.
  //
  // Ilk eslesme paywall'i (PremiumSuggestionSheet, trigger `first_match`)
  // 2.0.18'de KALDIRILDI: kayittan ~4 dk sonra cikiyordu, Kasim'da 39
  // gosterim / 0 odeme. Teklif ihtiyac aninda: kurtarma ve guc bakiyesi
  // yetersiz (`quiz_rescue` / `quiz_power`), gunluk kesif siniri
  // (`swipe_limit`), donusumde yesil yetersiz (`exchange_convert`).
  Future<void> _leaveCelebration({required String nextRoute}) async {
    final nav = ref.read(navigationServiceProvider);
    final offeredPush = await offerPushPermission(trigger: PushPromptTrigger.match);
    if (!mounted) return;
    nav.go(nextRoute);
    final review = AppReviewManager.instance;
    unawaited(
      offeredPush
          ? review.markPendingReturnReview()
          : review.tryShowReview(trigger: AppReviewTrigger.matchCelebration),
    );
  }
}
