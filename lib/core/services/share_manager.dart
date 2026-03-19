import 'package:share_plus/share_plus.dart';

class ShareManager {
  ShareManager._();
  static final ShareManager instance = ShareManager._();

  Future<void> share(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  Future<void> shareFiles(
    List<XFile> files, {
    String? text,
    String? subject,
  }) async {
    await Share.shareXFiles(files, text: text, subject: subject);
  }
}
