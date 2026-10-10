import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/rainbow_balance_chip.dart';
import 'package:qulo_v2/providers/rainbow_flag.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Üst çubukta Rainbow bakiyesi; dokununca market (`push`: geri tuşu açıldığı sekmeye — Keşfet ya da
/// Profil — döner). Rainbow kapalıysa hiç çizilmez.
class RainbowMarketButton extends ConsumerWidget {
  const RainbowMarketButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watchRainbowEnabled()) return const SizedBox.shrink();
    final balance = ref.watch(userProvider.select((u) => u.valueOrNull?.rainbowDiamonds ?? 0));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Tooltip(
        message: context.tr('market_title'),
        child: RainbowBalanceChip(
          balance: balance,
          onTap: () => ref.read(navigationServiceProvider).push(RouteNames.rewardsMarket),
        ),
      ),
    );
  }
}
