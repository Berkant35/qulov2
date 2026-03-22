import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/referral_invite_card.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/referral_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class DiamondsReferralSection extends ConsumerWidget {
  const DiamondsReferralSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralProvider);

    return referralAsync.when(
      loading: () => const Center(child: AppLoadingWidget.small()),
      error: (_, __) => const SizedBox.shrink(),
      data: (referralState) => ReferralInviteCard(
        code: referralState.code,
        stats: referralState.stats,
        onShare: () {
          if (referralState.code != null) {
            final code = referralState.code!;
            final reward = ref.read(economyConfigProvider).rewards.referralPurple;
            final message =
                "Qulo'ya katıl! Davet kodumu kullan, ikimize de $reward mor elmas hediye: $code\nhttps://qulo.app/invite/$code";
            ref.read(shareManagerProvider).share(message);
          }
        },
      ),
    );
  }
}
