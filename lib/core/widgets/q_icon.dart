import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;

  const QIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color;
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: iconColor != null
          ? ColorFilter.mode(iconColor, BlendMode.srcIn)
          : null,
    );
  }
}
