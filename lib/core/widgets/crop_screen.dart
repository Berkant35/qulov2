import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/crop_screen_mixin.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

// Raw Scaffold bilerek: full-bleed kırpma editörü (CLAUDE.md Scaffold istisnası).
class _CropScreenState extends State<CropScreen> with CropScreenMixin {
  /// 3:4 dikey kırpma (flört uygulaması standardı).
  static const _aspectRatio = 3 / 4;
  static const _initialCropSize = 0.85;
  static const _maskAlpha = 0.78;

  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        foregroundColor: context.appColors.textPrimary,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: cancel),
        actions: [
          IconButton(
            icon: isRotating
                ? const AppLoadingWidget.small()
                : const Icon(Icons.rotate_right),
            tooltip: context.tr('rotate'),
            onPressed: canRotate && hasValidImage ? rotate : null,
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: canConfirm ? confirm : null,
              child: isCropping
                  ? const AppLoadingWidget.small()
                  : Text(
                      context.tr('ok'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.appColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      // 3:4 portrait crop (dating-app standard). The avatar widgets clip
      // the rectangle into a circle at render time (ClipOval), so the user
      // still sees a circular profile photo — but the stored image keeps
      // more vertical context (hair, shoulders) for card / detail views.
      // Geçersiz bayt editöre verilmez (ayrıştırıcı isolate'te çöküyor); ekran
      // ilk karede kapanır.
      body: !hasValidImage
          ? const SizedBox.shrink()
          : Crop(
              controller: cropController,
              image: currentImageBytes,
              aspectRatio: _aspectRatio,
              baseColor: context.appColors.background,
              maskColor: context.appColors.background.withValues(alpha: _maskAlpha),
              cornerDotBuilder: (size, edgeAlignment) =>
                  const SizedBox.shrink(),
              onCropped: onCropped,
              onStatusChanged: onCropStatusChanged,
              progressIndicator: const Center(child: AppLoadingWidget.large()),
              initialSize: _initialCropSize,
              interactive: true,
            ),
    );
  }
}
