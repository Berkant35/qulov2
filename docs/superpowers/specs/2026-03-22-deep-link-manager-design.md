# Deep Link Manager - Design Spec

**Date:** 2026-03-22
**Status:** Approved
**Scope:** MVP-B (notifications + marketing/campaign links)

---

## Problem

- OS-level deep link listener yok — Universal Links (iOS) ve App Links (Android) yakalanmiyor
- Chat notification action_url path mismatch: server `/matches/chat/{matchId}` gonderiyor, Flutter `/chat/{matchId}` bekliyor
- `go()` navigation stack'i siliyor — deep link ile gelen kullanici geri donemiyor
- Auth olmayan kullanicinin deep link'i kaybolur

## Decision Log

| Karar | Secim | Neden |
|-------|-------|-------|
| Deep link kapsami | MVP-B (bildirim + marketing) | Yeterli coverage, gereksiz route'lar disaride |
| Domain stratejisi | Sadece `quloapp.com` | Tek domain, web fallback otomatik, custom scheme gereksiz |
| Auth olmayan kullanici | Deferred deep link (login sonrasi replay) | En iyi UX, kullanici niyetini kaybetmez |
| Invalid content | Her ekran kendi error state'ini handle eder | SOLID — SRP, deep link manager'in isi sadece yonlendirmek |

## Architecture

```
OS Deep Link (Universal/App Links)
         |
    DeepLinkManager (core/services/)
         |
    URI Parse + Route Match (DeepLinkParser)
         |
    Auth Check --> Not Auth? --> pendingDeepLinkProvider --> Login
         |                                                    |
    NavigationService.navigateDeepLink()            Login basarili
         |                                                    |
    go() veya push() (route tipine gore)         pendingDeepLink replay
```

### Components

#### 1. DeepLinkManager (`lib/core/services/deep_link_manager.dart`)

Singleton manager, `app_links` paketi ile OS link'lerini yakalar.

**Responsibilities:**
- Cold start: `appLinks.getInitialLink()` ile ilk link'i al
- Foreground/Background: `appLinks.uriLinkStream` dinle
- Link'i callback'e ilet (parse islemi disarida yapilir)
- Stream subscription lifecycle yonetimi

**Interface:**
```dart
class DeepLinkManager {
  static final DeepLinkManager instance = DeepLinkManager._();

  Future<Uri?> getInitialLink();
  Stream<Uri> get linkStream;
  void dispose();
}
```

**Provider:** `deepLinkManagerProvider` (api_provider.dart)

**Lifecycle:** Provider `ref.onDispose()` ile `DeepLinkManager.dispose()` cagirir. `app.dart` dispose'da provider'i invalidate eder.

#### 2. DeepLinkParser (`lib/core/services/deep_link_parser.dart`)

Pure utility class — URI'yi route bilgisine cevirir.

