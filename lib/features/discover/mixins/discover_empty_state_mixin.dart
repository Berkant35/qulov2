import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Bos discover ekraninin sunum-disi logic'i.
mixin DiscoverEmptyStateMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Kullanicinin kayitli arama yaricapi; yoksa makul bir varsayilan.
  double initialRadiusKm() {
    final user = ref.read(userProvider).valueOrNull;
    return (user?.matchRadiusKm ?? AppConstants.defaultMatchRadiusKm).toDouble();
  }

  /// Bos destenin sebebine gore baslik/aciklama. `inactive` (2.0.18): adaylar
  /// vardi ama hepsi uzun suredir gorulmuyor — "simdi aktif kimse yok, davet et /
  /// sonra bak". Diger (bilinmeyen dahil) sebepler genel "profil kalmadi" metni.
  ({String titleKey, String messageKey}) emptyCopyFor(String? reason) =>
      reason == DiscoverEmptyReason.inactive
          ? (titleKey: 'discover_empty_inactive_title', messageKey: 'discover_empty_inactive_hint')
          : (titleKey: 'no_more_profiles', messageKey: 'no_more_profiles_hint');

  /// Yaricapi kaydeder ve kartlari yeniden ceker.
  Future<void> applyRadiusAndSearch(double radiusKm) async {
    await ref.read(userProvider.notifier).updateProfile({
      'match_radius_km': radiusKm.round(),
    });
    if (!mounted) return;
    await ref.read(discoverProvider.notifier).loadCards();
  }
}
