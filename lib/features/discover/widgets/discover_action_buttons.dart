import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/circle_icon_button.dart';
import 'package:qulo_v2/core/widgets/locked_feature_button.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/features/discover/mixins/discover_action_buttons_mixin.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';

/// Keşfet kartının altındaki geri al (ücretli hak, kalan sayı altında) ve reddet butonları.
class DiscoverActionButtons extends ConsumerWidget with DiscoverActionButtonsMixin {
  final VoidCallback onReject;
  final Future<void> Function() onUndo;
  final bool canUndo;

  const DiscoverActionButtons({
    super.key,
    required this.onReject,
    required this.onUndo,
    required this.canUndo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowance = undoAllowance(ref.watch(dailyStatsProvider).valueOrNull);
    final hasUndoRight = allowance.hasRight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LockedFeatureButton(
              isLocked: !hasUndoRight,
              trigger: 'undo_locked',
              child: SafeTapButton(
                onTap: canUndo ? onUndo : null,
                builder: (context, isLoading, safeTap) => CircleIconButton(
                  iconPath: QIcons.icArrowLeft,
                  iconColor: canUndo && !isLoading ? context.appColors.warning : context.appColors.textHint,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  borderColor: canUndo && !isLoading
                      ? context.appColors.warning
                      : context.appColors.textHint.withValues(alpha: 0.3),
                  size: 44,
                  onTap: safeTap ?? () {},
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              undoLabel(allowance, lockedLabel: context.tr('undo')),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isUndoLabelHighlighted(allowance, canUndo: canUndo)
                    ? context.appColors.warning
                    : context.appColors.textHint,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.xl),
        CircleIconButton(
          iconPath: QIcons.icX,
          iconColor: context.appColors.error,
          backgroundColor: Theme.of(context).colorScheme.surface,
          borderColor: context.appColors.error,
          onTap: onReject,
        ),
      ],
    );
  }
}
