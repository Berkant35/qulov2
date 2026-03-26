import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
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
  // New props
  final String? referredBy;
  final String? referralStatus;
  final ValueChanged<String>? onApplyCode;
  final bool applyingCode;
  final String? applyError;
  final String? applySuccessName;
  final String? initialCode;

  const ReferralInviteCard({
    super.key,
    this.code,
    this.stats,
    this.compact = false,
    this.onShare,
    this.onTap,
    this.referredBy,
    this.referralStatus,
    this.onApplyCode,
    this.applyingCode = false,
    this.applyError,
    this.applySuccessName,
    this.initialCode,
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
      referredBy: referredBy,
      referralStatus: referralStatus,
      onApplyCode: onApplyCode,
      applyingCode: applyingCode,
      applyError: applyError,
      applySuccessName: applySuccessName,
      initialCode: initialCode,
    );
  }
}

class _CompactCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _CompactCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.cardPadding,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryDark.withValues(alpha: 0.5),
              colors.primary.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // Diamond with smoke/glow effect
            SizedBox(
              width: 40,
              height: 40,
              child: const DiamondIcon.purple(size: 28, showGlow: true),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('referral_compact_cta'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('referral_compact_subtitle'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Animated arrow indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.2),
              ),
              child: QIcon(
                QIcons.icChevronRight,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
            ),
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
  final String? referredBy;
  final String? referralStatus;
  final ValueChanged<String>? onApplyCode;
  final bool applyingCode;
  final String? applyError;
  final String? applySuccessName;
  final String? initialCode;

  const _FullCard({
    this.code,
    this.stats,
    this.onShare,
    this.referredBy,
    this.referralStatus,
    this.onApplyCode,
    this.applyingCode = false,
    this.applyError,
    this.applySuccessName,
    this.initialCode,
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
            context.appColors.primary.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.3),
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
                    color: context.appColors.primary,
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
                      backgroundColor: context.appColors.primary,
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
                  color: context.appColors.primary,
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
              valueColor: AlwaysStoppedAnimation<Color>(context.appColors.primary),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Referred-by or Apply-code section
          if (referredBy != null)
            _ReferredBySection(
              referredBy: referredBy!,
              referralStatus: referralStatus,
            )
          else if (onApplyCode != null)
            _ApplyCodeSection(
              onApplyCode: onApplyCode!,
              isLoading: applyingCode,
              errorText: applyError,
              successName: applySuccessName,
              initialCode: initialCode,
            ),
        ],
      ),
    );
  }
}

class _ReferredBySection extends StatelessWidget {
  final String referredBy;
  final String? referralStatus;

  const _ReferredBySection({
    required this.referredBy,
    this.referralStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = referralStatus == 'completed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: context.appColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${context.tr('referral_invited_by')}$referredBy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isCompleted
                ? context.tr('referral_reward_earned')
                : context.tr('referral_complete_profile'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCompleted
                  ? context.appColors.success
                  : Colors.amber.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyCodeSection extends StatefulWidget {
  final ValueChanged<String> onApplyCode;
  final bool isLoading;
  final String? errorText;
  final String? successName;
  final String? initialCode;

  const _ApplyCodeSection({
    required this.onApplyCode,
    this.isLoading = false,
    this.errorText,
    this.successName,
    this.initialCode,
  });

  @override
  State<_ApplyCodeSection> createState() => _ApplyCodeSectionState();
}

class _ApplyCodeSectionState extends State<_ApplyCodeSection> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _controller.text = widget.initialCode!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('referral_enter_code'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: context.tr('referral_code_hint'),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.card_giftcard_outlined,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  errorText: widget.errorText,
                  errorStyle: TextStyle(color: context.appColors.error),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: widget.isLoading
                    ? null
                    : () {
                        final code = _controller.text.trim();
                        if (code.isNotEmpty) {
                          widget.onApplyCode(code);
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: context.appColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                child: widget.isLoading
                    ? const AppLoadingWidget.small()
                    : Text(context.tr('referral_apply')),
              ),
            ),
          ],
        ),
        if (widget.successName != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${context.tr('referral_code_valid')}${widget.successName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appColors.success,
            ),
          ),
        ],
      ],
    );
  }
}
