import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/power_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

class PowerPurchaseSheet extends ConsumerStatefulWidget {
  const PowerPurchaseSheet({super.key});

  @override
  ConsumerState<PowerPurchaseSheet> createState() => _PowerPurchaseSheetState();
}

class _PowerPurchaseSheetState extends ConsumerState<PowerPurchaseSheet> {
  String? _buyingKey; // e.g. 'ORACLE_PURPLE'

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(diamondProvider.notifier).fetchBalance();
      ref.read(exchangeProvider.notifier).fetchAll();
    });
  }

  Future<void> _onBuy(String powerName, String diamondType, int quantity) async {
    final key = '${powerName}_$diamondType';
    if (_buyingKey != null) return;
    setState(() => _buyingKey = key);

    final result = await ref
        .read(exchangeProvider.notifier)
        .buyPower(powerName, diamondType, quantity);

    if (!mounted) return;

    result.when(
      success: (_) {
        // Sheet stays open — user closes manually
      },
      failure: (f) {
        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          // Paywall purple-only path; green can only be earned, so show snackbar instead.
          if (diamondType == 'PURPLE') {
            Navigator.of(context).pop();
            PaywallBottomSheetContent.show(ref, trigger: 'power_purchase');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(f.message ?? context.tr('purchase_failed')),
                backgroundColor: context.appColors.error,
              ),
            );
          }
          return;
        }
        if (f is ServerFailure && f.code == 'DIAMOND_COOLDOWN') {
          // 24h social-signup cooldown — subscription doesn't bypass; show explanation.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(f.message ?? context.tr('purchase_failed')),
              backgroundColor: context.appColors.error,
            ),
          );
          return;
        }
        final message = f.message ?? context.tr('purchase_failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: context.appColors.error,
          ),
        );
      },
    );
    setState(() => _buyingKey = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exchange = ref.watch(exchangeProvider);
    final balance = ref.watch(diamondProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              context.tr('quiz_buy_power'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Diamond balance
            balance.when(
              data: (bal) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DiamondIcon.green(size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${bal.green}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: context.appColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  const DiamondIcon.purple(size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${bal.purple}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: context.appColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: AppLoadingWidget.small()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Power list
            if (exchange.isLoading)
              const Center(child: AppLoadingWidget.large())
            else if (exchange.rates != null)
              ...exchange.rates!.powers.map(
                (power) => _PowerRow(
                  power: power,
                  inventoryCount: exchange.getCount(power.name),
                  buyingKey: _buyingKey,
                  onBuy: _onBuy,
                ),
              ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _PowerRow extends StatefulWidget {
  final ExchangeRatePower power;
  final int inventoryCount;
  final String? buyingKey;
  final Future<void> Function(String powerName, String diamondType, int quantity) onBuy;

  const _PowerRow({
    required this.power,
    required this.inventoryCount,
    required this.buyingKey,
    required this.onBuy,
  });

  @override
  State<_PowerRow> createState() => _PowerRowState();
}

class _PowerRowState extends State<_PowerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  late int _previousCount;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.inventoryCount;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_pulseController);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(_PowerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inventoryCount > _previousCount) {
      _pulseController.forward(from: 0);
    }
    _previousCount = widget.inventoryCount;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _powerLabel(BuildContext context) =>
      context.tr(powerLabelKey(widget.power.name));

  String _powerDesc(BuildContext context) =>
      context.tr(powerDescKey(widget.power.name));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerType = PowerType.fromApiName(widget.power.name);
    if (powerType == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _pulseController.isAnimating
                        ? [
                            BoxShadow(
                              color: powerType.color
                                  .withValues(alpha: _glowAnimation.value),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: PowerIcon(
                type: powerType,
                size: 28,
                showCount: widget.inventoryCount > 0,
                count: widget.inventoryCount,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _powerLabel(context),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _powerDesc(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity stepper
            _QuantityStepper(
              quantity: _quantity,
              onChanged: (q) => setState(() => _quantity = q),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Purple buy button
            _BuyChip(
              cost: widget.power.purpleCost * _quantity,
              icon: const DiamondIcon.purple(size: 14, showGlow: false),
              isLoading: widget.buyingKey == '${widget.power.name}_PURPLE',
              onTap: () => widget.onBuy(widget.power.name, 'PURPLE', _quantity),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Green buy button
            _BuyChip(
              cost: widget.power.greenCost * _quantity,
              icon: const DiamondIcon.green(size: 14, showGlow: false),
              isLoading: widget.buyingKey == '${widget.power.name}_GREEN',
              onTap: () => widget.onBuy(widget.power.name, 'GREEN', _quantity),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            enabled: quantity > 1,
            onTap: () => onChanged(quantity - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$quantity',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            enabled: quantity < 99,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? context.appColors.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _BuyChip extends StatelessWidget {
  final int cost;
  final Widget icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _BuyChip({
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
                width: 36,
                height: 18,
                child: Center(child: AppLoadingWidget.small()),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 4),
                  Text(
                    '$cost',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
