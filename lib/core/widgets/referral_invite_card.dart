import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/referral_model.dart';

class ReferralInviteCard extends StatelessWidget {
  final String? code;
  final ReferralStats? stats;
  final bool compact;
  final VoidCallback? onShare;
  final VoidCallback? onTap;

  const ReferralInviteCard({
    super.key,
    this.code,
    this.stats,
    this.compact = false,
    this.onShare,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactCard(onTap: onTap);
    }
    return _FullCard(
      code: code,
      stats: stats,
      onShare: onShare,
    );
  }
}

class _CompactCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _CompactCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          gradient: context.appColors.purpleGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const DiamondIcon.purple(size: 28, showGlow: false),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.tr('referral_compact_cta'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            QIcon(QIcons.icChevronRight, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FullCard extends StatelessWidget {
  final String? code;
  final ReferralStats? stats;
  final VoidCallback? onShare;

  const _FullCard({
    this.code,
    this.stats,
    this.onShare,
  });

  void _copyCode(BuildContext context) {
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('referral_code_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final used = stats?.completed ?? 0;
    final total = (stats?.completed ?? 0) + (stats?.remaining ?? 10);
    final progress = total > 0 ? used / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appColors.primaryDark.withValues(alpha: 0.6),
            AppColors.primary.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const DiamondIcon.purple(size: 24, showGlow: false),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.tr('referral_title'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('referral_description'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Code display
          if (code != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  code!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyCode(context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(context.tr('referral_copy')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share, size: 16),
                    label: Text(context.tr('referral_share')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('referral_progress'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                '$used/$total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
