import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// Kapsam chip'inin sunum-disi logic'i.
///
/// Stateless widget oldugu icin `on` kisitsiz plain mixin (proje kurali:
/// widget yalnizca UI orchestration, calistirilan fonksiyonlar mixin'de).
mixin DiscoverScopeChipMixin {
  /// Arama kullanicinin kendi radius'unun disina tasti mi.
  bool isExpanded(int distanceTier) => distanceTier > 0;

  /// Chip metni. Mesafe bilinmiyorsa (null) sayi eklenmez —
  /// 0 "yakinda" demek DEGIL, sunucu hesaplayamamis demek.
  String scopeLabel(BuildContext context, {required int distanceTier, double? distanceKm}) {
    final text = context.tr(
      isExpanded(distanceTier) ? 'discover_scope_expanded' : 'discover_scope_nearby',
    );
    if (distanceKm == null) return text;
    return '$text · ${context.fmt.radius(distanceKm)}';
  }
}
