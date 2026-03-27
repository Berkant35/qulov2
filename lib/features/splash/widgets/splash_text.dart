import 'package:flutter/material.dart';

class SplashText extends StatelessWidget {
  final Animation<double> animation;

  static const _text = 'QULO';
  static const _letterSpacing = 8.0;

  const SplashText({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_text.length, (i) {
            final stagger = i / _text.length;
            final letterProgress =
                ((animation.value - stagger * 0.4) / 0.6).clamp(0.0, 1.0);

            final opacity = Curves.easeOut.transform(letterProgress);
            final slideY = 12.0 * (1.0 - Curves.easeOutCubic.transform(letterProgress));

            return Transform.translate(
              offset: Offset(0, slideY),
              child: Opacity(
                opacity: opacity,
                child: Text(
                  _text[i],
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: _letterSpacing,
                      ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
