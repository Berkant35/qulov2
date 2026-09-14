import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/onboarding/mixins/profile_setup_mixin.dart';
import 'package:qulo_v2/features/onboarding/widgets/setup_ai_preview_sheet.dart';
import 'package:qulo_v2/features/onboarding/widgets/setup_brief_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Magic-fill flow of the setup gate: interests brief → AI preview → assign.
/// Split out of [ProfileSetupMixin] (SRP / mixin size limit); shares its
/// processing state, snackbar and completion detection.
mixin ProfileSetupMagicFillMixin<T extends ConsumerStatefulWidget>
    on ProfileSetupMixin<T> {
  Future<void> handleMagicFill() async {
    if (isProcessing) return;
    AnalyticsManager.instance.logEvent(AnalyticsEvents.setupMagicFillStart);

    final navigation = ref.read(navigationServiceProvider);
    await navigation.showAppBottomSheet<void>(
      CustomBottomSheet(
        name: 'setup_brief',
        maxHeightFactor: AppBottomSheet.tallHeightFactor,
        builder: (_) => SetupBriefSheet(
          onGenerate: (interests) async {
            navigation.closeOverlay();
            await _afterInterests(interests);
          },
          onSkip: () async {
            navigation.closeOverlay();
            AnalyticsManager.instance.logEvent(
              AnalyticsEvents.setupMagicFillSkip,
            );
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
        final result = await ref
            .read(userProvider.notifier)
            .setInterests(interests);
        if (!mounted) return;
        if (result.isFailure) {
          showSetupSnack(context.tr('preview_sheet_error'));
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
      final repoResult = await ref
          .read(questionRepositoryProvider)
          .getAiSuggestions({
            'profile_based': true,
            'count': AppConstants.minQuestions,
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
      showSetupSnack(context.tr('preview_sheet_error'));
      return;
    }

    final navigation = ref.read(navigationServiceProvider);
    await navigation.showAppBottomSheet<void>(
      CustomBottomSheet(
        name: 'setup_ai_preview',
        maxHeightFactor: AppBottomSheet.tallHeightFactor,
        builder: (_) => SetupAiPreviewSheet(
          suggestions: suggestions,
          onAssign: (edited) async {
            navigation.closeOverlay();
            await _assignSuggestions(edited);
          },
          onRegenerate: () async {
            navigation.closeOverlay();
            AnalyticsManager.instance.logEvent(
              AnalyticsEvents.setupMagicFillRegen,
            );
            await _showPreviewSheet();
          },
          onSkip: () async {
            navigation.closeOverlay();
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
      final user = ref.read(userProvider).valueOrNull;
      final outcome = await ref
          .read(questionProvider.notifier)
          .createFromSuggestions(
            edited,
            startOrder: (user?.questionCount ?? 0) + 1,
            // Match the locale used at suggestion fetch time (app UI locale).
            locale: Localizations.localeOf(context).languageCode,
          );
      if (!mounted) return;
      if (outcome.failed > 0) {
        showSetupSnack(context.tr('question_save_failed'));
      }
      if (outcome.created > 0) {
        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.setupMagicFillAssign,
        );
        maybeCompleteSetup();
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }
}
