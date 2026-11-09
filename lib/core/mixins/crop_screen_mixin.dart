import 'dart:async';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/utils/image_bytes.dart';
import 'package:qulo_v2/core/widgets/crop_screen.dart';
import 'package:qulo_v2/core/widgets/image_picker_permission_dialog.dart';

/// [CropScreen] logic'i: bayt doğrulama, döndürme, kırpma.
///
/// Crashlytics iOS 2.0.17: 0 baytlık görsel `crop_your_image` ayrıştırıcısında
/// `RangeError` attı, editör "yükleniyor"da kaldı; kullanıcı "Tamam"a basınca
/// `_CropEditorState._crop` `_parsedImageDetail!` ile düştü. Bu yüzden:
/// - geçersiz bayt editöre hiç verilmez (ekran kapanır + "başka fotoğraf seç"),
/// - "Tamam" yalnız editör `ready` iken açıktır,
/// - kırpma ve döndürme hataları yakalanıp mesaja çevrilir.
mixin CropScreenMixin on State<CropScreen> {
  final cropController = CropController();
  late Uint8List currentImageBytes;
  bool isEditorReady = false;
  bool isCropping = false;
  bool isRotating = false;

  bool get canConfirm => isEditorReady && !isCropping && !isRotating;
  bool get canRotate => !isCropping && !isRotating;

  /// Editöre verilecek bayt geçerli mi (geçersizse ekran ilk karede kapanır).
  /// Bir kez hesaplanır; döndürme yalnız geçerli JPEG üretir.
  late final bool hasValidImage;

  void initMixin() {
    currentImageBytes = widget.imageBytes;
    hasValidImage = ImageBytes.looksLikeImage(currentImageBytes);
    if (!hasValidImage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _rejectInvalid());
    }
  }

  void onCropStatusChanged(CropStatus status) {
    if (!mounted) return;
    final ready = status == CropStatus.ready;
    if (ready != isEditorReady) setState(() => isEditorReady = ready);
  }

  Future<void> rotate() async {
    if (!canRotate) return;
    setState(() => isRotating = true);
    final rotated = await compute(ImageBytes.rotate90, currentImageBytes);
    if (!mounted) return;
    if (rotated == null) {
      setState(() => isRotating = false);
      showInvalidImageMessage(context);
      return;
    }
    setState(() {
      currentImageBytes = rotated;
      isRotating = false;
      isEditorReady = false;
    });
    cropController.image = rotated;
  }

  /// `CropController.crop()` sonucu dönmez; paket içi `_crop` hatası bölgeye
  /// düşer. Bölge onu yakalar → çökme yerine mesaj, ekran açık kalır.
  ///
  /// crop() 3:4 dikey dikdörtgen üretir; avatarlar çizimde ClipOval ile
  /// yuvarlanır, kart / keşfet / detay tam dikdörtgeni gösterir.
  void confirm() {
    if (!canConfirm) return;
    setState(() => isCropping = true);
    runZonedGuarded(cropController.crop, (error, stack) {
      AnalyticsManager.instance.logNonFatalError(
        error,
        stack,
        context: 'CropScreen.confirm',
      );
      if (!mounted) return;
      setState(() => isCropping = false);
      showInvalidImageMessage(context);
    });
  }

  void onCropped(Uint8List croppedBytes) {
    if (mounted) Navigator.of(context).pop(croppedBytes);
  }

  void cancel() => Navigator.of(context).pop(null);

  void _rejectInvalid() {
    if (!mounted) return;
    showInvalidImageMessage(context);
    Navigator.of(context).pop(null);
  }
}
