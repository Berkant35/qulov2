import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';

class ChatQuestionPowerBar extends StatelessWidget {
  final int optionCount;
  final bool isPowerBlocked;
  final bool hasHint;
  final void Function(String powerName) onPowerTap;
  final Set<String> disabledPowers;

  const ChatQuestionPowerBar({
    super.key,
    required this.optionCount,
    required this.isPowerBlocked,
    required this.hasHint,
    required this.onPowerTap,
    this.disabledPowers = const {},
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
              onTap: isUsed
                  ? null
                  : () async => onPowerTap(type.apiName),
            );
          }).toList(),
        ),
        if (isPowerBlocked) _PowerBlockOverlay(onUnblock: onPowerTap),
      ],
    );
  }
}

class _ChatPowerButton extends StatelessWidget {
  final PowerType type;
  final bool isUsed;
  final Future<void> Function()? onTap;

  const _ChatPowerButton({
    required this.type,
    required this.isUsed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;
    final theme = Theme.of(context);

    return SafeTapButton(
      onTap: onTap,
      builder: (context, isLoading, safeTap) => GestureDetector(
        onTap: safeTap,
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUsed
                      ? theme.colorScheme.surfaceContainerHighest
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
  final void Function(String powerName) onUnblock;

  const _PowerBlockOverlay({required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, color: AppColors.warning, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Güçler Engellenmiş',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SafeTapButton(
                onTap: () async => onUnblock('POWER_UNBLOCK'),
                builder: (context, isLoading, onTap) => TextButton.icon(
                  onPressed: onTap,
                  icon: isLoading
                      ? const AppLoadingWidget.small()
                      : const Icon(Icons.lock_open, size: 16),
                  label: Text(AppLocalizations.of(context).get('chat_unlock')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
