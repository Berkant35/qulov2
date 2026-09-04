import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// AppBar icin kompakt mor/yesil bakiye.
///
/// Kaynak `userProvider`: uygulama acilisinda zaten yuklu, ekstra istek yok;
/// bakiye yerel guncellendiginde aninda yeniden cizilir.
class CompactDiamondBalance extends ConsumerWidget {
  const CompactDiamondBalance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    // Rengi AppBar'dan miras al: temanin `labelMedium`'u ikincil (gri) renk tasiyor.
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: DefaultTextStyle.of(context).style.color,
        );

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DiamondIcon.purple(size: 14, showGlow: false),
          const SizedBox(width: 2),
          Text('${user.purpleDiamonds}', style: style),
          const SizedBox(width: AppSpacing.sm),
          const DiamondIcon.green(size: 14, showGlow: false),
          const SizedBox(width: 2),
          Text('${user.greenDiamonds}', style: style),
        ],
      ),
    );
  }
}
