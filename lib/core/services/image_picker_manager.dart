import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qulo_v2/core/utils/image_bytes.dart';
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

/// Seçici bir dosya döndürdü ama görsel olarak açılamıyor (0 bayt ya da
/// çözülemeyen içerik). Çağıran "başka fotoğraf seç" mesajı gösterir.
class ImagePickerInvalidImageException implements Exception {
  final ImageSource source;

  /// `empty` (0 bayt) ya da `undecodable` — analitik için.
  final String reason;
  const ImagePickerInvalidImageException(this.source, {required this.reason});

  static const String reasonEmpty = 'empty';
  static const String reasonUndecodable = 'undecodable';
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
    // iOS image_picker kodlama başarısızsa 0 baytlık dosya yolu döndürebiliyor.
    if (bytes.isEmpty) {
      throw ImagePickerInvalidImageException(
        source,
        reason: ImagePickerInvalidImageException.reasonEmpty,
      );
    }
    final mimeType = xFile.mimeType ?? 'image/jpeg';
    final fileName = xFile.name;

    return PickedImage(bytes: bytes, mimeType: mimeType, fileName: fileName);
  }

  Future<PickedImage?> pickAndCropFromCamera(BuildContext context) =>
      pickAndCrop(context, ImageSource.camera);

  Future<PickedImage?> pickAndCropFromGallery(BuildContext context) =>
      pickAndCrop(context, ImageSource.gallery);

  Future<PickedImage?> pickAndCrop(
    BuildContext context,
    ImageSource source, {
    double maxWidth = _defaultMaxWidth,
    int imageQuality = _defaultImageQuality,
  }) async {
    final picked = await _pick(source, maxWidth: maxWidth, imageQuality: imageQuality);
    if (picked == null) return null;

    // Kırpma ekranına girmeden tam çözümleme: `crop_your_image` bozuk baytı
    // isolate'te yakalanmamış hatayla düşürüyor.
    if (!await ImageBytes.validate(picked.bytes)) {
      throw ImagePickerInvalidImageException(
        source,
        reason: ImagePickerInvalidImageException.reasonUndecodable,
      );
    }
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
