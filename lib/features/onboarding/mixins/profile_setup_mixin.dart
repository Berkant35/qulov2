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

/// Orchestrates gate screen state + photo/magic-fill/quick-assign/manual flows.
/// Setup completion is auto-detected via the router guard reading
/// `userProvider.setupComplete`; provider methods refresh user state on success.
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
      ListBottomSheet<String>(
        name: 'photo_source',
        options: [
          SheetOption(
            label: context.tr('setup_photo_picker_camera'),
            icon: Icons.camera_alt_outlined,
            value: 'camera',
          ),
          SheetOption(
            label: context.tr('setup_photo_picker_gallery'),
            icon: Icons.photo_library_outlined,
            value: 'gallery',
          ),
        ],
      ),
    );

    if (source == null || !mounted) return;
    setState(() => isUploadingPhoto = true);

    try {
      final picker = ref.read(imagePickerManagerProvider);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      final picked = source == 'camera'
          // ignore: use_build_context_synchronously
          ? await picker.pickAndCropFromCamera(context)
          // ignore: use_build_context_synchronously
          : await picker.pickAndCropFromGallery(context);
      if (picked == null) {
        if (mounted) setState(() => isUploadingPhoto = false);
        return;
      }

      // Setup gate uses replace semantics: capture how many photos existed
      // BEFORE the upload so we can drop them after the new one lands.
      // Backend POST /photos appends, so without this every tap added a new
      // photo instead of replacing — confusing the "change photo" intent.
      final preCount =
          ref.read(userProvider).valueOrNull?.photos?.length ?? 0;

      final result = await ref
          .read(userProvider.notifier)
          .uploadPhoto(picked.bytes, picked.mimeType);

      if (!mounted) return;
      await result.when(
        success: (_) async {
          // Delete the previous photos in reverse so indices stay valid.
          // The freshly-uploaded photo sits at index `preCount` and is not
          // touched.
          for (int i = preCount - 1; i >= 0; i--) {
            await ref.read(userProvider.notifier).deletePhoto(i);
          }
          if (!mounted) return;
          AnalyticsManager.instance.logEvent(AnalyticsEvents.setupPhotoSuccess);
          _maybeCompleteSetup();
        },
        failure: (_) async {
          AnalyticsManager.instance.logEvent(AnalyticsEvents.setupPhotoFail);
          if (mounted) _showSnack(context.tr('setup_photo_upload_error'));
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
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
    await _showPreviewSheet();
  }

  Future<void> _showPreviewSheet() async {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null || !mounted) return;

    setState(() => isProcessing = true);
    late final List<Map<String, dynamic>> suggestions;
    try {
      // Prefer the app's active UI locale over user.locale (DB column) — user
      // may have signed up in EN but switched UI to TR; question content should
      // follow what they actually see in the app.
      final appLocale = Localizations.localeOf(context).languageCode;
      final repoResult =
          await ref.read(questionRepositoryProvider).getAiSuggestions({
        'profile_based': true,
        'count': 2,
        'locale': appLocale,
      });
      if (!mounted) return;
      suggestions = repoResult.when<List<Map<String, dynamic>>>(
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
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }

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
          onAssign: (edited) async {
            Navigator.of(ctx).pop();
            await _assignSuggestions(edited);
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

  Future<void> _assignSuggestions(List<Map<String, dynamic>> edited) async {
    if (edited.isEmpty || !mounted) return;
    setState(() => isProcessing = true);
    try {
      final notifier = ref.read(questionProvider.notifier);
      final user = ref.read(userProvider).valueOrNull;
      final start = (user?.questionCount ?? 0) + 1;
      // Match the locale used at suggestion fetch time (app UI locale).
      final locale = Localizations.localeOf(context).languageCode;

      for (int i = 0; i < edited.length; i++) {
        final s = edited[i];
        final answers = (s['answers'] as List?) ?? const [];
        if (answers.length < 4) continue;
        // Server validator rejects explicit null on optional fields — omit if null
        final body = <String, dynamic>{
          'order_num': start + i,
          'question_text': s['question_text'],
          'answer_1': answers[0],
          'answer_2': answers[1],
          'answer_3': answers[2],
          'answer_4': answers[3],
          'correct_answer': s['correct_answer'],
          'locale': locale,
          'time_limit': 30,
        };
        if (s['hint'] != null) body['hint_text'] = s['hint'];
        if (s['category'] != null) body['category'] = s['category'];
        await notifier.createQuestion(body);
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

  /// User-initiated finish from the gate's footer CTA (only shown when
  /// `setupComplete == true`). Explicit navigation since router refresh
  /// is driven by auth state, not userProvider mutations.
  void handleFinish() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.setupComplete);
    ref.read(navigationServiceProvider).go(RouteNames.discover);
  }

  // ─── Back Confirmation ────────────────────────────────────────────

  Future<bool> handleBackAttempt() async {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.setupExitAttempt);
    final shouldLogout =
        await ref.read(navigationServiceProvider).showAppDialog<bool>(
              ConfirmDialog(
                name: 'setup_exit_confirm',
                title: context.tr('setup_exit_confirm_title'),
                message: context.tr('setup_exit_confirm_body'),
                confirmText: context.tr('setup_exit_confirm_logout'),
                cancelText: context.tr('setup_exit_confirm_stay'),
                isDestructive: true,
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
