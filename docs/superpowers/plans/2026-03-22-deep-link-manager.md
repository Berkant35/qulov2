# Deep Link Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** OS-level deep link yakalama, parse etme, auth-aware yonlendirme ve chat bildirim bug fix.

**Architecture:** `app_links` paketi ile OS deep link'lerini yakalar → `DeepLinkParser` URI'yi GoRouter path'e cevirir → auth durumuna gore ya hemen navigate eder ya da `pendingDeepLinkProvider`'a kaydedip login sonrasi replay eder. Mevcut `NavigationService`'e `navigateDeepLink()` metodu eklenir.

**Tech Stack:** Flutter, Riverpod, GoRouter, app_links, Firebase Analytics

**Spec:** `docs/superpowers/specs/2026-03-22-deep-link-manager-design.md`

---

## Task 1: Server — Chat Notification action_url Bug Fix

**Files:**
- Modify: `qulo-server/src/services/chat.service.ts:153-155`
- Modify: `qulo-server/src/services/chat-question.service.ts:270-272, 414`
- Modify: `qulo-server/src/services/media.service.ts:92-94, 156-158`

- [ ] **Step 1: Fix chat.service.ts**

Line 154 — degistir:
```typescript
// ONCE:
actionUrl: `/matches/chat/${match.id}`,
// SONRA:
actionUrl: `/chat/${match.id}`,
```

- [ ] **Step 2: Fix chat-question.service.ts**

Line 271 — degistir:
```typescript
// ONCE:
actionUrl: `/matches/chat/${matchId}`,
// SONRA:
actionUrl: `/chat/${matchId}`,
```

Line 414 — degistir:
```typescript
// ONCE:
{ actionUrl: `/matches/chat/${question.match_id}` },
// SONRA:
{ actionUrl: `/chat/${question.match_id}` },
```

- [ ] **Step 3: Fix media.service.ts**

Line 93 — degistir:
```typescript
// ONCE:
actionUrl: `/matches/chat/${match.id}`,
// SONRA:
actionUrl: `/chat/${match.id}`,
```

Line 157 — degistir:
```typescript
// ONCE:
actionUrl: `/matches/chat/${match.id}`,
// SONRA:
actionUrl: `/chat/${match.id}`,
```

- [ ] **Step 4: Dogrulama**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npx tsc --noEmit`
Expected: 0 error

- [ ] **Step 5: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git add src/services/chat.service.ts src/services/chat-question.service.ts src/services/media.service.ts
git commit -m "fix: chat notification action_url path — /matches/chat/ → /chat/"
```

---

## Task 2: Flutter — app_links Paketi + iOS Config

**Files:**
- Modify: `pubspec.yaml` — app_links dependency ekle
- Modify: `ios/Runner/Info.plist` — FlutterDeepLinkingEnabled: NO

- [ ] **Step 1: app_links paketini ekle**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter pub add app_links`

- [ ] **Step 2: iOS Info.plist — GoRouter built-in deep link handler'i devre disi birak**

`ios/Runner/Info.plist` dosyasinda `</dict>` kapanisından hemen once ekle:

```xml
<key>FlutterDeepLinkingEnabled</key>
<false/>
```

- [ ] **Step 3: Dogrulama**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter pub get`
Expected: 0 error

- [ ] **Step 4: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist
git commit -m "chore: add app_links package, disable GoRouter built-in deep link handler"
```

---

## Task 3: DeepLinkParser — Pure Utility Class

**Files:**
- Create: `lib/core/services/deep_link_parser.dart`

- [ ] **Step 1: DeepLinkParser'i olustur**

```dart
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
    if (!_validHosts.contains(uri.host)) {
      dev.log('[DeepLinkParser] Invalid host: ${uri.host}', name: 'DeepLink');
      return null;
    }

    final path = uri.path;
    final segments = uri.pathSegments;

    if (segments.isEmpty) return null;

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
}
```

- [ ] **Step 2: Dogrulama**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/core/services/deep_link_parser.dart`
Expected: 0 issues

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/deep_link_parser.dart
git commit -m "feat: add DeepLinkParser — URI to GoRouter path mapper"
```

---

## Task 4: DeepLinkManager — OS Link Listener

**Files:**
- Create: `lib/core/services/deep_link_manager.dart`
- Modify: `lib/providers/api_provider.dart` — provider ekle

- [ ] **Step 1: DeepLinkManager'i olustur**

```dart
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

  /// Cold start'ta gelen ilk deep link URI'yi doner.
  /// Yoksa null doner.
  Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (e) {
      dev.log('[DeepLinkManager] getInitialLink error: $e', name: 'DeepLink');
      return null;
    }
  }

  /// Foreground/background'da gelen deep link stream'ini dinler.
  /// Her yeni link geldiginde [onLink] callback'i cagrilir.
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
```

- [ ] **Step 2: Provider'i api_provider.dart'a ekle**

`lib/providers/api_provider.dart` dosyasinin sonuna ekle:

```dart
import 'package:qulo_v2/core/services/deep_link_manager.dart';

