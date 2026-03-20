import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class PassportBadge extends ConsumerStatefulWidget {
  const PassportBadge({super.key});

  @override
  ConsumerState<PassportBadge> createState() => _PassportBadgeState();
}

class _PassportBadgeState extends ConsumerState<PassportBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  int _pulseCount = 0;
  static const _maxPulses = 5;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener(_onAnimationStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restart glow on screen re-enter
    final isActive = ref.read(passportProvider).isActive;
    if (isActive && !_glowController.isAnimating) {
      _pulseCount = 0;
      _glowController.forward();
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _glowController.reverse();
    } else if (status == AnimationStatus.dismissed) {
      _pulseCount++;
      if (_pulseCount < _maxPulses) {
        _glowController.forward();
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passport = ref.watch(passportProvider);
    final location = ref.watch(locationProvider);
    final isActive = passport.isActive;
    final city = isActive ? passport.city : location.city;

    if (city == null || city.isEmpty) return const SizedBox.shrink();

    // Manage animation based on state
    if (isActive && !_glowController.isAnimating && _pulseCount < _maxPulses) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pulseCount = 0;
          _glowController.forward();
        }
      });
    } else if (!isActive && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.reset();
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () =>
            ref.read(navigationServiceProvider).push(RouteNames.passport),
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final theme = Theme.of(context);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primarySurface
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : context.appColors.border,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                              alpha: 0.4 * _glowController.value,
                            ),
                            spreadRadius: 4 * _glowController.value,
                            blurRadius: 8 * _glowController.value,
                          ),
                        ]
                      : null,
                ),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.flight : Icons.location_on,
                  size: 14,
                  color: isActive
                      ? AppColors.primary
                      : context.appColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  city,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isActive
                            ? AppColors.primary
                            : context.appColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
