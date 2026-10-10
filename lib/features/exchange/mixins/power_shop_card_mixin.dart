import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/power_labels.dart';
import 'package:qulo_v2/core/constants/power_purchase.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/exchange/widgets/power_shop_card.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// [PowerShopCard] icin sunum-disi logic: etiket eslemeleri ve guc satin alma akisi.
/// Envanter pulse'i `InventoryPulse` widget'inda. Widget yalnizca UI orchestration barindirir.
mixin PowerShopCardMixin on ConsumerState<PowerShopCard> {
  DiamondType? buyingWith;
  int quantity = 1;

  PowerType get powerType => PowerType.fromApiName(widget.power.name) ?? PowerType.oracle;

  String get powerLabel => context.tr(powerLabelKey(widget.power.name));

  String get powerDesc => context.tr(powerDescKey(widget.power.name));

  Future<void> onBuy(DiamondType type) async {
    if (buyingWith != null) return;
    setState(() => buyingWith = type);

    final result = await ref
        .read(exchangeProvider.notifier)
        .buyPower(widget.power.name, type.apiName, quantity);

    if (!mounted) return;
    result.when(
      success: (_) {
        // geri bildirim: envanter sayısı artınca InventoryPulse oynar
      },
      failure: (f) => _showPurchaseFailure(f, type),
    );
    setState(() => buyingWith = null);
  }

  void _showPurchaseFailure(AppFailure failure, DiamondType type) {
    final code = failure is ServerFailure ? failure.code : null;
    switch (classifyPowerPurchaseFailure(code)) {
      case PowerPurchaseFailureKind.insufficient:
        final params = (failure as ServerFailure).params as Map<String, dynamic>?;
        _showSnack(
          context.tr('purchase_insufficient_diamonds')
              .replaceAll('{required}', '${params?['required'] ?? ''}')
              .replaceAll('{current}', '${params?['current'] ?? ''}'),
          // Rainbow satın alınamaz: "elmas al" yönlendirmesi yalnız mor/yeşil için.
          withGetDiamonds: type != DiamondType.rainbow,
        );
      case PowerPurchaseFailureKind.rainbowUnavailable:
        _showSnack(context.tr('rainbow_not_available'));
        // Sunucu kararı değişti (ülke/platform kapandı): bayrağı tazele, Rainbow butonu kaybolsun.
        ref.read(userProvider.notifier).fetchMe();
      case PowerPurchaseFailureKind.cooldown:
      case PowerPurchaseFailureKind.other:
        _showSnack(context.tr(failure.userMessageKey('purchase_failed')));
    }
  }

  void _showSnack(String message, {bool withGetDiamonds = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appColors.error,
        action: withGetDiamonds
            ? SnackBarAction(
                label: context.tr('purchase_get_diamonds'),
                textColor: AppColors.inkOnDark,
                onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.diamonds),
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
