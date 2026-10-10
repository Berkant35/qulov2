import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/identity/mixins/identity_prompt_banner_mixin.dart';
import 'package:qulo_v2/providers/identity_provider.dart';

/// Profil ekranında etiket eklemeye davet eden küçük, kapatılabilir not. Keşfi/onboarding'i
/// engellemez; kimlik yüklenmediyse, doluysa ya da kapatıldıysa hiçbir şey çizmez.
class IdentityPromptBanner extends ConsumerStatefulWidget {
  const IdentityPromptBanner({super.key});

  @override
  ConsumerState<IdentityPromptBanner> createState() => _IdentityPromptBannerState();
}

class _IdentityPromptBannerState extends ConsumerState<IdentityPromptBanner>
    with IdentityPromptBannerMixin {
  @override
  void initState() {
    super.initState();
    initBanner();
  }

  @override
  Widget build(BuildContext context) {
    // Kapatmış kullanıcı için kimlik GET'i hiç tetiklenmez (watch'tan önce çık).
    if (dismissed) return const SizedBox.shrink();
    final identity = ref.watch(identityProvider).valueOrNull;
    if (identity == null || !identity.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.appColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.badge_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(context.tr('identity_banner_text'), style: theme.textTheme.bodySmall),
            ),
            TextButton(onPressed: add, child: Text(context.tr('identity_banner_add'))),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: context.tr('identity_banner_dismiss'),
              onPressed: dismiss,
            ),
          ],
        ),
      ),
    );
  }
}
