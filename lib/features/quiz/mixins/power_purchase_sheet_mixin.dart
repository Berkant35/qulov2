import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/power_purchase.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/features/quiz/widgets/power_purchase_sheet.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// [PowerPurchaseSheet] icin sunum-disi logic: ilk bakiye/oran cekme ve guc satin
/// alma akisi (basari, yetersiz elmas → paywall/snackbar, Rainbow kapali → snackbar +
/// bayrak tazeleme). Widget yalnizca UI orchestration barindirir.
mixin PowerPurchaseSheetMixin on ConsumerState<PowerPurchaseSheet> {
  ({String power, DiamondType type})? buying;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(diamondProvider.notifier).fetchBalance();
      ref.read(exchangeProvider.notifier).fetchAll();
    });
  }

  Future<void> onBuy(String powerName, DiamondType type, int quantity) async {
    if (buying != null) return;
    setState(() => buying = (power: powerName, type: type));

    final result = await ref
        .read(exchangeProvider.notifier)
        .buyPower(powerName, type.apiName, quantity);

    if (!mounted) return;

    result.when(
      success: (_) {
        // Sheet stays open — user closes manually
      },
      failure: (f) {
        final code = f is ServerFailure ? f.code : null;
        switch (classifyPowerPurchaseFailure(code)) {
          case PowerPurchaseFailureKind.insufficient when type == DiamondType.purple:
            // Paywall yalnız mor için; yeşil/Rainbow satın alınamaz, snackbar gösterilir.
            Navigator.of(context).pop();
            PaywallBottomSheetContent.show(ref, trigger: 'power_purchase');
          case PowerPurchaseFailureKind.rainbowUnavailable:
            showPurchaseError(context.tr('rainbow_not_available'));
            ref.read(userProvider.notifier).fetchMe();
          case _:
            showPurchaseError(context.tr(f.userMessageKey('purchase_failed')));
        }
      },
    );
    if (mounted) setState(() => buying = null);
  }

  void showPurchaseError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: context.appColors.error),
    );
  }
}
