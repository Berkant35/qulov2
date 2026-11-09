import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

/// Sistem bildirim isteminden önceki açıklama ekranı. `true` = kabul (ardından
/// sistem istemi), `false`/kapatma = şimdi değil.
class PushPermissionSheet extends StatelessWidget {
  const PushPermissionSheet({super.key, this.bodyKey = 'push_prompt_body'});

  /// Açıklama metninin çeviri anahtarı (değerli ana göre).
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Alt sayfa route'u GoRouter'ın değil; core ListBottomSheetWidget gibi
    // Navigator ile kapanır.
    final navigator = Navigator.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 56,
              color: context.appColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr('push_prompt_title'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr(bodyKey),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.tr('push_prompt_accept'),
              onPressed: () => navigator.pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: context.tr('push_prompt_later'),
              variant: AppButtonVariant.text,
              onPressed: () => navigator.pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
