import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/onboarding/widgets/setup_ai_preview_sheet.dart';
import 'package:qulo_v2/features/onboarding/widgets/setup_brief_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// ProfileSetupMixin — orchestrates the gate screen state and async operations.
///
/// Owns:
/// - UI flags (`isProcessing`, `isUploadingPhoto`)
/// - Photo upload flow (action sheet -> ImagePickerManager -> upload -> fetchMe)
/// - Magic Fill flow (brief sheet -> setInterests -> AI suggestions -> preview -> batch create)
/// - Quick Assign flow (single tap -> server quick-assign endpoint)
/// - Manual Create flow (push question_create route)
/// - Back-button confirmation dialog (logout path)
/// - Analytics breadcrumbs for every step
///
/// Setup completion is auto-detected via the router guard observing
/// `userProvider`'s `setupComplete` getter — this mixin only needs to ensure
/// fresh user state after each successful action (handled by provider methods).
mixin ProfileSetupMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool isProcessing = false;
  bool isUploadingPhoto = false;
  List<Map<String, dynamic>> _previewSuggestions = const [];

  void initMixin() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.setupGateView);
  }

  // ─── Photo Flow ───────────────────────────────────────────────────

  Future<void> handlePhotoTap() async {
    if (isProcessing || isUploadingPhoto) return;
    AnalyticsManager.instance.logEvent(AnalyticsEvents.setupPhotoStart);

    final navigation = ref.read(navigationServiceProvider);
    final source = await navigation.showAppBottomSheet<String>(
      CustomBottomSheet(
        name: 'photo_source',
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(ctx.tr('setup_photo_picker_camera')),
                onTap: () => Navigator.of(ctx).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(ctx.tr('setup_photo_picker_gallery')),
                onTap: () => Navigator.of(ctx).pop('gallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;
    setState(() => isUploadingPhoto = true);

    try {
      final picker = ref.read(imagePickerManagerProvider);
      final picked = source == 'camera'
          ? await picker.pickFromCamera()
          : await picker.pickFromGallery();
      if (picked == null) {
        if (mounted) setState(() => isUploadingPhoto = false);
        return;
      }

      final result = await ref
          .read(userProvider.notifier)
          .uploadPhoto(picked.bytes, picked.mimeType);

      if (!mounted) return;
      result.when(
        success: (_) {
          AnalyticsManager.instance.logEvent(AnalyticsEvents.setupPhotoSuccess);
          _maybeCompleteSetup();
        },
        failure: (_) {
          AnalyticsManager.instance.logEvent(AnalyticsEvents.setupPhotoFail);
          _showSnack(context.tr('setup_photo_upload_error'));
        },
      );
    } catch (_) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.setupPhotoFail);
      if (mounted) _showSnack(context.tr('setup_photo_upload_error'));
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

  // ─── Magic Fill Flow ──────────────────────────────────────────────

  Future<void> handleMagicFill() async {
    if (isProcessing) return;
    AnalyticsManager.instance.logEvent(AnalyticsEvents.setupMagicFillStart);

    final navigation = ref.read(navigationServiceProvider);
    await navigation.showAppBottomSheet<void>(
      CustomBottomSheet(
        name: 'setup_brief',
        maxHeightFactor: 0.85,
        builder: (ctx) => SetupBriefSheet(
          onGenerate: (interests) async {
            Navigator.of(ctx).pop();
            await _afterInterests(interests);
          },
          onSkip: () async {
            Navigator.of(ctx).pop();
            AnalyticsManager.instance.logEvent(AnalyticsEvents.setupMagicFillSkip);
            await _afterInterests(const []);
          },
        ),
      ),
    );
  }

  Future<void> _afterInterests(List<String> interests) async {
    if (!mounted) return;
    setState(() => isProcessing = true);
    try {
      if (interests.isNotEmpty) {
        final result =
            await ref.read(userProvider.notifier).setInterests(interests);
        if (!mounted) return;
        if (result.isFailure) {
          _showSnack(context.tr('preview_sheet_error'));
          return;
        }
      }
      await _showPreviewSheet();
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> _showPreviewSheet() async {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null || !mounted) return;

    final repoResult =
        await ref.read(questionRepositoryProvider).getAiSuggestions({
      'profile_based': true,
      'count': 2,
      'locale': user.locale ?? 'tr',
    });

    if (!mounted) return;

    final suggestions = repoResult.when<List<Map<String, dynamic>>>(
      success: (data) {
        final list = data['suggestions'];
        if (list is List) {
          return list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const [];
      },
      failure: (_) => const [],
    );

    if (suggestions.isEmpty) {
      _showSnack(context.tr('preview_sheet_error'));
      return;
    }

    _previewSuggestions = suggestions;
    final navigation = ref.read(navigationServiceProvider);
    await navigation.showAppBottomSheet<void>(
      CustomBottomSheet(
        name: 'setup_ai_preview',
        maxHeightFactor: 0.85,
        builder: (ctx) => SetupAiPreviewSheet(
          suggestions: _previewSuggestions,
          isProcessing: isProcessing,
          onAssign: () async {
            Navigator.of(ctx).pop();
            await _assignSuggestions();
          },
          onRegenerate: () async {
            Navigator.of(ctx).pop();
            AnalyticsManager.instance
                .logEvent(AnalyticsEvents.setupMagicFillRegen);
            await _showPreviewSheet();
          },
          onSkip: () async {
            Navigator.of(ctx).pop();
            await handleQuickAssign();
          },
        ),
      ),
    );
  }

  Future<void> _assignSuggestions() async {
    if (_previewSuggestions.isEmpty || !mounted) return;
    setState(() => isProcessing = true);
    try {
      final notifier = ref.read(questionProvider.notifier);
      final user = ref.read(userProvider).valueOrNull;
      final start = (user?.questionCount ?? 0) + 1;
      final locale = user?.locale ?? 'tr';

      for (int i = 0; i < _previewSuggestions.length; i++) {
        final s = _previewSuggestions[i];
        final answers = (s['answers'] as List?) ?? const [];
        if (answers.length < 4) continue;
        await notifier.createQuestion({
          'order_num': start + i,
          'question_text': s['question_text'],
          'answer_1': answers[0],
          'answer_2': answers[1],
          'answer_3': answers[2],
          'answer_4': answers[3],
          'correct_answer': s['correct_answer'],
          'hint_text': s['hint'],
          'category': s['category'],
          'locale': locale,
          'time_limit': 30,
        });
      }
      AnalyticsManager.instance.logEvent(AnalyticsEvents.setupMagicFillAssign);
      _maybeCompleteSetup();
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  // ─── Quick Assign Flow ────────────────────────────────────────────

  Future<void> handleQuickAssign() async {
    if (isProcessing || !mounted) return;
    AnalyticsManager.instance.logEvent(AnalyticsEvents.setupQuickAssign);
    setState(() => isProcessing = true);

    try {
      final result =
          await ref.read(userProvider.notifier).quickAssignQuestions();
      if (!mounted) return;
      result.when(
        success: (_) => _maybeCompleteSetup(),
        failure: (_) => _showSnack(context.tr('setup_quick_assign_error')),
      );
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  // ─── Manual Create Flow ───────────────────────────────────────────

  void handleManualCreate() {
    if (isProcessing) return;
    AnalyticsManager.instance.logEvent(AnalyticsEvents.setupManualCreate);
    ref.read(navigationServiceProvider).push(RouteNames.questionCreate);
  }

  // ─── Setup Completion Detection ───────────────────────────────────

  void _maybeCompleteSetup() {
    final user = ref.read(userProvider).valueOrNull;
    if (user?.setupComplete ?? false) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.setupComplete);
      // Router guard re-evaluates redirect when userProvider state changes.
    }
  }

  // ─── Back Confirmation ────────────────────────────────────────────

  Future<bool> handleBackAttempt() async {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.setupExitAttempt);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('setup_exit_confirm_title')),
        content: Text(ctx.tr('setup_exit_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('setup_exit_confirm_stay')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('setup_exit_confirm_logout')),
          ),
        ],
      ),
    );

    if (shouldLogout ?? false) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.setupExitConfirm);
      await ref.read(authProvider.notifier).logout();
      return true;
    }
    return false;
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
