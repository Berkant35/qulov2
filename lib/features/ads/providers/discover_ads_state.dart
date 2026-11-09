import 'package:qulo_v2/core/services/native_ad_handle.dart';

/// Oturum başına Discover reklam durumu.
///
/// [ad] yüklenmiş reklam (gösterilmeyi bekleyen ya da gösterilen);
/// [isShowing] true iken Discover destesinin yerinde reklam kartı vardır.
class DiscoverAdsState {
  const DiscoverAdsState({
    this.profilesPassed = 0,
    this.slotsResolved = 0,
    this.adsShown = 0,
    this.ad,
    this.isShowing = false,
    this.isLoading = false,
  });

  final int profilesPassed;
  final int slotsResolved;
  final int adsShown;
  final NativeAdHandle? ad;
  final bool isShowing;
  final bool isLoading;

  DiscoverAdsState copyWith({
    int? profilesPassed,
    int? slotsResolved,
    int? adsShown,
    NativeAdHandle? ad,
    bool clearAd = false,
    bool? isShowing,
    bool? isLoading,
  }) =>
      DiscoverAdsState(
        profilesPassed: profilesPassed ?? this.profilesPassed,
        slotsResolved: slotsResolved ?? this.slotsResolved,
        adsShown: adsShown ?? this.adsShown,
        ad: clearAd ? null : (ad ?? this.ad),
        isShowing: isShowing ?? this.isShowing,
        isLoading: isLoading ?? this.isLoading,
      );
}
