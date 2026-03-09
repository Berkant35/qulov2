# Map Picker Ekranı Yeniden Tasarımı — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Harita seçim ekranını custom Q pin, tema uyumlu harita stili, düzgün loading, ücretsiz pasaport ve görünür konum butonu ile yeniden tasarla.

**Architecture:** MapPickerScreen'e custom map JSON stiller (light/dark), CustomPainter ile Q pin widget'ı, fade-in harita loading, shimmer şehir loading ve ücretsiz pasaport mantığı eklenir. Backend'den 50 elmas maliyeti kaldırılır.

**Tech Stack:** Flutter (CustomPainter, AnimatedOpacity, google_maps_flutter), Node.js/Express backend

---

### Task 1: Custom Harita Stilleri (JSON Asset Dosyaları)

**Files:**
- Create: `assets/map/map_style_light.json`
- Create: `assets/map/map_style_dark.json`
- Modify: `pubspec.yaml:81-84` (assets listesine `assets/map/` ekle)

**Step 1: Light mode map style JSON oluştur**

`assets/map/map_style_light.json` — Minimal açık tema, POI/transit kaldırılmış, mor (#BB86FC) vurgulu su/park:

```json
[
  { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
  { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
  { "featureType": "poi.park", "stylers": [{ "visibility": "simplified" }] },
  { "featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{ "color": "#E8DEF8" }] },
  { "featureType": "water", "elementType": "geometry.fill", "stylers": [{ "color": "#D0BCFF" }] },
  { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{ "color": "#9C27B0" }] },
  { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#FFFFFF" }] },
  { "featureType": "road", "elementType": "geometry.stroke", "stylers": [{ "color": "#E0E0E0" }] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#F5F5F5" }] },
  { "featureType": "landscape", "elementType": "geometry.fill", "stylers": [{ "color": "#FAFAFA" }] },
  { "featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{ "color": "#E0E0E0" }] },
  { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{ "color": "#424242" }] }
]
```

**Step 2: Dark mode map style JSON oluştur**

`assets/map/map_style_dark.json` — Koyu gri zemin, açık gri yollar, mor vurgulu su/park:

```json
[
  { "elementType": "geometry", "stylers": [{ "color": "#1A1A1A" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#B0B0B0" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#0D0D0D" }] },
  { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
  { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
  { "featureType": "poi.park", "stylers": [{ "visibility": "simplified" }] },
  { "featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{ "color": "#2D1B4E" }] },
  { "featureType": "water", "elementType": "geometry.fill", "stylers": [{ "color": "#1A0A2E" }] },
  { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{ "color": "#BB86FC" }] },
  { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#2A2A2A" }] },
  { "featureType": "road", "elementType": "geometry.stroke", "stylers": [{ "color": "#333333" }] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#3A3A3A" }] },
  { "featureType": "landscape", "elementType": "geometry.fill", "stylers": [{ "color": "#121212" }] },
  { "featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{ "color": "#333333" }] },
  { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{ "color": "#E0E0E0" }] }
]
```

**Step 3: pubspec.yaml'a asset path ekle**

`pubspec.yaml` — `assets:` bloğunun sonuna ekle:

```yaml
  assets:
    - assets/icons/
    - assets/brand/
    - assets/illustrations/
    - assets/map/
```

**Step 4: Commit**

```bash
git add assets/map/ pubspec.yaml
git commit -m "feat: add custom map styles for light and dark themes"
```

---

### Task 2: Custom Q Pin Widget (CustomPainter)

**Files:**
- Create: `lib/features/passport/widgets/q_map_pin.dart`

**Step 1: QMapPin widget'ı oluştur**

`lib/features/passport/widgets/q_map_pin.dart` — Damla şeklinde pin, mor gradient, ortasında "Q" logosu, gölge efekti:

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class QMapPin extends StatelessWidget {
  const QMapPin({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.4,
      child: CustomPaint(
        painter: _QMapPinPainter(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.35),
            child: Text(
              'Q',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QMapPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final circleRadius = w * 0.42;
    final centerX = w / 2;
    final centerY = h * 0.38;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final shadowPath = _buildPinPath(centerX, centerY + 2, circleRadius, h);
    canvas.drawPath(shadowPath, shadowPaint);

    // Gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.primary, AppColors.primaryDark],
    );

    final rect = Rect.fromLTWH(0, 0, w, h);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final pinPath = _buildPinPath(centerX, centerY, circleRadius, h);
    canvas.drawPath(pinPath, gradientPaint);

    // White circle highlight (inner)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX - circleRadius * 0.15, centerY - circleRadius * 0.15),
      circleRadius * 0.25,
      highlightPaint,
    );
  }

  Path _buildPinPath(double cx, double cy, double r, double totalHeight) {
    final path = Path();
    final tipY = totalHeight * 0.95;

    // Arc for the circle (top portion)
    final startAngle = math.pi * 0.15;
    final sweepAngle = math.pi * (2 - 0.3);

    path.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepAngle,
    );

    // Lines to the tip (bottom point)
    path.lineTo(cx, tipY);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

**Step 2: Commit**

```bash
git add lib/features/passport/widgets/q_map_pin.dart
git commit -m "feat: add custom Q map pin widget with gradient and shadow"
```

---

### Task 3: MapPickerScreen Yeniden Yazımı

**Files:**
- Modify: `lib/features/passport/screens/map_picker_screen.dart` (tam dosya)

**Step 1: map_picker_screen.dart'ı güncelle**

Tüm değişiklikler tek dosyada:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/passport/widgets/q_map_pin.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _selectedPosition = const LatLng(41.0082, 28.9784);
  String? _selectedCity;
  bool _isLoadingCity = false;
  bool _isMapReady = false;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final brightness = Theme.of(context).brightness;
    final stylePath = brightness == Brightness.dark
        ? 'assets/map/map_style_dark.json'
        : 'assets/map/map_style_light.json';
    final style = await rootBundle.loadString(stylePath);
    if (mounted) {
      setState(() => _mapStyle = style);
      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        controller.setMapStyle(style);
      }
    }
  }

  Future<void> _initCurrentLocation() async {
    try {
      final manager = ref.read(locationManagerProvider);
      final permission = await manager.checkPermission();
      if (permission == LocationPermissionStatus.granted) {
        final result = await manager.getCurrentPosition();
        if (mounted) {
          setState(() {
            _selectedPosition = LatLng(result.lat, result.lng);
            _selectedCity = result.city;
          });
          final controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newLatLng(_selectedPosition));
        }
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
          // Map loading placeholder (shown until map is ready)
          if (!_isMapReady)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: const Center(child: AppLoadingWidget.large()),
            ),

          // Google Map with fade-in
          AnimatedOpacity(
            opacity: _isMapReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: 12,
              ),
              onMapCreated: (controller) {
                _mapController.complete(controller);
                if (_mapStyle != null) controller.setMapStyle(_mapStyle);
                setState(() => _isMapReady = true);
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // Custom Q pin (center of map)
          if (_isMapReady)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: QMapPin(size: 56),
              ),
            ),

          // Back button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: theme.colorScheme.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Bottom panel — city name + confirm
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
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
                  // City name row with shimmer-like opacity when loading
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: _isLoadingCity ? 0.4 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _selectedCity ?? context.tr('passport_select_location'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_isLoadingCity)
                        const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.sm),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: AppLoadingWidget.small(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Confirm button — free (no diamond cost)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _selectedCity != null ? _confirm : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: Text(context.tr('passport_move_here')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My location button — ABOVE bottom panel, with elevation
          Positioned(
            bottom: 160,
            right: AppSpacing.md,
            child: Material(
              elevation: 6,
              shape: const CircleBorder(),
              color: theme.colorScheme.surface,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _initCurrentLocation,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Detaylı değişiklik listesi:**
1. **Custom map style**: `_loadMapStyle()` → tema brightness'ına göre JSON yükler, `setMapStyle()` uygular
2. **Map loading**: `_isMapReady` flag → harita hazır olana kadar scaffold renginde placeholder + `AppLoadingWidget.large()`, hazır olunca `AnimatedOpacity` ile fade-in
3. **City loading**: `AppLoadingWidget.small()` yerine → mevcut şehir adı kalır ama `AnimatedOpacity(0.4)` ile soluklaşır + sağda küçük (16px) spinner
4. **Custom Q pin**: `Icon(Icons.location_on)` → `QMapPin(size: 56)`, sadece harita hazırken gösterilir
5. **Free passport**: Buton metninden `— ${AppConstants.passportCostPurple} 💎` kaldırıldı, `app_constants` import'u kaldırıldı
6. **My location button**: `CircleAvatar` → `Material(elevation: 6, shape: CircleBorder)` ile gölge + z-index, `InkWell` ile tıklama efekti, 48px boyut, `bottom: 160` (panel üstünde)
7. **Back button**: `CircleAvatar` → `Material(elevation: 4, shape: CircleBorder)` ile tutarlı

**Step 2: Commit**

```bash
git add lib/features/passport/screens/map_picker_screen.dart
git commit -m "feat: redesign map picker — custom style, Q pin, better loading, free passport"
```

---

### Task 4: Passport Screen — Elmas Maliyeti Kaldır

**Files:**
- Modify: `lib/features/passport/screens/passport_screen.dart:103-107`

**Step 1: Maliyet satırını kaldır**

passport_screen.dart'ta şu satırları sil (103-107):

```dart
// SİL — bu 5 satırı tamamen kaldır:
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${context.tr("passport_cost")}: ${AppConstants.passportCostPurple} 💎',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
```

Ayrıca `app_constants.dart` import'u artık kullanılmıyorsa kaldır (satır 3):

```dart
// SİL:
import 'package:qulo_v2/core/constants/app_constants.dart';
```

**Step 2: Commit**

```bash
git add lib/features/passport/screens/passport_screen.dart
git commit -m "feat: remove diamond cost display from passport screen"
```

---

### Task 5: Backend — Elmas Maliyetini Kaldır

**Files:**
- Modify: `server/src/services/passport.service.ts:20-21`

**Step 1: Diamond deduction satırını kaldır**

passport.service.ts'te `activate` method'unda şu satırı sil:

```typescript
// SİL:
    // 3. 50 mor elmas harca
    await diamondService.spendPurple(userId, 50, "PASSPORT");
```

Ayrıca `diamondService` import'unu kaldır (artık kullanılmıyorsa):

```typescript
// SİL:
import { diamondService } from "./diamond.service.js";
```

**Step 2: Commit**

```bash
git add server/src/services/passport.service.ts
git commit -m "feat: make passport activation free — remove diamond cost"
```

---

### Task 6: App Constants — passportCostPurple Temizliği

**Files:**
- Modify: `lib/core/constants/app_constants.dart:10`

**Step 1: Kullanılmayan constant'ı kaldır**

```dart
// SİL:
  static const int passportCostPurple = 50;
```

**Step 2: Grep ile başka referans olmadığını doğrula**

```bash
grep -r "passportCostPurple" lib/
```

Beklenen: Hiçbir sonuç döndürmemeli (Task 3 ve 4'te referanslar kaldırıldı).

**Step 3: Commit**

```bash
git add lib/core/constants/app_constants.dart
git commit -m "chore: remove unused passportCostPurple constant"
```

---

### Task 7: Flutter Analyze + Doğrulama

**Step 1: Flutter analyze çalıştır**

```bash
flutter analyze
```

Beklenen: Hata yok. Uyarı varsa düzelt.

**Step 2: Backend build kontrol**

```bash
cd server && npm run build
```

Beklenen: Başarılı build, TypeScript hata yok.

**Step 3: Cihazda test**

- Harita açıldığında custom stil (dark/light) uygulanmalı
- Q pin haritanın ortasında gözükmeli
- Harita yüklenirken Qulo loading, sonra fade-in
- Şehir algılanırken yazı soluklaşmalı + küçük spinner
- Buton "Buraya Taşın" (elmas yok)
- Sağ alttaki konum butonu gölgeli ve görünür
- Pasaport ekranında maliyet satırı yok
- Aktivasyon elmas harcamasız çalışmalı

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete map picker redesign — custom style, Q pin, free passport"
```
