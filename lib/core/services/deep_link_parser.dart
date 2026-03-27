import 'dart:developer' as dev;

enum DeepLinkNavType { go, push }

class DeepLinkResult {
  final String goRouterPath;
  final bool requiresAuth;
  final DeepLinkNavType navType;

  const DeepLinkResult({
    required this.goRouterPath,
    required this.requiresAuth,
    required this.navType,
  });

  @override
  String toString() =>
      'DeepLinkResult(path: $goRouterPath, auth: $requiresAuth, nav: $navType)';
}

abstract class DeepLinkParser {
  static const _validHosts = {'quloapp.com', 'www.quloapp.com'};

  /// URI'yi parse eder, desteklenen bir deep link ise DeepLinkResult doner.
  /// Desteklenmiyorsa veya gecersizse null doner.
  static DeepLinkResult? parse(Uri uri) {
    // Host validation
    if (uri.host.isEmpty || !_validHosts.contains(uri.host)) {
      dev.log('[DeepLinkParser] Invalid host: "${uri.host}"', name: 'DeepLink');
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.isEmpty || segments.any((s) => s == '..' || s == '.')) {
      return null;
    }

    final path = uri.path;

    // /invite/:code
    if (segments.first == 'invite' && segments.length == 2) {
      return DeepLinkResult(
        goRouterPath: '/invite/${segments[1]}',
        requiresAuth: false,
        navType: DeepLinkNavType.go,
      );
    }

    // /chat/:matchId
    if (segments.first == 'chat' && segments.length == 2) {
      return DeepLinkResult(
        goRouterPath: '/chat/${segments[1]}',
        requiresAuth: true,
        navType: DeepLinkNavType.push,
      );
    }

    // /matches
    if (path == '/matches') {
      return const DeepLinkResult(
        goRouterPath: '/matches',
        requiresAuth: true,
        navType: DeepLinkNavType.go,
      );
    }

    // /discover
    if (path == '/discover') {
      return const DeepLinkResult(
        goRouterPath: '/discover',
        requiresAuth: true,
        navType: DeepLinkNavType.go,
      );
    }

    // /profile/:userId → /profile-detail/:userId
    if (segments.first == 'profile' && segments.length == 2) {
      final secondSegment = segments[1];
      // subscription ve passport ayri handle edilir
      if (secondSegment == 'subscription') {
        return const DeepLinkResult(
          goRouterPath: '/profile/subscription',
          requiresAuth: true,
          navType: DeepLinkNavType.go,
        );
      }
      if (secondSegment == 'passport') {
        return const DeepLinkResult(
          goRouterPath: '/profile/passport',
          requiresAuth: true,
          navType: DeepLinkNavType.go,
        );
      }
      // Diger /profile/:userId → profil detay
      return DeepLinkResult(
        goRouterPath: '/profile-detail/$secondSegment',
        requiresAuth: true,
        navType: DeepLinkNavType.push,
      );
    }

    dev.log('[DeepLinkParser] Unsupported path: $path', name: 'DeepLink');
    return null;
  }

  /// Bildirim action_url'ini (ör. "/chat/abc123") parse eder.
  /// Host doğrulaması yapmaz — sadece path üzerinden navType belirler.
  static DeepLinkNavType resolveNavType(String actionUrl) {
    final uri = Uri.tryParse(actionUrl);
    if (uri == null || uri.pathSegments.isEmpty) return DeepLinkNavType.go;

    final first = uri.pathSegments.first;

    // push gerektiren route'lar
    if (first == 'chat' || first == 'profile-detail') {
      return DeepLinkNavType.push;
    }

    return DeepLinkNavType.go;
  }
}
