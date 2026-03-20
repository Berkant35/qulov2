import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class RewardMediaReveal extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;

  const RewardMediaReveal({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
  });

  @override
  State<RewardMediaReveal> createState() => _RewardMediaRevealState();
}

class _RewardMediaRevealState extends State<RewardMediaReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _blurAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Start reveal after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaType == 'audio') {
      return _AudioReveal(controller: _controller);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: _blurAnimation.value,
                sigmaY: _blurAnimation.value,
              ),
              child: child,
            ),
          ),
        );
      },
      child: CachedNetworkImage(
        imageUrl: widget.mediaUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (ctx, __) => Container(
          height: 200,
          color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
          child: const Center(child: AppLoadingWidget.small()),
        ),
        errorWidget: (ctx, __, ___) => Container(
          height: 200,
          color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.broken_image, color: context.appColors.textHint),
        ),
      ),
    );
  }
}

class _AudioReveal extends StatelessWidget {
  final AnimationController controller;

  const _AudioReveal({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + (controller.value * 0.5),
          child: Opacity(
            opacity: controller.value,
            child: child,
          ),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.audiotrack_rounded,
                size: 40,
                color: AppColors.primary,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Ses Ödülü Açıldı!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
