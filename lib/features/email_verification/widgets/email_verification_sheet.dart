import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/features/email_verification/mixins/email_verification_sheet_mixin.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// "Mesaj atmak için e-postanı doğrula" sayfası. Adres gösterilir; tekrar
/// gönder, "Doğruladım" (profil tazelenir) ve şimdi değil.
class EmailVerificationSheet extends ConsumerStatefulWidget {
  const EmailVerificationSheet({super.key, required this.trigger});

  /// GA4 `trigger` (bkz. `EmailVerifyTrigger`).
  final String trigger;

  @override
  ConsumerState<EmailVerificationSheet> createState() => _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends ConsumerState<EmailVerificationSheet>
    with EmailVerificationSheetMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(userProvider.select((u) => u.valueOrNull?.email)) ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 56, color: context.appColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr('email_verify_title'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('email_verify_body'),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                email,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
            if (noticeKey != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr(noticeKey!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: noticeIsError ? context.appColors.error : context.appColors.success,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.tr('email_verify_done'),
              isLoading: isChecking,
              onPressed: isBusy ? null : confirm,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: context.tr('email_verify_resend'),
              variant: AppButtonVariant.secondary,
              isLoading: isResending,
              onPressed: isBusy ? null : resend,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: context.tr('email_verify_later'),
              variant: AppButtonVariant.text,
              onPressed: later,
            ),
          ],
        ),
      ),
    );
  }
}
