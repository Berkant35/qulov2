import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/exchange/widgets/power_shop_card.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// [PowerShopCard] icin sunum-disi logic: pulse animasyonu, etiket eslemeleri
/// ve guc satin alma akisi. Widget yalnizca UI orchestration barindirir.
mixin PowerShopCardMixin on ConsumerState<PowerShopCard>
    implements TickerProvider {
  String? buyingWith; // 'purple' or 'green' or null
  int quantity = 1;

  late final AnimationController pulseController;
  late final Animation<double> scaleAnimation;
  late final Animation<double> glowAnimation;
  int previousCount = 0;

  @override
  void initState() {
    super.initState();
    previousCount = widget.inventoryCount;

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    scaleAnimation = TweenSequence<double>([
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
    ]).animate(pulseController);

    glowAnimation = TweenSequence<double>([
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
    ]).animate(pulseController);
  }

  @override
  void didUpdateWidget(PowerShopCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inventoryCount > previousCount) {
      pulseController.forward(from: 0);
    }
    previousCount = widget.inventoryCount;
  }

  @override
  void dispose() {
    pulseController.dispose();
    super.dispose();
  }

  PowerType get powerType => PowerType.fromApiName(widget.power.name) ?? PowerType.oracle;

  String get powerLabel {
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

  String get powerDesc {
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

  Future<void> onBuy(String diamondType) async {
    if (buyingWith != null) return;
    setState(() => buyingWith = diamondType);

    final result = await ref
        .read(exchangeProvider.notifier)
        .buyPower(widget.power.name, diamondType.toUpperCase(), quantity);

    if (mounted) {
      result.when(
        success: (_) {
          // animation in didUpdateWidget is the feedback
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
      setState(() => buyingWith = null);
    }
  }
}
