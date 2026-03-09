# Location System & Passport Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** GPS konum otomatik alma, Google Maps ile pasaport konum seçimi, ve discover empty state'de inline mesafe slider'ı ekle.

**Architecture:** Discover ekranına girişte GPS alınıp backend'e gönderilir (reverse geocoding ile city). Passport modunda Google Maps picker ile konum seçilir (Premium gate). Empty state'de inline slider ile match_radius_km ayarlanır.

**Tech Stack:** Flutter (geolocator, geocoding, google_maps_flutter), Riverpod, GoRouter, Express/TypeScript backend, Supabase PostgreSQL

---

## Phase 1: Backend Değişiklikleri

### Task 1: Backend — Passport subscription gate + location update city desteği

**Files:**
- Modify: `server/src/services/passport.service.ts`
- Modify: `server/src/services/user.service.ts:122-135`
- Modify: `server/src/validators/user.validator.ts:35-38`
- Modify: `server/src/utils/errors.ts`

**Step 1: Errors'a yeni hata kodları ekle**

`server/src/utils/errors.ts` — `DAILY_LIMIT_EXCEEDED` satırından sonra ekle:

```typescript
PASSPORT_REQUIRES_PREMIUM: () =>
  new AppError("PASSPORT_REQUIRES_PREMIUM", 403, "Passport mode requires Premium subscription"),

PASSPORT_ALREADY_ACTIVE: () =>
  new AppError("PASSPORT_ALREADY_ACTIVE", 409, "Passport is already active"),
```

**Step 2: Passport service'e subscription kontrolü ekle**

`server/src/services/passport.service.ts` — `activate` metodunu güncelle:

```typescript
import { supabase } from "../config/supabase.js";
import { diamondService } from "./diamond.service.js";
import { subscriptionService } from "./subscription.service.js";
import { Errors } from "../utils/errors.js";

export class PassportService {
  async activate(userId: string, city: string, lat: number, lng: number) {
    // 1. Premium kontrolü
    const sub = await subscriptionService.getStatus(userId);
    if (!sub.isActive || sub.plan !== "premium") {
      throw Errors.PASSPORT_REQUIRES_PREMIUM();
    }

    // 2. Zaten aktif mi kontrol
    const { data: user } = await supabase
      .from("users")
      .select("passport_city")
      .eq("id", userId)
      .single();

    if (user?.passport_city) {
      throw Errors.PASSPORT_ALREADY_ACTIVE();
    }

    // 3. 50 mor elmas harca
    await diamondService.spendPurple(userId, 50, "PASSPORT");

    // 4. Passport alanlarını güncelle
    const { error } = await supabase
      .from("users")
      .update({
        passport_city: city,
        passport_lat: lat,
        passport_lng: lng,
        updated_at: new Date().toISOString(),
      })
      .eq("id", userId);

    if (error) throw Errors.SERVER_ERROR();

    return { passport_city: city, passport_lat: lat, passport_lng: lng };
  }

  async deactivate(userId: string) {
    const { error } = await supabase
      .from("users")
      .update({
        passport_city: null,
        passport_lat: null,
        passport_lng: null,
        updated_at: new Date().toISOString(),
      })
      .eq("id", userId);

    if (error) throw Errors.SERVER_ERROR();
    return { message: "Passport deactivated" };
  }
}

export const passportService = new PassportService();
```

**Step 3: Location update'e city ekle**

`server/src/validators/user.validator.ts` — `updateLocationSchema`'yı güncelle:

```typescript
export const updateLocationSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  city: z.string().max(100).optional(),
});
```

`server/src/services/user.service.ts` — `updateLocation` metodunu güncelle:

```typescript
async updateLocation(userId: string, lat: number, lng: number, city?: string) {
  const updateData: Record<string, unknown> = { lat, lng };
  if (city) updateData.city = city;

  const { error } = await supabase
    .from("users")
    .update(updateData)
    .eq("id", userId)
    .eq("is_deleted", false);

  if (error) {
    console.error("[updateLocation] Supabase error:", error);
    throw Errors.SERVER_ERROR();
  }

  await this.recalculateProfileCompletion(userId);
}
```

