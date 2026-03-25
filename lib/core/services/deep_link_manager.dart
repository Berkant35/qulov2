import 'dart:async';
import 'dart:developer' as dev;

import 'package:app_links/app_links.dart';

class DeepLinkManager {
  DeepLinkManager._();
  static final DeepLinkManager instance = DeepLinkManager._();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _appLinks = AppLinks();
    _initialized = true;
    dev.log('[DeepLinkManager] Initialized', name: 'DeepLink');
  }

  Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (e) {
      dev.log('[DeepLinkManager] getInitialLink error: $e', name: 'DeepLink');
      return null;
    }
  }

  void listen(void Function(Uri uri) onLink) {
    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      onLink,
      onError: (error) {
        dev.log('[DeepLinkManager] Stream error: $error', name: 'DeepLink');
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    dev.log('[DeepLinkManager] Disposed', name: 'DeepLink');
  }
}
