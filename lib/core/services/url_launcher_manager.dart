import 'package:url_launcher/url_launcher.dart';

class UrlLauncherManager {
  UrlLauncherManager._();
  static final UrlLauncherManager instance = UrlLauncherManager._();

  static const _allowedSchemes = {'http', 'https', 'mailto', 'tel', 'sms'};

  Future<bool> launch(String url, {LaunchMode mode = LaunchMode.externalApplication}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      return false;
    }
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: mode);
    }
    return false;
  }
}
