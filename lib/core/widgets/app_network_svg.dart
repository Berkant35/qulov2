import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/network/safe_svg_network_loader.dart';

/// Agdan SVG gosterir; bozuk/eksik icerikte hata firlatmaz, bos cizer.
///
/// Ham `SvgPicture.network` kullanma: yukleme hatasi Crashlytics'e fatal
/// olarak duser (bkz. `SafeSvgNetworkLoader`).
class AppNetworkSvg extends StatelessWidget {
  const AppNetworkSvg({
    super.key,
    required this.url,
    this.size = AppSizes.iconMd,
    this.placeholder,
  });

  final String url;
  final double size;

  /// Yuklenirken gosterilir; verilmezse ayni boyutta bos alan.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return SvgPicture(
      SafeSvgNetworkLoader(url),
      width: size,
      height: size,
      placeholderBuilder: (_) => placeholder ?? SizedBox.square(dimension: size),
    );
  }
}
