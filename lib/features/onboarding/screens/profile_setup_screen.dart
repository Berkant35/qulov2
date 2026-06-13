import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/onboarding/mixins/profile_setup_mixin.dart';
import 'package:qulo_v2/features/onboarding/widgets/setup_photo_card.dart';
import 'package:qulo_v2/features/onboarding/widgets/setup_question_card.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// ProfileSetupScreen — gate that forces new users to upload a photo and
/// reach minimum question count (>=2) before they can enter the main app.
///
/// All business logic lives in [ProfileSetupMixin] — this widget is a thin
/// orchestrator that wires user state to the two setup cards.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with ProfileSetupMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider).valueOrNull;
    final hasPhoto = user?.photos?.isNotEmpty ?? false;
    final questionsReady = (user?.questionCount ?? 0) >= 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await handleBackAttempt();
      },
      child: AppScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('setup_title'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('setup_subtitle'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SetupPhotoCard(
              isComplete: hasPhoto,
              isUploading: isUploadingPhoto,
              onTap: handlePhotoTap,
            ),
            const SizedBox(height: AppSpacing.md),
            SetupQuestionCard(
              isComplete: questionsReady,
              isProcessing: isProcessing,
              onMagicFill: handleMagicFill,
              onQuickAssign: handleQuickAssign,
              onManualCreate: handleManualCreate,
              onEdit: () => ref
                  .read(navigationServiceProvider)
                  .push(RouteNames.questions),
            ),
            const Spacer(),
            Center(
              child: Text(
                context.tr('setup_hint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
