import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

/// "Hediye kartlarım" listesinin sonu: sonraki sayfa yüklenirken küçük yükleyici, istek başarısızsa
/// satır içi hata + "Yeniden dene" (kaydırma kendiliğinden tekrar denemez).
class RedemptionsListFooter extends StatelessWidget {
  const RedemptionsListFooter({super.key, required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!failed) return const Center(child: AppLoadingWidget.small());
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('redemptions_load_failed'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(onPressed: onRetry, child: Text(context.tr('retry'))),
      ],
    );
  }
}
