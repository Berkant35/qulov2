import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class ProfileReportButton extends ConsumerWidget {
  final String userId;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  const ProfileReportButton({
    super.key,
    required this.userId,
    this.onReport,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton(
        onPressed: () => _showSheet(context),
        child: Text(
          context.tr('report_or_block'),
          style: TextStyle(
            color: context.appColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Report option
            ListTile(
              leading: Icon(
                Icons.flag_outlined,
                color: context.appColors.warning,
              ),
              title: Text(
                context.tr('report'),
                style: TextStyle(color: context.appColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                onReport?.call();
              },
            ),
            // Block option
            ListTile(
              leading: Icon(
                Icons.block,
                color: context.appColors.error,
              ),
              title: Text(
                context.tr('block'),
                style: TextStyle(color: context.appColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                onBlock?.call();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
