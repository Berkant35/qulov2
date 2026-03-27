import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/fullscreen_photo_viewer.dart';

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

    final heroTag = 'reward_${widget.mediaUrl}';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FullscreenPhotoViewer(
              imageUrl: widget.mediaUrl,
              heroTag: heroTag,
            ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: AnimatedBuilder(
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: CachedNetworkImage(
              imageUrl: widget.mediaUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder: (ctx, __) => Container(
                height: 200,
                color: context.appColors.surfaceElevated,
                child: const Center(child: AppLoadingWidget.small()),
              ),
              errorWidget: (ctx, __, ___) => Container(
                height: 200,
                color: context.appColors.surfaceElevated,
                child: Icon(Icons.broken_image,
                    color: context.appColors.textHint),
              ),
            ),
          ),
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
          color: context.appColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: context.appColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.audiotrack_rounded,
                size: 40,
                color: context.appColors.primary,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Ses Ödülü Açıldı!',
                style: TextStyle(
                  color: context.appColors.primary,
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
