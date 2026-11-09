import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/native_ad_handle.dart';
import 'package:qulo_v2/features/ads/providers/discover_ads_notifier.dart';

/// `DiscoverAdCard` logic'i: reklamı geçme (buton ya da başlık şeridinden kaydırma).
///
/// Reklam kartı beğeni/ret DEĞİLDİR: `discoverProvider`'a, swipe API'sine ya da
/// undo yığınına dokunmaz; yalnız [DiscoverAdsNotifier.dismiss] çağrılır.
mixin DiscoverAdCardMixin {
  /// Başlık şeridinde bu hızın (px/s) üstündeki yatay sürükleme kartı geçer.
  static const swipeVelocity = 300.0;

  NativeAdHandle? currentAd(WidgetRef ref) => ref.watch(discoverAdsProvider.select((s) => s.ad));

  void skip(WidgetRef ref) => ref.read(discoverAdsProvider.notifier).dismiss();

  void onLabelDragEnd(WidgetRef ref, DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dx.abs() >= swipeVelocity) skip(ref);
  }
}
