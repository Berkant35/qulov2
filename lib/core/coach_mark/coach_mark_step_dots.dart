import 'package:flutter/material.dart';

/// Tur kartındaki adım noktaları (tek adımlı turda çizilmez); etkin adım büyük ve vurgulu.
class CoachMarkStepDots extends StatelessWidget {
  const CoachMarkStepDots({
    super.key,
    required this.count,
    required this.index,
  });

  static const double _activeSize = 10;
  static const double _size = 6;
  static const double _gap = 3;

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return Container(
          width: active ? _activeSize : _size,
          height: active ? _activeSize : _size,
          margin: const EdgeInsets.symmetric(horizontal: _gap),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
        );
      }),
    );
  }
}
