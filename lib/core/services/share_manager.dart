import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';

/// [origin]: paylaşım sayfasının çıkış alanı — iOS'ta zorunlu, çağıran
/// `shareOriginFor(context)` ile verir (bkz. `core/utils/share_origin.dart`).
class ShareManager {
  ShareManager._();
  static final ShareManager instance = ShareManager._();

  Future<void> share(String text, {String? subject, Rect? origin}) async {
    await Share.share(text, subject: subject, sharePositionOrigin: origin);
  }

  Future<void> shareFiles(
    List<XFile> files, {
    String? text,
    String? subject,
    Rect? origin,
  }) async {
    await Share.shareXFiles(
      files,
      text: text,
      subject: subject,
      sharePositionOrigin: origin,
    );
  }
}
