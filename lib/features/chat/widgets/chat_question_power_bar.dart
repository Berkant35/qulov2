import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';

class ChatQuestionPowerBar extends StatelessWidget {
  final int optionCount;
  final bool isPowerBlocked;
  final bool hasHint;
  final Future<void> Function(String powerName) onPowerTap;
  final Set<String> disabledPowers;
  final Map<String, int> powerCounts;
  final int unblockCost;

  const ChatQuestionPowerBar({
    super.key,
    required this.optionCount,
    required this.isPowerBlocked,
    required this.hasHint,
    required this.onPowerTap,
    this.disabledPowers = const {},
    this.powerCounts = const {},
    this.unblockCost = 0,
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

            return _ChatPowerButton(
              type: type,
              isUsed: isUsed,
              isLocked: isPowerBlocked,
              count: powerCounts[type.apiName] ?? 0,
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
            unblockCost: unblockCost,
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
  final Future<void> Function()? onTap;

  const _ChatPowerButton({
    required this.type,
    required this.isUsed,
    this.isLocked = false,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;

    return SafeTapButton(
      onTap: onTap,
      builder: (context, isLoading, safeTap) => GestureDetector(
        onTap: safeTap,
        child: Opacity(
          opacity: isUsed ? 1.0 : isLocked ? 0.35 : (count > 0 ? 1.0 : 0.4),
          child: SizedBox(
            width: 52,
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
                              ? Colors.grey.withValues(alpha: 0.3)
                              : color.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isLoading
                            ? const AppLoadingWidget.small()
                            : isUsed
                                ? Icon(Icons.check, size: 20, color: Colors.grey)
                                : isLocked
                                    ? Icon(Icons.lock, size: 18, color: Colors.grey.withValues(alpha: 0.6))
                                    : QIcon(
                                        type.iconPath,
                                        size: 22,
                                        color: color,
                                      ),
                      ),
                    ),
                    if (!isUsed && !isLocked && count > 0)
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
                  _powerLabel(type),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: (isUsed || isLocked) ? Colors.grey : color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _powerLabel(PowerType type) => switch (type) {
        PowerType.oracle => 'Oracle',
        PowerType.half => 'Yarıla',
        PowerType.skip => 'Geç',
        PowerType.hint => 'İpucu',
        PowerType.timeExtend => '+15s',
        PowerType.skipAll => 'Hepsini Geç',
        PowerType.powerBlock => 'Engel',
        PowerType.powerUnblock => 'Kilidi Aç',
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
                      'Kilidi Aç',
                      style: TextStyle(
                        color: colors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: hasInventory
                          ? Text(
                              '$unblockCount adet',
                              style: TextStyle(
                                color: colors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const DiamondIcon.purple(size: 12, showGlow: false),
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
