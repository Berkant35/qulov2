import 'dart:io' show HttpException;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show NetworkImageLoadException;

/// Yakalanmamış bir hatanın Crashlytics'e FATAL mı non-fatal mı yazılacağı.
///
/// Ağdan görsel yükleme hataları (404, DNS, kopan bağlantı) uygulamayı
/// çökertmez; fatal yazılınca 2.0.16'da crash-free oranını gerçek
/// crash'lerle karıştırıyordu. Kaydı sürer, yalnız non-fatal düşer.
abstract final class CrashClassifier {
  /// Flutter'ın görsel önbelleği hataları bu kütüphane adıyla bildirir.
  static const imageLibrary = 'image resource service';

  static bool isFatalFlutterError(FlutterErrorDetails details) =>
      details.library != imageLibrary && !isImageLoadError(details.exception);

  /// CachedNetworkImage / NetworkImage yükleme hataları: http
  /// `ClientException`, cache manager'ın `HttpExceptionWithStatus`'u
  /// (`HttpException` alt sınıfı) ve Flutter'ın `NetworkImageLoadException`'ı.
  static bool isImageLoadError(Object error) =>
      error is NetworkImageLoadException ||
      error is HttpException ||
      _isHttpClientException(error);

  /// `package:http` yalnız dev bağımlılığı (uygulamaya cache manager üzerinden
  /// geçişli gelir): tipe import'suz, paketin SABİT `toString` önekiyle bakılır
  /// (runtimeType adı değil — obfuscation'dan etkilenmez).
  static bool _isHttpClientException(Object error) =>
      error.toString().startsWith('ClientException');
}
