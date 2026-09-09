import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Bos discover ekraninin sunum-disi logic'i.
mixin DiscoverEmptyStateMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Kullanicinin kayitli arama yaricapi; yoksa makul bir varsayilan.
  double initialRadiusKm() {
    final user = ref.read(userProvider).valueOrNull;
    return (user?.matchRadiusKm ?? AppConstants.defaultMatchRadiusKm).toDouble();
  }

  /// Yaricapi kaydeder ve kartlari yeniden ceker.
  Future<void> applyRadiusAndSearch(double radiusKm) async {
    await ref.read(userProvider.notifier).updateProfile({
      'match_radius_km': radiusKm.round(),
    });
    await ref.read(discoverProvider.notifier).loadCards();
  }
}
