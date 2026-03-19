import 'package:flutter/material.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

class CircleIconButton extends StatelessWidget {
  final String iconPath;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final double size;
  final VoidCallback onTap;

  const CircleIconButton({
    super.key,
    required this.iconPath,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    this.size = 56,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [BoxShadow(color: borderColor.withValues(alpha: 0.2), blurRadius: 8)],
        ),
        child: Center(child: QIcon(iconPath, color: iconColor, size: size * 0.5)),
      ),
    );
  }
}
