import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/data/models/economy_config_model.dart';

class ChatQuestionPowerBar extends StatelessWidget {
  final int optionCount;
  final bool isPowerBlocked;
  final bool hasHint;
  final Future<void> Function(String powerName) onPowerTap;
  final Set<String> disabledPowers;
  final Map<String, int> powerCounts;
  final PowerCostsConfig powerCosts;

  const ChatQuestionPowerBar({
    super.key,
    required this.optionCount,
    required this.isPowerBlocked,
    required this.hasHint,
    required this.onPowerTap,
    this.disabledPowers = const {},
    this.powerCounts = const {},
    this.powerCosts = PowerCostsConfig.fallback,
  });

  List<PowerType> get _availablePowers {
    if (optionCount == 2) {
      return [PowerType.oracle, PowerType.skip];
    }
    return [
      PowerType.oracle,
      PowerType.half,
      if (hasHint) PowerType.hint,
      PowerType.timeExtend,
      PowerType.skip,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final powers = _availablePowers;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: powers.map((type) {
            final isUsed = disabledPowers.contains(type.apiName);
            final count = powerCounts[type.apiName] ?? 0;
            final cost = powerCosts.forPower(type.apiName);

            return _ChatPowerButton(
              type: type,
              isUsed: isUsed,
              isLocked: isPowerBlocked,
              count: count,
              purpleCost: cost?.purpleCost ?? 0,
              greenCost: cost?.greenCost ?? 0,
              onTap: (isUsed || isPowerBlocked)
                  ? null
                  : () async => onPowerTap(type.apiName),
            );
          }).toList(),
        ),
        if (isPowerBlocked) ...[
          const SizedBox(height: AppSpacing.sm),
          _UnlockButton(
            onUnblock: onPowerTap,
            unblockCount: powerCounts['POWER_UNBLOCK'] ?? 0,
            unblockCost: powerCosts.powerUnblock.purpleCost,
          ),
        ],
      ],
    );
  }
}

class _ChatPowerButton extends StatelessWidget {
  final PowerType type;
  final bool isUsed;
  final bool isLocked;
  final int count;
  final int purpleCost;
  final int greenCost;
  final Future<void> Function()? onTap;

  const _ChatPowerButton({
    required this.type,
    required this.isUsed,
    this.isLocked = false,
    required this.count,
    this.purpleCost = 0,
    this.greenCost = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;
    final hasInventory = count > 0;
    // Kullanılmış → full opak, kilitli → çok soluk, envanterde var → full, envanterde yok → biraz soluk
    final isSelectable = !isUsed && !isLocked;

    return SafeTapButton(
      onTap: onTap,
      builder: (context, isLoading, safeTap) => GestureDetector(
        onTap: safeTap,
        child: Opacity(
          opacity: isUsed ? 1.0 : isLocked ? 0.3 : 1.0,
          child: SizedBox(
            width: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUsed
                            ? context.appColors.surfaceElevated
                            : color.withValues(alpha: 0.15),
                        border: Border.all(
                          color: isUsed
                              ? context.appColors.textHint.withValues(alpha: 0.3)
                              : color.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isLoading
                            ? const AppLoadingWidget.small()
                            : isUsed
                                ? Icon(Icons.check, size: 20, color: context.appColors.textHint)
                                : isLocked
                                    ? Icon(Icons.lock, size: 18,
                                        color: context.appColors.textHint.withValues(alpha: 0.6))
                                    : QIcon(type.iconPath, size: 22, color: color),
                      ),
                    ),
                    // Envanter badge
                    if (isSelectable && hasInventory)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _powerLabel(context, type),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: (isUsed || isLocked) ? context.appColors.textHint : color,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Maliyet — envanterde yoksa ve seçilebilirse göster
                if (isSelectable && !hasInventory && purpleCost > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const DiamondIcon.purple(size: 8, showGlow: false),
                        Text(
                          '$purpleCost',
                          style: TextStyle(
                            fontSize: 8,
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const DiamondIcon.green(size: 8, showGlow: false),
                        Text(
                          '$greenCost',
                          style: TextStyle(
                            fontSize: 8,
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _powerLabel(BuildContext context, PowerType type) => switch (type) {
        PowerType.oracle => context.tr('power_bar_oracle'),
        PowerType.half => context.tr('power_bar_half'),
        PowerType.skip => context.tr('power_bar_skip'),
        PowerType.hint => context.tr('power_bar_hint'),
        PowerType.timeExtend => context.tr('power_bar_time'),
        PowerType.skipAll => context.tr('power_bar_skip_all'),
        PowerType.powerBlock => context.tr('power_bar_block'),
        PowerType.powerUnblock => context.tr('power_bar_unlock'),
      };
}

class _UnlockButton extends StatelessWidget {
  final Future<void> Function(String powerName) onUnblock;
  final int unblockCount;
  final int unblockCost;

  const _UnlockButton({
    required this.onUnblock,
    this.unblockCount = 0,
    this.unblockCost = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasInventory = unblockCount > 0;

    return SafeTapButton(
      onTap: () async => onUnblock('POWER_UNBLOCK'),
      builder: (context, isLoading, onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
          ),
          child: isLoading
              ? const Center(child: AppLoadingWidget.small())
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_open, size: 16, color: colors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.tr('power_bar_unlock'),
                      style: TextStyle(
                        color: colors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: hasInventory
                          ? Text(
                              '×$unblockCount',
                              style: TextStyle(
                                color: colors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const DiamondIcon.purple(
                                    size: 12, showGlow: false),
                                const SizedBox(width: 3),
                                Text(
                                  '$unblockCost',
                                  style: TextStyle(
                                    color: colors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
