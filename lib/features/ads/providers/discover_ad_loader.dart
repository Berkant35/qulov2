import 'dart:developer' as dev;

import 'package:qulo_v2/core/services/admob_manager.dart';
import 'package:qulo_v2/core/services/att_manager.dart';
import 'package:qulo_v2/core/services/native_ad_handle.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/ads/analytics/ad_analytics.dart';

/// Tek bir Discover native reklamını hazırlar: onay → ATT durumu → istek.
///
/// ATT: yeni izin İSTENMEZ; yalnız mevcut durum okunur. İzin yoksa
/// kişiselleştirilmemiş (NPA) reklam istenir.
class DiscoverAdLoader {
  DiscoverAdLoader({
    required this.manager,
    required this.att,
    required this.analytics,
  });

  final AdMobManager manager;
  final AttManager att;
  final AdAnalytics analytics;

  static const style = NativeAdStyle(
    background: AppColors.surface,
    primaryText: AppColors.textPrimary,
    secondaryText: AppColors.textSecondary,
    ctaBackground: AppColors.primary,
    ctaText: AppColors.background,
    cornerRadius: AppSpacing.radiusMd,
  );

  /// Reklam tutamacı; onay yok / istek hatası / boş dönüşte `null`.
  /// [stillAllowed], onay ve ağ beklemesi sonrası yeniden sorulur (VIP olduysa vazgeç).
  Future<NativeAdHandle?> load({required bool Function() stillAllowed}) async {
    try {
      if (!await manager.ensureReady() || !stillAllowed()) return null;
      final personalized = await att.isAuthorized();
      final handle = await manager.loadNativeAd(
        nonPersonalized: !personalized,
        style: style,
        onImpression: analytics.impression,
        onClicked: analytics.clicked,
      );
      analytics.loaded();
      return handle;
    } on NativeAdLoadException catch (e) {
      analytics.failed(e.code);
    } catch (e) {
      dev.log('ad load error: $e', name: 'DiscoverAdLoader');
      analytics.failed(-1);
    }
    return null;
  }
}
