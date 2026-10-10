import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_network_svg.dart';
import 'package:qulo_v2/features/rewards_market/market_labels.dart';

/// Marka logosu; logo yoksa baş harf rozeti. SVG logo `AppNetworkSvg` ile (ham `SvgPicture.network`
/// / resim yükleyici SVG'de çöker ya da Crashlytics'e fatal düşer), diğerleri önbellekli resimle.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.brandKey, this.logoUrl, this.size = 40});

  final String brandKey;
  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.rainbow.withValues(alpha: 0.18),
      child: Text(
        rewardBrandLabel(context, brandKey).characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.rainbow, fontWeight: FontWeight.w800),
      ),
    );
    final url = logoUrl;
    if (url == null) return fallback;
    if (AppNetworkSvg.isSvgUrl(url)) {
      return ClipOval(child: AppNetworkSvg(url: url, size: size, placeholder: fallback));
    }
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * dpr).round(),
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
