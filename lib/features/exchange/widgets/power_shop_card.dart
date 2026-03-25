import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class PowerShopCard extends ConsumerStatefulWidget {
  final ExchangeRatePower power;
  final int inventoryCount;

  const PowerShopCard({
    super.key,
    required this.power,
    required this.inventoryCount,
  });

  @override
  ConsumerState<PowerShopCard> createState() => _PowerShopCardState();
}

class _PowerShopCardState extends ConsumerState<PowerShopCard> {
  String? _buyingWith; // 'purple' or 'green' or null

  PowerType get _powerType => PowerType.fromApiName(widget.power.name) ?? PowerType.oracle;

  String get _powerLabel {
    final key = switch (widget.power.name) {
      'ORACLE' => 'power_oracle',
      'HALF' => 'power_half',
      'SKIP' => 'power_skip',
      'SKIP_ALL' => 'power_skip_all',
      'TIME_EXTEND' => 'power_time',
      'HINT' => 'power_hint',
      _ => widget.power.name,
    };
    return context.tr(key);
  }

  String get _powerDesc {
    final key = switch (widget.power.name) {
      'ORACLE' => 'power_oracle_desc',
      'HALF' => 'power_half_desc',
      'SKIP' => 'power_skip_desc',
      'SKIP_ALL' => 'power_skip_all_desc',
      'TIME_EXTEND' => 'power_time_extend_desc',
      'HINT' => 'power_hint_desc',
      _ => '',
    };
    return context.tr(key);
  }

  Future<void> _onBuy(String diamondType) async {
    if (_buyingWith != null) return;
    setState(() => _buyingWith = diamondType);

    final result = await ref
        .read(exchangeProvider.notifier)
        .buyPower(widget.power.name, diamondType.toUpperCase(), 1);

    if (mounted) {
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('purchase_success'))),
          );
        },
        failure: (f) {
          if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
            final params = f.params as Map<String, dynamic>?;
            final required = params?['required'] ?? '';
            final current = params?['current'] ?? '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr('purchase_insufficient_diamonds')
                      .replaceAll('{required}', '$required')
                      .replaceAll('{current}', '$current'),
                ),
                backgroundColor: context.appColors.error,
                action: SnackBarAction(
                  label: context.tr('purchase_get_diamonds'),
                  textColor: Colors.white,
                  onPressed: () {
                    ref.read(navigationServiceProvider).go(RouteNames.diamonds);
                  },
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(f.message ?? context.tr('purchase_failed')),
                backgroundColor: context.appColors.error,
              ),
            );
          }
        },
      );
      setState(() => _buyingWith = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Power icon with inventory badge
          PowerIcon(
            type: _powerType,
            size: 32,
            showCount: widget.inventoryCount > 0,
            count: widget.inventoryCount,
          ),
          const SizedBox(width: AppSpacing.md),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _powerLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _powerDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Buy buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Purple cost button
              _BuyButton(
                cost: widget.power.purpleCost,
                icon: const DiamondIcon.purple(size: 16, showGlow: false),
                isLoading: _buyingWith == 'purple',
                onTap: () => _onBuy('purple'),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Green cost button
              _BuyButton(
                cost: widget.power.greenCost,
                icon: const DiamondIcon.green(size: 16, showGlow: false),
                isLoading: _buyingWith == 'green',
                onTap: () => _onBuy('green'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final int cost;
  final Widget icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _BuyButton({
    required this.cost,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 48,
                height: 20,
                child: Center(child: AppLoadingWidget.small()),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$cost',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
