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

  const ChatQuestionPowerBar({
    super.key,
    required this.optionCount,
    required this.isPowerBlocked,
    required this.hasHint,
    required this.onPowerTap,
    this.disabledPowers = const {},
    this.powerCounts = const {},
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

    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: powers.map((type) {
            final isUsed = disabledPowers.contains(type.apiName);

            return _ChatPowerButton(
              type: type,
              isUsed: isUsed,
              count: powerCounts[type.apiName] ?? 0,
              onTap: isUsed
                  ? null
                  : () async => onPowerTap(type.apiName),
            );
          }).toList(),
        ),
        if (isPowerBlocked)
          _PowerBlockOverlay(
            onUnblock: onPowerTap,
            unblockCount: powerCounts['POWER_UNBLOCK'] ?? 0,
          ),
      ],
    );
  }
}

class _ChatPowerButton extends StatelessWidget {
  final PowerType type;
  final bool isUsed;
  final int count;
  final Future<void> Function()? onTap;

  const _ChatPowerButton({
    required this.type,
    required this.isUsed,
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
          opacity: isUsed ? 1.0 : (count > 0 ? 1.0 : 0.4),
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
                                : QIcon(
                                    type.iconPath,
                                    size: 22,
                                    color: color,
                                  ),
                      ),
                    ),
                    if (!isUsed && count > 0)
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
                    color: isUsed ? Colors.grey : color,
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

class _PowerBlockOverlay extends StatelessWidget {
  final Future<void> Function(String powerName) onUnblock;
  final int unblockCount;

  const _PowerBlockOverlay({
    required this.onUnblock,
    this.unblockCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasInventory = unblockCount > 0;

    return Positioned.fill(
      child: SafeTapButton(
        onTap: () async => onUnblock('POWER_UNBLOCK'),
        builder: (context, isLoading, onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Center(
              child: isLoading
                  ? const AppLoadingWidget.small()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: colors.warning, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Güçler Kilitli',
                              style: TextStyle(
                                color: colors.warning,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_open, size: 10, color: colors.warning.withValues(alpha: 0.7)),
                                const SizedBox(width: 3),
                                if (hasInventory)
                                  Text(
                                    '$unblockCount adet',
                                    style: TextStyle(
                                      color: colors.warning.withValues(alpha: 0.7),
                                      fontSize: 10,
                                    ),
                                  )
                                else ...[
                                  const DiamondIcon.purple(size: 10, showGlow: false),
                                  const SizedBox(width: 2),
                                  Text(
                                    'ile aç',
                                    style: TextStyle(
                                      color: colors.warning.withValues(alpha: 0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
