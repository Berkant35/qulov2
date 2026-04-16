import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qulo_v2/core/widgets/crop_screen.dart';

export 'package:image_picker/image_picker.dart' show ImageSource;

class PickedImage {
  final Uint8List bytes;
  final String mimeType;
  final String fileName;

  const PickedImage({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });
}

/// Thrown when the OS denies camera/photo access so callers can prompt the
/// user to enable the permission from app settings.
class ImagePickerPermissionException implements Exception {
  final ImageSource source;
  const ImagePickerPermissionException(this.source);

  bool get isCamera => source == ImageSource.camera;
}

class ImagePickerManager {
  ImagePickerManager._();
  static final ImagePickerManager instance = ImagePickerManager._();

  final ImagePicker _picker = ImagePicker();

  static const double _defaultMaxWidth = 1080;
  static const int _defaultImageQuality = 85;

  /// Opens the OS-level app settings page so the user can grant
  /// previously-denied permissions (camera, photos, etc.).
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<PickedImage?> pickFromGallery({
    double maxWidth = _defaultMaxWidth,
    int imageQuality = _defaultImageQuality,
  }) {
    return _pick(ImageSource.gallery, maxWidth: maxWidth, imageQuality: imageQuality);
  }

  Future<PickedImage?> pickFromCamera({
    double maxWidth = _defaultMaxWidth,
    int imageQuality = _defaultImageQuality,
  }) {
    return _pick(ImageSource.camera, maxWidth: maxWidth, imageQuality: imageQuality);
  }

  Future<PickedImage?> _pick(
    ImageSource source, {
    required double maxWidth,
    required int imageQuality,
  }) async {
    final XFile? xFile;
    try {
      xFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        imageQuality: imageQuality,
      );
    } on PlatformException catch (e) {
      // iOS: `camera_access_denied`, `photo_access_denied`.
      // Android: `camera_access_denied`, `photo_access_denied` (image_picker).
      if (e.code == 'camera_access_denied' ||
          e.code == 'photo_access_denied') {
        throw ImagePickerPermissionException(source);
      }
      rethrow;
    }
    if (xFile == null) return null;

    final bytes = await xFile.readAsBytes();
    final mimeType = xFile.mimeType ?? 'image/jpeg';
    final fileName = xFile.name;

    return PickedImage(bytes: bytes, mimeType: mimeType, fileName: fileName);
  }

  Future<PickedImage?> pickAndCrop(
    BuildContext context,
    ImageSource source, {
    double maxWidth = _defaultMaxWidth,
    int imageQuality = _defaultImageQuality,
  }) async {
    final picked = await _pick(source, maxWidth: maxWidth, imageQuality: imageQuality);
    if (picked == null) return null;

    if (!context.mounted) return null;

    final croppedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CropScreen(imageBytes: picked.bytes),
      ),
    );

    if (!context.mounted || croppedBytes == null) return null;

    return PickedImage(
      bytes: croppedBytes,
      mimeType: picked.mimeType,
      fileName: picked.fileName,
    );
  }
}