**Responsibilities:**
- URI validation (host check: `quloapp.com` VEYA `www.quloapp.com`)
- Path matching (desteklenen route'lar)
- Deep link path → GoRouter path mapping (ornegin `/profile/:userId` → `/profile-detail/:userId`)
- Parameter extraction
- Malformed URI rejection + log

**Interface:**
```dart
enum DeepLinkNavType { go, push }

class DeepLinkResult {
  final String goRouterPath;    // Gercek GoRouter path (e.g., "/profile-detail/uuid")
  final bool requiresAuth;
  final DeepLinkNavType navType;
}

abstract class DeepLinkParser {
  static DeepLinkResult? parse(Uri uri);
}
```

**Path Mapping Tablosu:**

| Deep Link Path | GoRouter Path | NavType |
|---------------|---------------|---------|
| `/invite/:code` | `/invite/:code` (redirect handled by GoRouter) | go |
| `/chat/:matchId` | `/chat/:matchId` | push |
| `/matches` | `/matches` | go |
| `/discover` | `/discover` | go |
| `/profile/:userId` | `/profile-detail/:userId` | push |
| `/profile/subscription` | `/profile/subscription` | go |
| `/profile/passport` | `/profile/passport` | go |

**Onemli:** `/profile/subscription` ve `/profile/passport` StatefulShellRoute nested route'laridir. Bu route'lara `go()` ile navigate edilir — GoRouter shell route'lari dogru tab'a yonlendirir. `push()` shell-nested route'larda beklenmedik davranis gosterir.

`/chat/:matchId` ve `/profile-detail/:userId` ise `parentNavigatorKey: rootNavigatorKey` ile tanimli top-level route'lardir, `push()` ile guvenle navigate edilebilir.

#### 3. pendingDeepLinkProvider (`lib/providers/deep_link_provider.dart`)

Auth olmayan kullanici icin deferred link saklama.

```dart
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);
```

**Redirect fonksiyonundaki yeri (app_router.dart):**

```dart
redirect: (context, state) {
  final authState = ref.read(authProvider);
  final isAuth = authState.status == AuthStatus.authenticated;

  // 1. Auth yukleniyor — bekle
  if (authState.status == AuthStatus.initial) return null;

  // 2. Update/maintenance route'lari — her zaman izin ver
  final isUpdateRoute = ...;
  if (isUpdateRoute) return null;

  // 3. Invite route — mevcut logic (auth ise discover'a, degilse register'a)
  final isInviteRoute = ...;
  if (isInviteRoute) { ... }

  // 4. YENI: Auth basarili + pending deep link var → replay
  final pendingLink = ref.read(pendingDeepLinkProvider);
  if (isAuth && pendingLink != null) {
    ref.read(pendingDeepLinkProvider.notifier).state = null;  // consume
    return pendingLink;
  }

  // 5. Auth degilse + protected route → login'e yonlendir
  //    (pendingDeepLink zaten DeepLinkParser tarafindan set edilmis olur)
  if (!isAuth && !isAuthRoute && !isInviteRoute && !isUpdateRoute) {
    return '/auth/login';
  }

  // 6. Auth ise + auth route'taysa → discover'a
  if (isAuth && (isAuthRoute || isSplash)) return '/discover';

  return null;
}
```

**Onemli:** `pendingDeepLink` set islemi redirect icinde YAPILMAZ. DeepLinkParser sonucu `requiresAuth: true` ve kullanici auth degilse, deep link handler (app.dart) pending'e yazar. Redirect sadece consume eder.

#### 4. NavigationService — Yeni metod: `navigateDeepLink()`

Mevcut `handleDeepLink()` yerine daha net bir metod eklenir:

```dart
void navigateDeepLink(DeepLinkResult result) {
  if (result.navType == DeepLinkNavType.go) {
    _router.go(result.goRouterPath);
  } else {
    _router.push(result.goRouterPath);
  }

  // Observer'lara bildir
  for (final observer in _observers) {
    observer.onNavigate(NavigationEvent.go(result.goRouterPath));
  }
}
```

Mevcut `handleDeepLink(String uri)` metodu deprecated olarak kalir, geriye uyumluluk icin (bildirimler hala kullanir).

## Supported Deep Links (MVP-B)

| Deep Link URL | GoRouter Path | Auth | NavType | Aciklama |
|--------------|---------------|------|---------|----------|
| `quloapp.com/invite/:code` | `/invite/:code` | No | go | Referral — GoRouter redirect register'a yonlendirir |
| `quloapp.com/chat/:matchId` | `/chat/:matchId` | Yes | push | Root navigator, full screen |
| `quloapp.com/matches` | `/matches` | Yes | go | Bottom nav tab switch |
| `quloapp.com/discover` | `/discover` | Yes | go | Bottom nav tab switch |
| `quloapp.com/profile/:userId` | `/profile-detail/:userId` | Yes | push | Root navigator, full screen |
| `quloapp.com/profile/subscription` | `/profile/subscription` | Yes | go | Shell nested route |
| `quloapp.com/profile/passport` | `/profile/passport` | Yes | go | Shell nested route |

## Bug Fix: Chat Notification Path

**Root cause:** Server `chat.service.ts:154` sends `/matches/chat/${match.id}`, Flutter route is `/chat/:matchId`.

**Fix:** Server-side action_url'leri duzelt:
- `chat.service.ts` → `/chat/${match.id}`
- `chat-question.service.ts` → `/chat/${match.id}` (if applicable)
- `media.service.ts` → `/chat/${match.id}` (if applicable)

Banner suppression logic'i otomatik duzulur (zaten `/chat/$matchId` ariyor).

## Platform Configuration

### iOS
- `Info.plist`: `FlutterDeepLinkingEnabled` → `NO` (GoRouter built-in handler devre disi, app_links ile manual handle)
- `Runner.entitlements`: `applinks:quloapp.com` (zaten eklendi)

### Android
- `AndroidManifest.xml`: VIEW intent-filter `quloapp.com` (zaten eklendi)
- GoRouter'in built-in deep link handler'i Android'de de devre disi olmali — `app_links` paketi bunu otomatik handle eder

### Package
- `app_links: ^6.4.0` (veya uyumlu son surum — `flutter pub add` ile kontrol edilecek)
- Flutter SDK >= 3.22 gerektir (mevcut projede zaten uygun)

## Edge Cases

| Senaryo | Cozum |
|---------|-------|
| Auth olmayan + protected link | `pendingDeepLinkProvider`'a kaydet, login sonrasi redirect'te replay |
| iOS terminated state cift navigation | `FlutterDeepLinkingEnabled: NO` + `app_links` ile manual handle |
| Expired/invalid content | Ilgili ekranin kendi error state'i handle eder |
| Ayni ekrana tekrar deep link | NavigationService throttle (50ms) mevcut |
| Malformed URI | DeepLinkParser validation, gecersizse ignore + log |
| Cold start + heavy screen | Splash'te auth + init tamamlanana kadar deep link bekletilir |
| `www.quloapp.com` subdomain | DeepLinkParser host check: `quloapp.com` VEYA `www.quloapp.com` kabul eder |
| push() sonrasi bos stack | push() kullanan route'lar root navigator'da — bottom nav her zaman altta |
| Shell-nested route + push() catismasi | Shell-nested route'lar (subscription, passport) `go()` kullanir, push degil |
| Stream subscription leak | Provider `ref.onDispose()` ile `DeepLinkManager.dispose()` cagirir |
| Redirect dongusu | pendingDeepLink set islemi handler'da, consume redirect'te — ayri sorumluluk |

## Analytics

Deep link event'leri `AnalyticsManager` uzerinden loglanir:

| Event | Parametreler | Ne Zaman |
|-------|-------------|----------|
| `deep_link_received` | `uri`, `source` (initial/stream) | Her deep link geldiginde |
| `deep_link_navigated` | `target_path`, `nav_type` | Basarili navigate sonrasi |
| `deep_link_deferred` | `target_path` | Auth yok, pending'e kaydedildi |
| `deep_link_replayed` | `target_path` | Login sonrasi pending replay |
| `deep_link_invalid` | `uri`, `reason` | Parse basarisiz |

## Init Flow (app.dart)

```
1. App baslar → Splash
2. Auth check (authProvider)
3. Auth tamamlaninca (postFrameCallback):
   a. DeepLinkManager.getInitialLink() → link var mi?
      - Link var → DeepLinkParser.parse(uri)
        - result == null → ignore (invalid link)
        - requiresAuth && !isAuth → pendingDeepLinkProvider'a kaydet
        - !requiresAuth || isAuth → NavigationService.navigateDeepLink(result)
      - Link yok → normal akis
   b. DeepLinkManager.linkStream.listen → (foreground deep link'ler icin ayni logic)
4. Auth state degisince → GoRouter redirect tetiklenir → pendingDeepLink kontrol → replay
```

## Files to Create/Modify

### New Files
- `lib/core/services/deep_link_manager.dart` — OS link listener (singleton + provider)
- `lib/core/services/deep_link_parser.dart` — URI → route parser (pure utility)
- `lib/providers/deep_link_provider.dart` — pendingDeepLink StateProvider

### Modified Files
- `lib/app.dart` — DeepLinkManager init + stream listener + deep link handling
- `lib/routing/app_router.dart` — redirect fonksiyonuna pendingDeepLink replay eklenir
- `lib/core/navigation/navigation_service.dart` — `navigateDeepLink(DeepLinkResult)` metodu eklenir
- `lib/core/analytics/analytics_manager.dart` — deep link event'leri (5 yeni event)
- `ios/Runner/Info.plist` — `FlutterDeepLinkingEnabled: NO`
- `pubspec.yaml` — `app_links` dependency

### Server Files (Bug Fix)
- `qulo-server/src/services/chat.service.ts` — action_url `/chat/${match.id}`
- `qulo-server/src/services/chat-question.service.ts` — action_url fix (if applicable)
- `qulo-server/src/services/media.service.ts` — action_url fix (if applicable)