final deepLinkManagerProvider = Provider<DeepLinkManager>((ref) {
  final manager = DeepLinkManager.instance;
  ref.onDispose(() => manager.dispose());
  return manager;
});
```

- [ ] **Step 3: Dogrulama**

Run: `flutter analyze lib/core/services/deep_link_manager.dart lib/providers/api_provider.dart`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/core/services/deep_link_manager.dart lib/providers/api_provider.dart
git commit -m "feat: add DeepLinkManager — OS deep link listener with app_links"
```

---

## Task 5: pendingDeepLinkProvider + Analytics Events

**Files:**
- Create: `lib/providers/deep_link_provider.dart`
- Modify: `lib/core/services/analytics_manager.dart` — 5 yeni event metodu

- [ ] **Step 1: deep_link_provider.dart olustur**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auth olmayan kullanici icin deferred deep link saklama.
/// Deep link handler set eder, GoRouter redirect consume eder.
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);
```

- [ ] **Step 2: Analytics event'lerini ekle**

`lib/core/services/analytics_manager.dart` dosyasina, class'in sonuna (dispose/son metoddan once) su metodlari ekle:

```dart
// ── Deep Link Analytics ──────────────────────────────────────────

void logDeepLinkReceived(String uri, {required String source}) {
  logEvent('deep_link_received', params: {'uri': uri, 'source': source});
}

void logDeepLinkNavigated(String targetPath, String navType) {
  logEvent('deep_link_navigated', params: {
    'target_path': targetPath,
    'nav_type': navType,
  });
}

void logDeepLinkDeferred(String targetPath) {
  logEvent('deep_link_deferred', params: {'target_path': targetPath});
}

void logDeepLinkReplayed(String targetPath) {
  logEvent('deep_link_replayed', params: {'target_path': targetPath});
}

void logDeepLinkInvalid(String uri, String reason) {
  logEvent('deep_link_invalid', params: {'uri': uri, 'reason': reason});
}
```

- [ ] **Step 3: Dogrulama**

Run: `flutter analyze lib/providers/deep_link_provider.dart lib/core/services/analytics_manager.dart`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/providers/deep_link_provider.dart lib/core/services/analytics_manager.dart
git commit -m "feat: add pendingDeepLinkProvider + deep link analytics events"
```

---

## Task 6: NavigationService — navigateDeepLink() Metodu

**Files:**
- Modify: `lib/core/navigation/navigation_service.dart:127-134`

- [ ] **Step 1: Import ekle**

Dosyanin basina ekle:
```dart
import 'package:qulo_v2/core/services/deep_link_parser.dart';
```

- [ ] **Step 2: Mevcut handleDeepLink'i koru, yeni metod ekle**

`handleDeepLink` metodu (satir ~129) sonrasina yeni metod ekle:

```dart
/// Deep link parse sonucuna gore navigate eder.
/// go: bottom nav / shell route tab switch icin.
/// push: full-screen overlay route'lar icin (chat, profil detay).
void navigateDeepLink(DeepLinkResult result) {
  if (result.navType == DeepLinkNavType.go) {
    _router.go(result.goRouterPath);
  } else {
    _router.push(result.goRouterPath);
  }

  final eventType = result.navType == DeepLinkNavType.go
      ? NavigationType.go
      : NavigationType.push;
  for (final observer in _observers) {
    observer.onNavigate(
      NavigationEvent(
        routeName: result.goRouterPath,
        type: eventType,
        timestamp: DateTime.now(),
      ),
    );
  }
}
```

