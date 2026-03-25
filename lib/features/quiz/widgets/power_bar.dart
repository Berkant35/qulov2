import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/features/quiz/widgets/power_purchase_sheet.dart';

class PowerBar extends ConsumerWidget {
  final String sessionId;
  final bool hasHint;
  final void Function(String power)? onPowerUsed;
  final VoidCallback? onSheetOpening;
  final VoidCallback? onSheetClosed;

  const PowerBar({
    super.key,
    required this.sessionId,
    this.hasHint = false,
    this.onPowerUsed,
    this.onSheetOpening,
    this.onSheetClosed,
  });

  static const _powers = [
    PowerType.oracle,
    PowerType.half,
    PowerType.skip,
    PowerType.hint,
    PowerType.timeExtend,
    PowerType.skipAll,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeState = ref.watch(exchangeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _powers.map((type) {
        final count = exchangeState.getCount(type.apiName);
        final hasInventory = count > 0;
        final isHintDisabled = type == PowerType.hint && !hasHint;
        final isDisabled = !hasInventory || isHintDisabled;

        return _PowerButton(
          type: type,
          count: count,
          hasInventory: hasInventory && !isHintDisabled,
          onTap: isDisabled
              ? () async => _onEmptyPowerTap(context)
              : () async => onPowerUsed?.call(type.apiName),
        );
      }).toList(),
    );
  }

  void _onEmptyPowerTap(BuildContext context) {
    onSheetOpening?.call();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => const PowerPurchaseSheet(),
    ).whenComplete(() {
      onSheetClosed?.call();
    });
  }
}

class _PowerButton extends StatelessWidget {
  final PowerType type;
  final int count;
  final bool hasInventory;
  final Future<void> Function() onTap;

  const _PowerButton({
    required this.type,
    required this.count,
    required this.hasInventory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;

    return SafeTapButton(
      onTap: onTap,
      builder: (context, isLoading, safeTap) => GestureDetector(
        onTap: safeTap,
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
                      color: hasInventory
                          ? color.withValues(alpha: 0.15)
                          : context.appColors.surfaceElevated,
                      border: Border.all(
                        color: hasInventory
                            ? color.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isLoading
                          ? AppLoadingWidget.small()
                          : QIcon(
                              type.iconPath,
                              size: 22,
                              color: hasInventory ? color : Colors.grey,
                            ),
                    ),
                  ),
                  if (hasInventory && !isLoading)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
