# Navigation System Design

## Problem

- Navigation cagrilari ekranlara dagilmis, merkezi yonetim yok
- Dialog/BottomSheet icin `Navigator.pop(context)` kullaniliyor, GoRouter ile cakisiyor
- Observer/logging/analytics icin altyapi yok
- Root vs shell navigator secimi runtime'da yapilemiyor
- Test icin navigation mocklanamaz
- Deep link handle merkezi degil

## Cozum: NavigationService (Riverpod-based)

GoRouter'i saran, Riverpod provider ile inject edilen merkezi navigation servisi.

## Architecture

```
Screen
  -> ref.read(navigationServiceProvider)
    -> NavigationService
      -> Observer chain (log, analytics, custom)
      -> GoRouter (root or shell navigator)
      -> Dialog/BottomSheet (via navigatorKey)
```

## 1. Core - NavigationService

### Dosya: `lib/core/navigation/navigation_service.dart`

```dart
class NavigationService {
  final GoRouter _router;
  final GlobalKey<NavigatorState> _rootNavigatorKey;
  final List<NavigationObserver> _observers;

  // Route navigation
  void go(String name, {Map<String, String>? params, Object? extra, bool useRootNavigator = false});
  void push(String name, {Map<String, String>? params, Object? extra, bool useRootNavigator = false});
  void pop<T>([T? result]);
  bool canPop();

  // Dialog & Overlay (context-free, navigatorKey kullanir)
  Future<T?> showAppDialog<T>(AppDialog dialog);
  Future<T?> showAppBottomSheet<T>(AppBottomSheet sheet);
  void closeOverlay<T>([T? result]);

  // Deep link
  void handleDeepLink(String uri);

  // Observer management
  void addObserver(NavigationObserver observer);
  void removeObserver(NavigationObserver observer);
}
```

### Provider

```dart
final navigationServiceProvider = Provider<NavigationService>((ref) {
  final router = ref.read(routerProvider);
  return NavigationService(
    router: router,
    observers: [LoggingObserver(), AnalyticsObserver()],
  );
});
```

### Kullanim

```dart
// ONCE
context.goNamed(RouteNames.settings);
Navigator.pop(dialogContext, true);

// SONRA
ref.read(navigationServiceProvider).go(RouteNames.settings);
ref.read(navigationServiceProvider).closeOverlay(true);
```

## 2. Observer & Event System

### Dosya: `lib/core/navigation/navigation_observer.dart`

```dart
abstract class NavigationObserver {
  void onNavigate(NavigationEvent event);
  void onPop(NavigationEvent event);
  void onDialogOpen(String dialogName, {Map<String, dynamic>? params});
  void onDialogClose(String dialogName, {dynamic result});
}
```

### Dosya: `lib/core/navigation/navigation_event.dart`

```dart
class NavigationEvent {
  final String routeName;
  final Map<String, String>? pathParameters;
  final Object? extra;
  final NavigationType type; // go, push, pop
  final DateTime timestamp;
}

enum NavigationType { go, push, pop }
```

### Built-in Observers

- **LoggingObserver**: Debug modda console log (`[NAV] go -> settings`)
- **AnalyticsObserver**: Firebase Analytics screen_view + dialog event'leri

## 3. Root Navigator & Shell-Aware Navigation

### Navigator Keys

```dart
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
```

### useRootNavigator Parametresi

- `false` (varsayilan): Shell icinde acilir, bottom nav gorunur
- `true`: Root navigator'da acilir, bottom nav gizlenir (quiz, full-screen chat, vb.)

### Route Taniminda parentNavigatorKey

```dart
GoRoute(
  parentNavigatorKey: rootNavigatorKey,  // shell disinda
  path: '/quiz/:targetId',
  name: RouteNames.quiz,
  ...
),
```

### Root Olacak Ekranlar

| Ekran | Root? | Neden |
|-------|-------|-------|
| Quiz | Evet | Tam odak |
| Chat | Parametrik | Bazen shell, bazen full-screen |
| Onboarding | Evet | Auth flow |
| Settings | Hayir | Profile alt sayfasi |

## 4. Dialog & Overlay Type System

### Dosya: `lib/core/navigation/models/app_dialog.dart`

```dart
sealed class AppDialog {
  final String name;            // observer logging icin
  final bool barrierDismissible;
  final bool useRootNavigator;  // varsayilan true
}
```

**Hazir Tipler:**
- **ConfirmDialog**: title, message, confirmText, cancelText, isDestructive -> Future<bool?>
- **InfoDialog**: title, message, icon, iconColor, buttonText -> Future<void>
- **FormDialog**: title, fields (FormFieldConfig list), submitText -> Future<Map<String, dynamic>?>
- **CustomDialog**: builder (Widget Function(BuildContext)) -> Future<T?>

### Dosya: `lib/core/navigation/models/app_bottom_sheet.dart`

```dart
sealed class AppBottomSheet {
  final String name;
  final bool isDismissible;
  final bool enableDrag;
  final bool useRootNavigator;
  final double? maxHeight;      // ekranin %'si (0.0-1.0)
}
```

**Hazir Tipler:**
- **ListBottomSheet**: title, options (SheetOption list) -> Future<T?>
- **CustomBottomSheet**: builder -> Future<T?>

### Observer Loglari

```
[NAV] dialog_open -> delete_account | type: ConfirmDialog | destructive: true
[NAV] dialog_close -> delete_account | result: true
[NAV] sheet_open -> report_reason | type: ListBottomSheet
[NAV] sheet_close -> report_reason | result: spam
```

## 5. Deep Link Support

```dart
// NavigationService
void handleDeepLink(String uri) {
  _notifyObservers(DeepLinkEvent(uri));
  // Auth guard (GoRouter redirect handles this)
  _router.go(uri);
}
```

Platform setup (Info.plist, AndroidManifest.xml) ileride yapilir, NavigationService altyapisi hazir.

## 6. Dosya Yapisi

```
lib/core/navigation/
  navigation_service.dart        // Ana servis
  navigation_observer.dart       // Abstract observer
  navigation_event.dart          // Event model
  navigation_provider.dart       // Riverpod provider
  observers/
    logging_observer.dart
    analytics_observer.dart
  models/
    app_dialog.dart              // sealed class + tipleri
    app_bottom_sheet.dart        // sealed class + tipleri
  widgets/
    confirm_dialog_widget.dart   // ConfirmDialog renderer
    info_dialog_widget.dart      // InfoDialog renderer
    form_dialog_widget.dart      // FormDialog renderer
    list_bottom_sheet_widget.dart // ListBottomSheet renderer
```

## 7. Migration Plani

1. NavigationService + models + observers yaz
2. Router config'e navigator key'leri ekle
3. Mevcut ekranlari NavigationService'e gecir (8 dosya)
4. Mevcut showDialog cagrilerini AppDialog tiplerine cevir (3 dosya)
5. Test altyapisi (mock provider)

## Tasarim Kararlari

- `sealed class` -> tip guvenligi, exhaustive switch
- Her dialog/sheet'in `name` field'i zorunlu (observer icin)
- Observer'lar senkron calisir (navigation'i bloklamaz)
- Hazir dialog tipleri theme'den stil alir
- `useRootNavigator` varsayilan false (mevcut davranis korunur)
- Dialog/BottomSheet her zaman root navigator kullanir