- [ ] **Step 3: Dogrulama**

Run: `flutter analyze lib/core/navigation/navigation_service.dart`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/core/navigation/navigation_service.dart
git commit -m "feat: add navigateDeepLink() to NavigationService"
```

---

## Task 7: GoRouter Redirect — pendingDeepLink Replay

**Files:**
- Modify: `lib/routing/app_router.dart:67-82`

- [ ] **Step 1: Import'lari ekle**

Dosyanin basina (mevcut import'larin sonuna) ekle:
```dart
import 'package:qulo_v2/providers/deep_link_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';
```

- [ ] **Step 2: Redirect fonksiyonunu tamamen yeniden yaz**

Mevcut redirect blogu (satir 67-82) TAMAMEN asagidakiyle degistirilir.
Kritik sira: pendingDeepLink replay, `isAuth && (isAuthRoute || isSplash)` kontrolunden ONCE gelmeli.
Yoksa login sonrasi redirect `/discover`'a gider ve pending link kaybolur.

```dart
redirect: (context, state) {
  final authState = ref.read(authProvider);
  final isAuth = authState.status == AuthStatus.authenticated;
  final isAuthRoute = state.matchedLocation.startsWith('/auth');
  final isSplash = state.matchedLocation == '/';

  // 1. Auth yukleniyor — bekle
  if (authState.status == AuthStatus.initial) return null;

  // 2. Update/maintenance route'lari — her zaman izin ver
  final isUpdateRoute = state.matchedLocation == '/force-update' ||
      state.matchedLocation == '/maintenance';
  if (isUpdateRoute) return null;

  // 3. Invite route — mevcut logic
  final isInviteRoute = state.matchedLocation.startsWith('/invite/');
  if (isAuth && isInviteRoute) return '/discover';

  // 4. Auth degil → login'e yonlendir (auth, invite, update haric)
  if (!isAuth && !isAuthRoute && !isInviteRoute && !isUpdateRoute) {
    return '/auth/login';
  }

  // 5. YENI: Pending deep link replay — login sonrasi deferred link
  final pendingLink = ref.read(pendingDeepLinkProvider);
  if (isAuth && pendingLink != null) {
    ref.read(pendingDeepLinkProvider.notifier).state = null;
    // Analytics: deep_link_replayed
    ref.read(analyticsManagerProvider).logDeepLinkReplayed(pendingLink);
    return pendingLink;
  }

  // 6. Auth + auth route veya splash → discover'a yonlendir
  if (isAuth && (isAuthRoute || isSplash)) return '/discover';

  return null;
},
```

**Onemli:** Bu redirect'in calismasi icin 2 ek import gerekir (Step 1'de eklendi).

- [ ] **Step 3: Dogrulama**

Run: `flutter analyze lib/routing/app_router.dart`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/routing/app_router.dart
git commit -m "feat: add pendingDeepLink replay to GoRouter redirect"
```

---

## Task 8: app.dart — Deep Link Init + Stream Listener

**Files:**
- Modify: `lib/app.dart`

Bu en kritik task — tum parcalari birlestiriyor.

- [ ] **Step 1: Import'lari ekle**

`lib/app.dart` basina su import'lari ekle (zaten olanlari DUPLICATE ETME):
```dart
import 'package:qulo_v2/core/services/deep_link_parser.dart';
import 'package:qulo_v2/providers/deep_link_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
```

NOT: `api_provider.dart` zaten import edilmis (deepLinkManagerProvider ve analyticsManagerProvider burada). `auth_provider.dart` MUTLAKA eklenmeli — `_handleDeepLink` icinde `authProvider` ve `AuthStatus` kullanilir.

- [ ] **Step 2: initState'e DeepLinkManager init ekle**

`initState()` icinde (mevcut `WidgetsBinding.instance.addPostFrameCallback` blogu icinde, `_setupNotificationCallbacks()` satirindan sonra) ekle:

```dart
_setupDeepLinks();
```

- [ ] **Step 3: _setupDeepLinks metodu yaz**

`_setupNotificationCallbacks()` metodundan sonra yeni metod ekle:

