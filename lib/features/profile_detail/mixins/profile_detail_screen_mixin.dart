import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';
import 'package:qulo_v2/features/profile_detail/screens/profile_detail_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

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
    final nav = ref.read(navigationServiceProvider);
    nav.pop();
    nav.push(
      RouteNames.quiz,
      params: {'targetId': widget.userId},
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
    final nav = ref.read(navigationServiceProvider);
    final controller = TextEditingController();

    nav.showAppDialog(
      CustomDialog(
        name: 'report_user',
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('report')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: context.tr('report_reason_hint')),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => nav.closeOverlay(),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                nav.closeOverlay();
                final reason = controller.text.trim();
                if (reason.isNotEmpty) {
                  AnalyticsManager.instance.logEvent(
                    AnalyticsEvents.profileDetailReport,
                    params: {AnalyticsEvents.paramTargetUserId: widget.userId},
                  );
                  await ref.read(reportRepositoryProvider).createReport(
                    reportedId: widget.userId,
                    reason: reason,
                  );
                }
                controller.dispose();
              },
              child: Text(context.tr('report')),
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
