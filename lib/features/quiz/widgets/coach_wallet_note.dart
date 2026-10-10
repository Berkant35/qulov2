import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Güç turu kartındaki cüzdan satırı: "Cüzdanında N mor elmas var".
///
/// Yeni hesaba 30 başlangıç moru veriliyor (qulo-server `STARTER_PURPLE`).
/// Ayrı bir bilgi/overlay açmak yerine ilk quiz'den önce zaten gösterilen güç
/// turuna tek satır eklendi — güçlerin parasının hazır olduğu tam o anda.
/// Bakiye 0 (ya da profil yüklenmemiş) ise satır görünmez.
class CoachWalletNote extends ConsumerWidget {
  const CoachWalletNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purple = ref.watch(userProvider.select((u) => u.valueOrNull?.purpleDiamonds)) ?? 0;
    if (purple <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          const DiamondIcon.purple(size: 20, showGlow: false),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.tr('coach_quiz_wallet_note').replaceAll('{count}', context.fmt.integer(purple)),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
