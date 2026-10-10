import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/email_verification/email_verification_controller.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Eşleşmeler ekranındaki nazik hatırlatma: e-posta doğrulanmamışsa görünür,
/// dokununca doğrulama sayfası açılır. Keşfet'i kalabalıklaştırmamak için
/// yalnız mesajlaşmanın başladığı yerde.
class EmailVerifyBanner extends ConsumerWidget {
  const EmailVerifyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verified = ref.watch(userProvider.select((u) => u.valueOrNull?.emailVerified));
    // Profil yüklenmemişken (null) gösterilmez — yanlış alarm olmasın.
    if (verified != false) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding, AppSpacing.sm, AppSpacing.pagePadding, AppSpacing.sm,
      ),
      child: Material(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => ref
              .read(emailVerificationControllerProvider)
              .prompt(trigger: EmailVerifyTrigger.banner),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.mark_email_unread_outlined, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('email_verify_title'),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        context.tr('email_verify_banner_body'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
