import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Seçilen fotoğrafın baytları için saf yardımcılar (kırpma akışı).
///
/// `image` paketi bozuk girdide `null` dönmek yerine istisna atar: 0 baytlık
/// dosyada format tespiti (`PngDecoder.isValidFile`) `RangeError` fırlatır.
/// iOS'ta `image_picker_ios` 0.8.13+3, JPEG/PNG kodlaması `nil` dönerse
/// `createFileAtPath:contents:nil` ile BOŞ dosya yazıp yolunu yine döndürüyor
/// (`FLTImagePickerPhotoAssetUtil.createFile`); bu baytlar `crop_your_image`
/// ayrıştırıcısına ulaşınca isolate'te yakalanmamış hata (fatal) oluyordu.
abstract final class ImageBytes {
  /// Başlık düzeyinde hızlı kontrol (senkron, ekranda kullanılır): boş değil ve
  /// bilinen bir görsel formatı.
  static bool looksLikeImage(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    try {
      return img.findDecoderForData(bytes) != null;
    } catch (_) {
      return false;
    }
  }

  /// Tam çözümleme kontrolü — `crop_your_image` ile aynı çözücü (`decodeImage`).
  /// Ağır iş: [validate] ile isolate'te çalışır.
  static bool canDecode(Uint8List bytes) {
    if (!looksLikeImage(bytes)) return false;
    try {
      final decoded = img.decodeImage(bytes);
      return decoded != null && decoded.width > 0 && decoded.height > 0;
    } catch (_) {
      return false;
    }
  }

  /// [canDecode]'u ana iş parçacığını kilitlemeden çalıştırır.
  static Future<bool> validate(Uint8List bytes) async {
    if (!looksLikeImage(bytes)) return false;
    try {
      return await compute(canDecode, bytes);
    } catch (_) {
      return false;
    }
  }

  /// Saat yönünde 90° döndürür; çözülemeyen girdide `null` (istisna atmaz).
  static Uint8List? rotate90(Uint8List bytes) {
    if (!looksLikeImage(bytes)) return null;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return img.encodeJpg(img.copyRotate(decoded, angle: 90), quality: 90);
    } catch (_) {
      return null;
    }
  }
}
