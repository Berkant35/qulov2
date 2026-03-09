import 'package:url_launcher/url_launcher.dart';

class UrlLauncherManager {
  UrlLauncherManager._();
  static final UrlLauncherManager instance = UrlLauncherManager._();

  Future<bool> launch(String url, {LaunchMode mode = LaunchMode.externalApplication}) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: mode);
    }
    return false;
  }
}