```dart
void _setupDeepLinks() {
  final deepLinkManager = ref.read(deepLinkManagerProvider);
  final analytics = ref.read(analyticsManagerProvider);
  deepLinkManager.init();

  // Cold start — ilk link
  deepLinkManager.getInitialLink().then((uri) {
    if (uri != null) {
      analytics.logDeepLinkReceived(uri.toString(), source: 'initial');
      _handleDeepLink(uri);
    }
  });

  // Foreground/background — stream
  deepLinkManager.listen((uri) {
    analytics.logDeepLinkReceived(uri.toString(), source: 'stream');
    _handleDeepLink(uri);
  });
}

void _handleDeepLink(Uri uri) {
  final result = DeepLinkParser.parse(uri);
  final analytics = ref.read(analyticsManagerProvider);

  if (result == null) {
    analytics.logDeepLinkInvalid(uri.toString(), 'unsupported_path');
    return;
  }

  final authState = ref.read(authProvider);
  final isAuth = authState.status == AuthStatus.authenticated;

  if (result.requiresAuth && !isAuth) {
    // Deferred deep link — login sonrasi replay edilecek
    ref.read(pendingDeepLinkProvider.notifier).state = result.goRouterPath;
    analytics.logDeepLinkDeferred(result.goRouterPath);
    return;
  }

  // Hemen navigate et
  ref.read(navigationServiceProvider).navigateDeepLink(result);
  analytics.logDeepLinkNavigated(
    result.goRouterPath,
    result.navType.name,
  );
}
```

- [ ] **Step 4: Dogrulama**

Run: `flutter analyze lib/app.dart`
Expected: 0 issues

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart
git commit -m "feat: integrate DeepLinkManager in app.dart — cold start + stream handling"
```

---

## Task 9: Son Dogrulama

- [ ] **Step 1: Tam flutter analyze**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: 0 issues (veya sadece onceden bilinen hatalar: PurchasePackage + profile_screen_mixin)

- [ ] **Step 2: Server dogrulama**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npx tsc --noEmit`
Expected: 0 errors

- [ ] **Step 3: Deep link path mapping dogrulama**

Su path'lerin GoRouter'da karsiligini kontrol et:
- `/invite/:code` → `app_routes.dart` icinde `/invite/:code` route VAR ✓
- `/chat/:matchId` → `app_routes.dart` icinde `/chat/:matchId` route VAR ✓
- `/matches` → `app_routes.dart` icinde `/matches` (StatefulShellRoute branch) VAR ✓
- `/discover` → `app_routes.dart` icinde `/discover` (StatefulShellRoute branch) VAR ✓
- `/profile-detail/:userId` → `app_routes.dart` icinde `/profile-detail/:userId` route VAR ✓
- `/profile/subscription` → `app_routes.dart` icinde `/profile` → `subscription` sub-route VAR ✓
- `/profile/passport` → `app_routes.dart` icinde `/profile` → `passport` sub-route VAR ✓

- [ ] **Step 4: Final commit (gerekirse)**

```bash
git add -A
git commit -m "feat: deep link manager — complete implementation"
```

---

## Dosya Ozeti

| Dosya | Islem | Task |
|-------|-------|------|
| `qulo-server/.../chat.service.ts` | Modify: action_url fix | 1 |
| `qulo-server/.../chat-question.service.ts` | Modify: action_url fix | 1 |
| `qulo-server/.../media.service.ts` | Modify: action_url fix | 1 |
| `pubspec.yaml` | Modify: app_links dependency | 2 |
| `ios/Runner/Info.plist` | Modify: FlutterDeepLinkingEnabled | 2 |
| `lib/core/services/deep_link_parser.dart` | Create: URI parser | 3 |
| `lib/core/services/deep_link_manager.dart` | Create: OS link listener | 4 |
| `lib/providers/api_provider.dart` | Modify: provider ekle | 4 |
| `lib/providers/deep_link_provider.dart` | Create: pending state | 5 |
| `lib/core/services/analytics_manager.dart` | Modify: 5 event | 5 |
| `lib/core/navigation/navigation_service.dart` | Modify: navigateDeepLink() | 6 |
| `lib/routing/app_router.dart` | Modify: redirect replay | 7 |
| `lib/app.dart` | Modify: init + handler | 8 |
