import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/one_time_flag_store.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/features/notifications/mixins/push_permission_offer_mixin.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/profile/screens/questions_screen.dart';
import 'package:qulo_v2/features/profile/widgets/question_celebration_dialog.dart';

mixin QuestionsScreenMixin on ConsumerState<QuestionsScreen>, PushPermissionOfferMixin<QuestionsScreen> {
  int previousCount = 0;
  bool initialized = false;
  static const keyCelebrationShown = 'celebration_shown';

  void initMixin() {
    Future.microtask(() {
      ref.read(questionProvider.notifier).fetchQuestions();
      final questions = ref.read(questionProvider).valueOrNull ?? [];
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.questionListView,
        params: {
          AnalyticsEvents.paramQuestionsCount: questions.length,
        },
      );
    });
  }

  void checkCelebration(List<QuestionModel> questions) async {
    final count = questions.length;
    if (initialized &&
        previousCount < AppConstants.minQuestions &&
        count >= AppConstants.minQuestions) {
      if (await OneTimeFlagStore.markIfUnset(keyCelebrationShown)) {
        if (mounted) unawaited(showCelebrationDialog());
      }
    }
    previousCount = count;
    initialized = true;
  }

  /// `ReorderableListView.onReorder` — build'den mixin'e tasindi (CLAUDE.md
  /// "Widget Logic -> Mixin"). Sunucu siralamayi reddederse liste eski haline
  /// doner; eskiden bu sessizdi, artik kullaniciya soyleniyor.
  ///
  /// Mesaj await ONCESI aliniyor; sonrasinda `State.context` yalnizca `mounted`
  /// kontroluyle kullaniliyor.
  Future<void> onReorderQuestions(int oldIndex, int newIndex) async {
    HapticFeedback.mediumImpact();
    final message = context.tr('error_try_again');
    final ok = await ref
        .read(questionProvider.notifier)
        .reorderQuestions(oldIndex, newIndex);
    if (ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void openAnalytics() {
    ref.read(navigationServiceProvider).push(RouteNames.questionAnalytics);
  }

  void showModeSheet() {
    final questions = ref.read(questionProvider).valueOrNull ?? [];
    final dailyStats = ref.read(dailyStatsProvider).valueOrNull;
    final questionsLimit = dailyStats?.questionsLimit ?? 4;
    if (questions.length >= questionsLimit) {
      PaywallBottomSheetContent.show(ref, trigger: 'question_limit');
      return;
    }

    final nav = ref.read(navigationServiceProvider);
    nav.showAppBottomSheet(
      ListBottomSheet<String>(
        name: 'question_mode_select',
        title: context.tr('question_mode_title'),
        options: [
          SheetOption(
            icon: Icons.auto_awesome,
            label: context.tr('question_create_easy_mode'),
            value: 'easy',
          ),
          SheetOption(
            icon: Icons.edit_note,
            label: context.tr('question_create_advanced_mode'),
            value: 'advanced',
          ),
        ],
      ),
    ).then((value) {
      if (value == null) return;
      if (value == 'easy') {
        nav.push(RouteNames.questionEasyMode);
      } else {
        nav.push(RouteNames.questionCreate);
      }
    });
  }

  void editQuestion(QuestionModel question) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.questionEdit,
      params: {
        AnalyticsEvents.paramQuestionId: question.id,
      },
    );
    ref.read(navigationServiceProvider).push(
      RouteNames.questionCreate,
      extra: question,
    );
  }

  /// Onaylanan silme, dialog açıkken ekran kapansa da sunucuya gider:
  /// notifier await ÖNCESİ alınır (`ref` sonra kullanılamaz).
  Future<void> deleteQuestion(QuestionModel question) async {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.questionDelete,
      params: {
        AnalyticsEvents.paramQuestionId: question.id,
      },
    );
    final questions = ref.read(questionProvider.notifier);
    final confirmed = await ref.read(navigationServiceProvider).showAppDialog<bool>(
      ConfirmDialog(
        name: 'delete_question',
        title: context.tr('delete'),
        message: question.questionText,
        confirmText: context.tr('delete'),
        isDestructive: true,
      ),
    );
    if (confirmed == true) await questions.deleteQuestion(question.orderNum);
  }

  /// Dialog ekranın değil kendi bağlamıyla çizilir ve servisi önceden yakalar:
  /// açıkken ekran kapanırsa da düğme çalışır.
  ///
  /// Kapanınca bildirim izni açıklaması (uygunsa, ömür boyu bir kez —
  /// `PushPromptStore`), sonra "Keşfet'e git" seçildiyse Keşfet. Açıklama soru
  /// ekranında açılır; Keşfet'e geçişten sonra açılsa kartların üstüne binerdi.
  Future<void> showCelebrationDialog() async {
    final nav = ref.read(navigationServiceProvider);
    final goDiscover = await nav.showAppDialog<bool>(
      CustomDialog(
        name: 'question_celebration',
        builder: (_) => QuestionCelebrationDialog(
          onGoDiscover: () => nav.closeOverlay(true),
        ),
      ),
    );
    if (mounted) await offerPushPermission(trigger: PushPromptTrigger.questionCelebration);
    if (goDiscover == true) nav.go(RouteNames.discover);
  }

  String difficultyLabel(QuestionModel q) {
    final total = q.statsCorrect + q.statsWrong;
    if (total < 10) return context.tr('analytics_difficulty_unranked');
    final rate = q.statsCorrect / total;
    if (rate >= 0.8) return context.tr('analytics_difficulty_easy');
    if (rate >= 0.5) return context.tr('analytics_difficulty_medium');
    if (rate >= 0.2) return context.tr('analytics_difficulty_hard');
    return context.tr('analytics_difficulty_legendary');
  }

  Color difficultyColor(QuestionModel q) {
    final total = q.statsCorrect + q.statsWrong;
    if (total < 10) return context.appColors.textHint;
    final rate = q.statsCorrect / total;
    if (rate >= 0.8) return context.appColors.secondary;
    if (rate >= 0.5) return context.appColors.info;
    if (rate >= 0.2) return context.appColors.warning;
    return context.appColors.error;
  }
}
