import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _cropController = CropController();
  bool _isCropping = false;
  bool _isRotating = false;
  late Uint8List _currentImageBytes;

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.imageBytes;
  }

  Future<void> _rotate() async {
    if (_isRotating) return;
    setState(() => _isRotating = true);

    final rotated = await compute(_rotateImage90, _currentImageBytes);
    if (rotated != null && mounted) {
      setState(() {
        _currentImageBytes = rotated;
        _isRotating = false;
      });
      _cropController.image = rotated;
    } else if (mounted) {
      setState(() => _isRotating = false);
    }
  }

  /// Rotate image bytes 90 degrees clockwise (runs in isolate via compute).
  static Uint8List? _rotateImage90(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final rotated = img.copyRotate(decoded, angle: 90);
    return img.encodeJpg(rotated, quality: 90);
  }

  void _confirm() {
    setState(() => _isCropping = true);
    // Use crop() instead of cropCircle() to get a square output.
    // withCircleUi on the Crop widget is visual-only (circle overlay guide).
    _cropController.crop();
  }

  void _onCropped(Uint8List croppedBytes) {
    if (mounted) {
      Navigator.of(context).pop(croppedBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        foregroundColor: context.appColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          IconButton(
            icon: _isRotating
                ? const AppLoadingWidget.small()
                : const Icon(Icons.rotate_right),
            tooltip: context.tr('rotate'),
            onPressed: (_isCropping || _isRotating) ? null : _rotate,
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _isCropping ? null : _confirm,
              child: _isCropping
                  ? const AppLoadingWidget.small()
                  : Text(
                      context.tr('ok'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Crop(
        controller: _cropController,
        image: _currentImageBytes,
        aspectRatio: 1,
        withCircleUi: true,
        baseColor: context.appColors.background,
        maskColor: context.appColors.background.withValues(alpha: 0.78),
        cornerDotBuilder: (size, edgeAlignment) => const SizedBox.shrink(),
        onCropped: _onCropped,
        initialSize: 0.8,
        interactive: true,
      ),
    );
  }
}
