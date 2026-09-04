import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';
import 'package:qulo_v2/features/profile_detail/screens/profile_detail_screen.dart';
import 'package:qulo_v2/features/profile_detail/widgets/report_category_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/profile_detail/providers/profile_detail_provider.dart';
import 'package:qulo_v2/features/quiz/models/quiz_target_args.dart';

mixin ProfileDetailScreenMixin on ConsumerState<ProfileDetailScreen> {
  void initMixin() {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.profileDetailView,
      params: {
        AnalyticsEvents.paramTargetUserId: widget.userId,
        AnalyticsEvents.paramContext: widget.args?.context.name ?? 'unknown',
      },
    );
  }

  void disposeMixin() {}

  // ─── Photo Navigation ───

  void onPhotoChanged(int index, int total) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.profileDetailPhotoNav,
      params: {
        AnalyticsEvents.paramTargetUserId: widget.userId,
        AnalyticsEvents.paramPhotoIndex: index,
        AnalyticsEvents.paramTotalPhotos: total,
      },
    );
  }

  // ─── Action Bar Callbacks ───

  void onSolveQuestions() {
    _logAction('solve');
    _solveQuestionsFlow();
  }

  // Discover'dan gelindiğinde LIKE swipe kaydet — discover_card_view._navigateToQuiz simetrisi.
  // Match/chat/quizResult context'lerinde swipe yok; sadece quiz'e push.
  Future<void> _solveQuestionsFlow() async {
    final nav = ref.read(navigationServiceProvider);

    if (widget.args?.context == ProfileDetailContext.discover) {
      final result = await ref.read(discoverProvider.notifier).swipe(
        targetId: widget.userId,
        action: 'LIKE',
      );
      if (!mounted) return;

      var aborted = false;
      result.when(
        success: (_) {},
        failure: (f) {
          if (f is ServerFailure && f.code == 'DAILY_LIMIT_EXCEEDED') {
            PaywallBottomSheetContent.show(ref, trigger: 'swipe_limit');
            aborted = true;
          }
        },
      );
      if (aborted) return;
    }

    if (!mounted) return;
    // Kimlik TEK kaynaktan: yuklu profil varsa o (mesafesi null olsa bile — bilinmiyor
    // demektir, kartin degeriyle ezilmez), yoksa discover'dan gelen on yuklenmis kart.
    final profile = ref.read(profileDetailProvider(widget.userId)).valueOrNull;
    final card = widget.args?.preloadedCard;
    final target = profile != null
        ? QuizTargetArgs(
            name: profile.name,
            photoUrl: profile.photos.firstOrNull,
            distanceKm: profile.distanceKm,
          )
        : QuizTargetArgs(
            name: card?.name,
            photoUrl: card?.photos?.firstOrNull,
            distanceKm: card?.distanceKm,
          );
    nav.pop();
    nav.push(
      RouteNames.quiz,
      params: {'targetId': widget.userId},
      extra: target,
    );
  }

  void onReject() {
    _logAction('reject');
    ref.read(navigationServiceProvider).pop('reject');
  }

  void onSendMessage() {
    _logAction('message');
    final matchId = widget.args?.matchId;
    if (matchId == null) return;
    final nav = ref.read(navigationServiceProvider);

    // Chat context'inden geldiyse, zaten chat ekranı altta var — sadece pop yeterli
    if (widget.args?.context == ProfileDetailContext.chat) {
      nav.pop();
    } else {
      nav.pop();
      nav.push(RouteNames.chat, params: {'matchId': matchId});
    }
  }

  void onClose() {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.profileDetailClose,
      params: {AnalyticsEvents.paramTargetUserId: widget.userId},
    );
    ref.read(navigationServiceProvider).pop();
  }

  // ─── Report & Block ───

  void onReport() {
    _logAction('report');
    _showReportDialog();
  }

  void onBlock() {
    _logAction('block');
    _showBlockConfirmation();
  }

  void _logAction(String action) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.profileDetailAction,
      params: {
        AnalyticsEvents.paramAction: action,
        AnalyticsEvents.paramTargetUserId: widget.userId,
      },
    );
  }

  // ─── Dialogs ───

  void _showReportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReportCategorySheet(
        onSelected: _showReportReasonDialog,
      ),
    );
  }

  void _showReportReasonDialog(String category) {
    final nav = ref.read(navigationServiceProvider);
    final controller = TextEditingController();
    final isOther = category == 'OTHER';

    nav.showAppDialog(
      CustomDialog(
        name: 'report_reason',
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('report')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: ctx.tr('report_reason_hint'),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          actions: [
            TextButton(
              onPressed: () => nav.closeOverlay(),
              child: Text(ctx.tr('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final reason = controller.text.trim();
                if (isOther && reason.isEmpty) return;
                nav.closeOverlay();
                AnalyticsManager.instance.logEvent(
                  AnalyticsEvents.profileDetailReport,
                  params: {AnalyticsEvents.paramTargetUserId: widget.userId},
                );
                await ref.read(reportRepositoryProvider).createReport(
                  reportedId: widget.userId,
                  category: category,
                  reason: reason.isNotEmpty ? reason : null,
                );
                controller.dispose();
              },
              child: Text(ctx.tr('report')),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmation() {
    final nav = ref.read(navigationServiceProvider);

    nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'block_user',
        title: context.tr('block_user_title'),
        message: context.tr('block_user_message'),
        confirmText: context.tr('block'),
        cancelText: context.tr('cancel'),
        isDestructive: true,
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.profileDetailBlock,
        params: {AnalyticsEvents.paramTargetUserId: widget.userId},
      );
      await ref.read(blockRepositoryProvider).blockUser(widget.userId);
      if (mounted) {
        ref.read(navigationServiceProvider).pop('blocked');
      }
    });
  }
}