`server/src/validators/user.validator.ts` — `match_radius_km` aralığını güncelle:

```typescript
match_radius_km: z.number().int().min(5).max(200).optional(),
```

**Step 4: Location controller'da city parametresini geçir**

`server/src/controllers/user.controller.ts` — `updateLocationHandler`'da:

```typescript
const { lat, lng, city } = req.body as UpdateLocationInput;
await userService.updateLocation(req.user!.userId, lat, lng, city);
```

**Step 5: Commit**

```bash
git add server/src/utils/errors.ts server/src/services/passport.service.ts server/src/services/user.service.ts server/src/validators/user.validator.ts server/src/controllers/user.controller.ts
git commit -m "feat: add passport subscription gate, city to location update, radius 5-200"
```

---

## Phase 2: Flutter — Paket & LocationManager Güncelleme

### Task 2: google_maps_flutter paketi + LocationManager reverse geocoding

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/services/location_manager.dart`

**Step 1: pubspec.yaml'a google_maps_flutter ekle**

Dependencies bölümüne ekle:

```yaml
google_maps_flutter: ^2.10.0
```

`flutter pub get` çalıştır.

**Step 2: LocationManager'a reverse geocoding ekle**

`lib/core/services/location_manager.dart`:

```dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String? city;

  const LocationResult({required this.lat, required this.lng, this.city});
}

