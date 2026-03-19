import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

enum PowerType {
  oracle(QIcons.icOracle, 'ORACLE'),
  half(QIcons.icSplit, 'HALF'),
  skip(QIcons.icSkipForward, 'SKIP'),
  skipAll(QIcons.icFastForward, 'SKIP_ALL'),
  timeExtend(QIcons.icClock, 'TIME_EXTEND'),
  hint(QIcons.icLightbulb, 'HINT');

  final String iconPath;
  final String apiName;
  const PowerType(this.iconPath, this.apiName);

  Color get color => switch (this) {
    PowerType.oracle => AppColors.primaryDark,
    PowerType.half => AppColors.error,
    PowerType.skip => AppColors.info,
    PowerType.skipAll => AppColors.primary,
    PowerType.timeExtend => AppColors.success,
    PowerType.hint => AppColors.warning,
  };

  static PowerType fromApiName(String name) {
    return PowerType.values.firstWhere((p) => p.apiName == name);
  }
}

class PowerIcon extends StatelessWidget {
  final PowerType type;
  final double size;
  final bool showCount;
  final int? count;

  const PowerIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.showCount = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final icon = QIcon(type.iconPath, size: size, color: type.color);

    if (!showCount || count == null || count! <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: type.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '×$count',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
