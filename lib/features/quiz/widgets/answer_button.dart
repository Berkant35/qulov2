import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class AnswerButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isOracleSuggested;

  const AnswerButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isDisabled = false,
    this.isOracleSuggested = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDisabled
                  ? Theme.of(context).colorScheme.outline
                  : AppColors.primary,
              width: isOracleSuggested ? 2.0 : 1.5,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color: isDisabled
                ? Theme.of(context).colorScheme.surfaceContainerHigh
                : Theme.of(context).colorScheme.surface,
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDisabled
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    if (!isOracleSuggested) return child;

    return _OraclePulseWrapper(child: child);
  }
}

class _OraclePulseWrapper extends StatefulWidget {
  final Widget child;
  const _OraclePulseWrapper({required this.child});

  @override
  State<_OraclePulseWrapper> createState() => _OraclePulseWrapperState();
}

class _OraclePulseWrapperState extends State<_OraclePulseWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3 + 0.4 * _animation.value),
                blurRadius: 8 + 8 * _animation.value,
                spreadRadius: 1 + 2 * _animation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