class LocationManager {
  LocationManager._();
  static final LocationManager instance = LocationManager._();

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  Future<LocationResult> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    final city = await getCityFromCoordinates(position.latitude, position.longitude);
    return LocationResult(lat: position.latitude, lng: position.longitude, city: city);
  }

  Future<String?> getCityFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ?? placemarks.first.administrativeArea;
      }
    } catch (_) {}
    return null;
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.denied => LocationPermissionStatus.denied,
      LocationPermission.deniedForever => LocationPermissionStatus.deniedForever,
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.always => LocationPermissionStatus.granted,
      LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
    };
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
}
```

**Step 3: Commit**

```bash
git add pubspec.yaml lib/core/services/location_manager.dart
git commit -m "feat: add google_maps_flutter package, reverse geocoding to LocationManager"
```

---

## Phase 3: Flutter — Konum Provider & Discover Entegrasyonu

### Task 3: LocationProvider güncelle + Discover'da otomatik konum

**Files:**
- Modify: `lib/providers/location_provider.dart`
- Modify: `lib/data/repositories/user_repository.dart`
- Modify: `lib/features/discover/screens/discover_screen.dart`

**Step 1: LocationProvider'a city desteği ve discover tetiklemesi ekle**

`lib/providers/location_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class LocationState {
  final double? lat;
  final double? lng;
  final String? city;
  final bool isLoading;
  final String? error;

  const LocationState({this.lat, this.lng, this.city, this.isLoading = false, this.error});

  LocationState copyWith({double? lat, double? lng, String? city, bool? isLoading, String? error}) {
    return LocationState(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      city: city ?? this.city,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final manager = ref.read(locationManagerProvider);

      final serviceEnabled = await manager.isServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(isLoading: false, error: 'LOCATION_SERVICE_DISABLED');
        return;
      }

      var permission = await manager.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await manager.requestPermission();
        if (permission == LocationPermissionStatus.denied) {
          state = state.copyWith(isLoading: false, error: 'LOCATION_PERMISSION_DENIED');
          return;
        }
      }

      if (permission == LocationPermissionStatus.deniedForever) {
        state = state.copyWith(isLoading: false, error: 'LOCATION_PERMISSION_DENIED_FOREVER');
        return;
      }

      final result = await manager.getCurrentPosition();

      state = state.copyWith(
        lat: result.lat,
        lng: result.lng,
        city: result.city,
        isLoading: false,
      );

      await ref.read(userRepositoryProvider).updateLocation(
        lat: result.lat,
        lng: result.lng,
        city: result.city,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
```

**Step 2: UserRepository.updateLocation'a city parametresi ekle**

`lib/data/repositories/user_repository.dart` — `updateLocation` metodunu güncelle:

```dart
@override
Future<Result<void>> updateLocation({required double lat, required double lng, String? city}) async {
  try {
    final data = <String, dynamic>{'lat': lat, 'lng': lng};
    if (city != null) data['city'] = city;
    await _service.updateLocation(data);
    return const Success(null);
  } on DioException catch (e) {
    return Failure(e.toAppFailure());
  }
}
```

Interface'de de güncelle (IUserRepository).

**Step 3: DiscoverScreen'de konum tetiklemesi ekle**

`lib/features/discover/screens/discover_screen.dart` — `initState`'e konum alma ekle:

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    // Önce konum al, sonra kartları yükle
    _initLocationAndDiscover();
  });
  _loadAndIncrementNudge();
}

Future<void> _initLocationAndDiscover() async {
  final locationState = ref.read(locationProvider);
  // Konum henüz alınmamışsa al
  if (locationState.lat == null) {
    await ref.read(locationProvider.notifier).getCurrentLocation();
  }
  // Kartları yükle
  ref.read(discoverProvider.notifier).loadCards();
}
```

**Step 4: Commit**

```bash
git add lib/providers/location_provider.dart lib/data/repositories/user_repository.dart lib/features/discover/screens/discover_screen.dart
git commit -m "feat: auto GPS on discover entry with reverse geocoding city"
```

---

## Phase 4: Flutter — Google Maps Picker Ekranı

### Task 4: MapPickerScreen oluştur

**Files:**
- Create: `lib/features/passport/screens/map_picker_screen.dart`
- Modify: `lib/routing/route_names.dart`
- Modify: `lib/routing/app_routes.dart` (route ekle)

**Step 1: RouteNames'e mapPicker ekle**

`lib/routing/route_names.dart`:

```dart
static const mapPicker = 'map-picker';
```

**Step 2: Route tanımı ekle**

`lib/routing/app_routes.dart` — passport route'unun yanına:

```dart
GoRoute(
  path: 'map-picker',
  name: RouteNames.mapPicker,
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const MapPickerScreen(),
),
```

**Step 3: MapPickerScreen widget'ını yaz**

`lib/features/passport/screens/map_picker_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _selectedPosition = const LatLng(41.0082, 28.9784); // İstanbul default
  String? _selectedCity;
  bool _isLoadingCity = false;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    try {
      final manager = ref.read(locationManagerProvider);
      final permission = await manager.checkPermission();
      if (permission == LocationPermissionStatus.granted) {
        final result = await manager.getCurrentPosition();
        setState(() {
          _selectedPosition = LatLng(result.lat, result.lng);
          _selectedCity = result.city;
        });
        final controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newLatLng(_selectedPosition));
      }
    } catch (_) {}
  }

  Future<void> _onCameraIdle() async {
    setState(() => _isLoadingCity = true);
    try {
      final manager = ref.read(locationManagerProvider);
      final city = await manager.getCityFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );
      if (mounted) {
        setState(() {
          _selectedCity = city;
          _isLoadingCity = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCity = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _selectedPosition = position.target;
  }

  void _confirm() {
    Navigator.of(context).pop({
      'lat': _selectedPosition.latitude,
      'lng': _selectedPosition.longitude,
      'city': _selectedCity,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Center pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(Icons.location_on, size: 48, color: AppColors.primary),
            ),
          ),

          // Top bar — back button
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // My location button
          Positioned(
            bottom: 140,
            right: AppSpacing.md,
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _initCurrentLocation,
              ),
            ),
          ),

          // Bottom sheet — city name + confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // City name
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _isLoadingCity
                            ? const AppLoadingWidget.small()
                            : Text(
                                _selectedCity ?? context.tr('passport_select_location'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _selectedCity != null ? _confirm : null,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
                      child: Text(
                        '${context.tr("passport_move_here")} — ${AppConstants.passportCostPurple} 💎',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Commit**

```bash
git add lib/features/passport/screens/map_picker_screen.dart lib/routing/route_names.dart lib/routing/app_routes.dart
git commit -m "feat: add Google Maps picker screen for passport location selection"
```

---

## Phase 5: Flutter — PassportScreen Güncelleme

### Task 5: PassportScreen'i harita + subscription gate ile güncelle

**Files:**
- Modify: `lib/features/passport/screens/passport_screen.dart`

**Step 1: PassportScreen'i tamamen güncelle**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key});

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> with LoadingMixin {

  Future<void> _openMapPicker() async {
    final result = await ref.read(navigationServiceProvider).push<Map<String, dynamic>>(
      RouteNames.mapPicker,
    );
    if (result == null || !mounted) return;

    final city = result['city'] as String?;
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;

    if (city == null || city.isEmpty) return;

    await withLoading(() async {
      await ref.read(passportProvider.notifier).activate(city: city, lat: lat, lng: lng);
    });
  }

  @override
  Widget build(BuildContext context) {
    final passport = ref.watch(passportProvider);
    final subscription = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);
    final isPremium = subscription.valueOrNull?.subscription.isPremium ?? false;

    // Premium gate
    if (!isPremium) {
      return AppScaffold(
        title: context.tr('passport'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QIcon(QIcons.icLock, size: 64, color: AppColors.textHint),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.tr('passport_premium_only'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr('passport_premium_desc'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => ref.read(navigationServiceProvider).push(RouteNames.subscription),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
                    child: Text(context.tr('upgrade_to_premium')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: context.tr('passport'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.flight, size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            passport.isActive
                ? '${context.tr("passport_active")}: ${passport.city}'
                : context.tr('passport_explore'),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${context.tr("passport_cost")}: ${AppConstants.passportCostPurple} 💎',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          if (!passport.isActive) ...[
            // Harita ile konum seç butonu
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: isLoading ? null : _openMapPicker,
                icon: const Icon(Icons.map),
                label: isLoading
                    ? const SizedBox(height: 20, width: 20, child: AppLoadingWidget.small())
                    : Text(context.tr('passport_pick_on_map')),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
              ),
            ),
          ] else ...[
            // Aktif pasaport bilgileri
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flight_takeoff, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passport.city ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          context.tr('passport_active_desc'),
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () => withLoading(() => ref.read(passportProvider.notifier).deactivate()),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: AppLoadingWidget.small())
                    : Text(context.tr('passport_deactivate')),
              ),
            ),
          ],

          if (passport.failure != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr(passport.failure!.code),
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/passport/screens/passport_screen.dart
git commit -m "feat: passport screen with map picker + premium gate"
```

---

## Phase 6: Flutter — Discover Empty State + Slider

### Task 6: Discover empty state widget + inline radius slider

**Files:**
- Create: `lib/features/discover/widgets/discover_empty_state.dart`
- Modify: `lib/features/discover/screens/discover_screen.dart`

**Step 1: DiscoverEmptyState widget'ı oluştur**

`lib/features/discover/widgets/discover_empty_state.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';

class DiscoverEmptyState extends ConsumerStatefulWidget {
  const DiscoverEmptyState({super.key});

  @override
  ConsumerState<DiscoverEmptyState> createState() => _DiscoverEmptyStateState();
}

class _DiscoverEmptyStateState extends ConsumerState<DiscoverEmptyState> {
  late double _radius;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).valueOrNull;
    _radius = (user?.matchRadiusKm ?? 50).toDouble();
  }

  Future<void> _updateRadiusAndSearch() async {
    setState(() => _isSearching = true);

    // Radius'u backend'e kaydet
    await ref.read(userRepositoryProvider).updateProfile({
      'match_radius_km': _radius.round(),
    });

    // Discover'ı yeniden yükle
    await ref.read(discoverProvider.notifier).loadCards();

    if (mounted) setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passport = ref.watch(passportProvider);
    final subscription = ref.watch(subscriptionProvider);
    final isPremium = subscription.valueOrNull?.subscription.isPremium ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QIcon(QIcons.icCompassOff, size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('no_more_profiles'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('no_more_profiles_hint'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Inline slider
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('match_radius'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_radius.round()} km',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _radius,
                    min: 5,
                    max: 200,
                    divisions: 39, // 5km adımlar
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _radius = val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5 km', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textHint)),
                      Text('200 km', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isSearching ? null : _updateRadiusAndSearch,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
                      child: _isSearching
                          ? const AppLoadingWidget.small()
                          : Text(context.tr('search_again')),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Pasaport ipucu
            if (passport.isActive) ...[
              TextButton.icon(
                onPressed: () => ref.read(navigationServiceProvider).push(RouteNames.passport),
                icon: const Icon(Icons.flight, size: 16),
                label: Text(context.tr('passport_change_city')),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ] else if (isPremium) ...[
              TextButton.icon(
                onPressed: () => ref.read(navigationServiceProvider).push(RouteNames.passport),
                icon: const Icon(Icons.flight, size: 16),
                label: Text(context.tr('passport_explore_hint')),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ] else ...[
              TextButton.icon(
                onPressed: () => ref.read(navigationServiceProvider).push(RouteNames.subscription),
                icon: const Icon(Icons.flight, size: 16),
                label: Text(context.tr('passport_premium_explore_hint')),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Step 2: DiscoverScreen'deki empty state'i güncelle**

`lib/features/discover/screens/discover_screen.dart` — satır 306-322 arası mevcut empty state'i değiştir:

```dart
if (discover.cards.isEmpty) {
  return const DiscoverEmptyState();
}
```

Import ekle:
```dart
import 'package:qulo_v2/features/discover/widgets/discover_empty_state.dart';
```

**Step 3: Commit**

```bash
git add lib/features/discover/widgets/discover_empty_state.dart lib/features/discover/screens/discover_screen.dart
git commit -m "feat: discover empty state with inline radius slider + passport hints"
```

---

## Phase 7: Flutter — i18n Keys

### Task 7: Yeni çeviri key'lerini ekle

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: TR ve EN key'leri ekle**

TR map'e ekle:
```dart
// Passport
'passport_premium_only': 'Pasaport modu Premium üyelere özeldir',
'passport_premium_desc': 'Premium\'a yükselerek istediğin şehirden eşleşmeleri keşfet',
'passport_pick_on_map': 'Haritadan Konum Seç',
'passport_select_location': 'Konumu seçmek için haritayı kaydır',
'passport_move_here': 'Buraya Taşın',
'passport_active_desc': 'Keşif bu konumdan yapılıyor',
'passport_deactivate': 'Gerçek Konumuma Dön',
'passport_change_city': 'Farklı bir şehre taşın',
'passport_explore_hint': 'Pasaport ile başka şehirleri keşfet',
'passport_premium_explore_hint': 'Premium ile başka şehirleri keşfet',
'upgrade_to_premium': 'Premium\'a Yükselt',

// Discover Empty State
'no_more_profiles_hint': 'Mesafe aralığını artırarak daha fazla kişi görebilirsin',
'match_radius': 'Eşleşme Mesafesi',
'search_again': 'Yeniden Ara',

// Location
'location_required': 'Konum izni gerekli',
'location_required_desc': 'Yakınındaki kişileri görebilmek için konum iznini etkinleştir',
'enable_location': 'Konum İznini Aç',
```

EN map'e ekle:
```dart
'passport_premium_only': 'Passport mode is exclusive to Premium members',
'passport_premium_desc': 'Upgrade to Premium to discover matches from any city',
'passport_pick_on_map': 'Pick Location on Map',
'passport_select_location': 'Drag the map to select a location',
'passport_move_here': 'Move Here',
'passport_active_desc': 'Discovery is based on this location',
'passport_deactivate': 'Return to My Location',
'passport_change_city': 'Move to a different city',
'passport_explore_hint': 'Explore other cities with Passport',
'passport_premium_explore_hint': 'Explore other cities with Premium',
'upgrade_to_premium': 'Upgrade to Premium',
'no_more_profiles_hint': 'Increase your distance range to see more people',
'match_radius': 'Match Distance',
'search_again': 'Search Again',
'location_required': 'Location permission required',
'location_required_desc': 'Enable location to see people nearby',
'enable_location': 'Enable Location',
```

**Step 2: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat: add i18n keys for passport, discover empty state, location"
```

---

## Phase 8: Discover — Konum İzni Empty State

### Task 8: Konum izni yoksa discover'da uyarı göster

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`

**Step 1: Konum hatası kontrolü ekle**

DiscoverScreen build metodunda, `state.when(data: (discover) {` bloğunun başında, question gate'den önce:

```dart
// Konum izni kontrolü
final locationState = ref.watch(locationProvider);
if (locationState.error == 'LOCATION_PERMISSION_DENIED' ||
    locationState.error == 'LOCATION_PERMISSION_DENIED_FOREVER' ||
    locationState.error == 'LOCATION_SERVICE_DISABLED') {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QIcon(QIcons.icLocation, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('location_required'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('location_required_desc'),
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () async {
                final manager = ref.read(locationManagerProvider);
                if (locationState.error == 'LOCATION_SERVICE_DISABLED') {
                  await manager.openLocationSettings();
                } else {
                  await manager.openAppSettings();
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
              child: Text(context.tr('enable_location')),
            ),
          ),
        ],
      ),
    ),
  );
}
```

Import ekle:
```dart
import 'package:qulo_v2/providers/location_provider.dart';
```

**Step 2: Commit**

```bash
git add lib/features/discover/screens/discover_screen.dart
git commit -m "feat: show location permission required state in discover"
```

---

## Phase 9: Discover'da Pasaport Badge

### Task 9: Discover ekranında pasaport aktif badge'i

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`

**Step 1: AppScaffold actions'a pasaport badge ekle**

```dart
return AppScaffold(
  title: context.tr('discover'),
  padding: EdgeInsets.zero,
  isLoading: state is AsyncLoading,
  actions: [
    if (ref.watch(passportProvider).isActive)
      Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flight, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                ref.watch(passportProvider).city ?? '',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
  ],
  body: state.when(
    // ... mevcut kod
  ),
);
```

**Step 2: Commit**

```bash
git add lib/features/discover/screens/discover_screen.dart
git commit -m "feat: show passport city badge in discover screen header"
```

---

## Phase 10: UserModel match_radius_km alanı kontrolü

### Task 10: UserModel'de matchRadiusKm alanı olduğunu doğrula + default 50

**Files:**
- Check: `lib/data/models/user_model.dart` — `matchRadiusKm` alanı mevcut mu?
- Modify (if needed): `lib/data/models/user_model.dart`

**Step 1: UserModel'i kontrol et**

`matchRadiusKm` alanı UserModel'de yoksa ekle:

```dart
@JsonKey(name: 'match_radius_km')
final int matchRadiusKm;

// Constructor'da: this.matchRadiusKm = 50 (default)
// fromJson'da: matchRadiusKm: json['match_radius_km'] as int? ?? 50
```

**Step 2: Commit (eğer değişiklik yaptıysan)**

```bash
git add lib/data/models/user_model.dart
git commit -m "fix: ensure matchRadiusKm field in UserModel with default 50"
```

---

## Özet

| Phase | Task | Açıklama |
|-------|------|----------|
| 1 | Task 1 | Backend: passport gate + location city + radius 5-200 |
| 2 | Task 2 | google_maps_flutter + LocationManager reverse geocoding |
| 3 | Task 3 | LocationProvider city + discover'da auto GPS |
| 4 | Task 4 | MapPickerScreen (Google Maps tam ekran) |
| 5 | Task 5 | PassportScreen: harita + premium gate |
| 6 | Task 6 | DiscoverEmptyState: inline slider |
| 7 | Task 7 | i18n keys (TR + EN) |
| 8 | Task 8 | Discover: konum izni yoksa uyarı |
| 9 | Task 9 | Discover: pasaport badge |
| 10 | Task 10 | UserModel matchRadiusKm kontrolü |
