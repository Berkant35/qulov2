import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qulo_v2/core/widgets/crop_screen.dart';

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

class ImagePickerManager {
  ImagePickerManager._();
  static final ImagePickerManager instance = ImagePickerManager._();

  final ImagePicker _picker = ImagePicker();

  static const double _defaultMaxWidth = 1080;
  static const int _defaultImageQuality = 85;

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
    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
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

    if (croppedBytes == null) return null;

    return PickedImage(
      bytes: croppedBytes,
      mimeType: picked.mimeType,
      fileName: picked.fileName,
    );
  }
}
