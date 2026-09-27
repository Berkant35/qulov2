import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/utils/referral_share.dart';
import 'package:qulo_v2/features/discover/mixins/discover_invite_hint_mixin.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/referral_provider.dart';

/// Havuz bittiginde "arkadasini cagir" girisi.
///
/// Davet sistemi 2026-09-27'ye kadar YALNIZ Elmaslar ekranindaydi: kullanici
/// oraya elmas almaya gider, arkadas davet etmeye degil. Sonuc olculdu —
/// `referrals` tablosunda 584 aktif kullaniciya karsilik sifir satir. Mekanik
/// calisiyordu; kimse bulundugu yeri gormuyordu.
///
/// Burasi dogru an: ekranda gosterilecek kimse kalmamis, kullanicinin istedigi
/// sey daha fazla insan, ve davet tam olarak onu getiriyor. Elmas ikincil —
/// etiket once cagriyi, sonra odulu soyluyor.
///
/// Veriyi `referralProvider` kendisi yukluyor; bu giris ilk yazildiginda
/// provider bos state donuyordu ve onu dolduran tek yer Elmaslar ekraniydi —
/// yani giris tam olarak hedef kitlede hic cizilmiyordu.
class DiscoverInviteHint extends ConsumerWidget with DiscoverInviteHintMixin {
  const DiscoverInviteHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referral = ref.watch(referralProvider).valueOrNull;
    final code = shareableInviteCode(
      code: referral?.code,
      stats: referral?.stats,
    );
    if (code == null) return const SizedBox.shrink();

    // `watch`: config `EconomyConfig.fallback` ile basliyor ve gercek deger
    // sonradan geliyor (splash fetch, basarisizsa 30 sn sonra tekrar). `read`
    // olsa ekran acikken gelen degeri kacirir ve odul sayisi yanlis kalirdi —
    // para metninde bu kabul edilemez.
    final reward = ref.watch(
      economyConfigProvider.select((c) => c.rewards.referralPurple),
    );

    return TextButton.icon(
      onPressed: () => ref.read(shareManagerProvider).share(
            buildReferralShareMessage(
              template: context.tr('referral_share_message'),
              reward: reward,
              code: code,
            ),
          ),
      icon: const Icon(Icons.person_add_alt, size: 16),
      label: Text(
        inviteLabel(
          template: context.tr('discover_invite_friend'),
          reward: reward,
        ),
        textAlign: TextAlign.center,
      ),
      style: TextButton.styleFrom(foregroundColor: context.appColors.secondary),
    );
  }
}
