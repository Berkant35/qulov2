# Qulo İkon Paketi Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Qulo'ya özgü Lucide tabanlı SVG ikon sistemi oluştur, mevcut asset'leri temizle/düzenle, ve kritik ekranlarda Material ikonları SVG ile değiştir.

**Architecture:** SVG tabanlı ikon sistemi — `QIcons` class tüm path sabitleri, `QIcon` widget SvgPicture sarmalayıcısı. Lucide ikonları SVG dosya olarak `assets/icons/` altında `ic_` prefix ile tutulur. Branded/çok renkli görseller `assets/brand/`, dekoratif SVG'ler `assets/illustrations/` altında ayrılır.

**Tech Stack:** Flutter, flutter_svg ^2.0.16, Lucide Icons (SVG download)

---

## Faz 1: Temizlik & Altyapı

### Task 1: Yeni klasör yapısını oluştur

**Files:**
- Create: `assets/brand/` (dizin)
- Create: `assets/illustrations/` (dizin)
- Delete: `assets/fonts/QuloIcon.ttf`
- Modify: `pubspec.yaml:76-88`

**Step 1: Yeni dizinleri oluştur**

```bash
mkdir -p assets/brand assets/illustrations
```

**Step 2: Brand asset'leri taşı**

```bash
# Logo
mv assets/svgShapes/quloSplash.svg assets/brand/qulo_splash.svg

# Diamonds — snake_case ile yeniden adlandır
mv assets/logo/greenDiamondR.svg assets/brand/green_diamond.svg
mv assets/logo/purpleDiamondR.svg assets/brand/purple_diamond.svg
mv assets/logo/greenDiamondSlideToLeft.svg assets/brand/green_diamond_slide_left.svg
mv assets/logo/greenDiamondSlideToRight.svg assets/brand/green_diamond_slide_right.svg
mv assets/logo/slideToLeftPurpleDiamond.svg assets/brand/purple_diamond_slide_left.svg
mv assets/logo/slideToRightPurpleDiomand.svg assets/brand/purple_diamond_slide_right.svg
```

**Step 3: İllüstrasyonları taşı**

```bash
# Dekoratif SVG shape'ler → illustrations/
mv assets/svgShapes/beer.svg assets/illustrations/beer.svg
mv assets/svgShapes/bottomShape.svg assets/illustrations/bottom_shape.svg
mv assets/svgShapes/bottomtTriangle.svg assets/illustrations/bottom_triangle.svg
mv assets/svgShapes/chart.svg assets/illustrations/chart.svg
mv assets/svgShapes/coffee.svg assets/illustrations/coffee.svg
mv assets/svgShapes/curse.svg assets/illustrations/curse.svg
mv assets/svgShapes/direct_pass.svg assets/illustrations/direct_pass.svg
mv assets/svgShapes/giftLog.svg assets/illustrations/gift_log.svg
mv assets/svgShapes/leftCircle.svg assets/illustrations/left_circle.svg
mv assets/svgShapes/no_message.svg assets/illustrations/no_message.svg
mv assets/svgShapes/no_reason.svg assets/illustrations/no_reason.svg
mv assets/svgShapes/rightCircle.svg assets/illustrations/right_circle.svg
mv assets/svgShapes/staticsTop.svg assets/illustrations/statics_top.svg
mv assets/svgShapes/svg_permission_location.svg assets/illustrations/permission_location.svg
mv assets/svgShapes/svg_permission_photo.svg assets/illustrations/permission_photo.svg
mv assets/svgShapes/svg_preview.svg assets/illustrations/preview.svg
mv assets/svgShapes/svg_tracking_permission.svg assets/illustrations/tracking_permission.svg
mv assets/svgShapes/teas.svg assets/illustrations/teas.svg
mv assets/svgShapes/wine.svg assets/illustrations/wine.svg
```

**Step 4: Mevcut ikonları snake_case ile yeniden adlandır**

```bash
# Zaten ic_ prefix olanlar — sadece tutarsız isimleri düzelt
mv assets/icons/gift.svg assets/icons/ic_gift.svg
mv assets/icons/locationSvg.svg assets/icons/ic_location.svg
mv assets/icons/locationTick.svg assets/icons/ic_location_tick.svg
mv assets/icons/photo_camera.svg assets/icons/ic_photo_camera.svg
mv assets/icons/travelSVG.svg assets/icons/ic_travel.svg
mv assets/icons/man.svg assets/icons/ic_male.svg
mv assets/icons/woman.svg assets/icons/ic_female.svg
```

**Step 5: Duplicate ve kullanılmayan dosyaları sil**

```bash
# PNG duplicates (SVG versiyonları var)
rm assets/icons/man.png
rm assets/icons/woman.png
rm assets/icons/lgbt.png
rm assets/icons/message.png

# Kullanılmayan font
rm assets/fonts/QuloIcon.ttf

# Boşaltılmış eski dizinleri temizle
rmdir assets/svgShapes/ 2>/dev/null || true
rmdir assets/logo/ 2>/dev/null || true
```

**Step 6: pubspec.yaml'ı güncelle**

`pubspec.yaml:76-88` bölümünü şu şekilde güncelle:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/icons/
    - assets/brand/
    - assets/illustrations/
    - assets/lottie/

  fonts:
    - family: Helvetica
      fonts:
        - asset: assets/fonts/Helvetica.ttc
```

QuloIcon font deklarasyonunu kaldır.

**Step 7: Uygulamayı derle, hata olmadığından emin ol**

```bash
flutter analyze
```

**Step 8: Commit**

```bash
git add -A
git commit -m "refactor: reorganize asset folders, rename to snake_case, remove unused files"
```

---

### Task 2: QIcons sabitleri class'ını oluştur

**Files:**
- Create: `lib/core/constants/q_icons.dart`
- Modify: `lib/core/constants/app_assets.dart`

**Step 1: QIcons class'ını yaz**

Create `lib/core/constants/q_icons.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Qulo ikon sabitleri.
/// Tüm SVG ikon path'leri burada merkezi olarak tanımlanır.
abstract final class QIcons {
  // ─── Navigation ───
  static const icCompass = 'assets/icons/ic_compass.svg';
  static const icHeart = 'assets/icons/ic_heart.svg';
  static const icUser = 'assets/icons/ic_user.svg';

  // ─── Actions ───
  static const icSend = 'assets/icons/ic_send.svg';
  static const icX = 'assets/icons/ic_x.svg';
  static const icPlus = 'assets/icons/ic_plus.svg';
  static const icPencil = 'assets/icons/ic_pencil.svg';
  static const icTrash2 = 'assets/icons/ic_trash_2.svg';
  static const icLogOut = 'assets/icons/ic_log_out.svg';
  static const icArrowLeft = 'assets/icons/ic_arrow_left.svg';
  static const icChevronRight = 'assets/icons/ic_chevron_right.svg';
  static const icCheckCircle = 'assets/icons/ic_check_circle.svg';

  // ─── Powers (Quiz) ───
  static const icCopy = 'assets/icons/ic_copy.svg';
  static const icSplit = 'assets/icons/ic_split.svg';
  static const icSkipForward = 'assets/icons/ic_skip_forward.svg';
  static const icLightbulb = 'assets/icons/ic_lightbulb.svg';
  static const icClock = 'assets/icons/ic_clock.svg';
  static const icFastForward = 'assets/icons/ic_fast_forward.svg';

  // ─── Status / Info ───
  static const icGem = 'assets/icons/ic_gem.svg';
  static const icEye = 'assets/icons/ic_eye.svg';
  static const icEyeOff = 'assets/icons/ic_eye_off.svg';
  static const icZap = 'assets/icons/ic_zap.svg';
  static const icMapPin = 'assets/icons/ic_map_pin.svg';
  static const icGlobe = 'assets/icons/ic_globe.svg';
  static const icHelpCircle = 'assets/icons/ic_help_circle.svg';
  static const icSettings = 'assets/icons/ic_settings.svg';
  static const icLock = 'assets/icons/ic_lock.svg';
  static const icMail = 'assets/icons/ic_mail.svg';
  static const icCake = 'assets/icons/ic_cake.svg';
  static const icCalendar = 'assets/icons/ic_calendar.svg';
  static const icUserOutline = 'assets/icons/ic_user_outline.svg';

  // ─── Discover ───
  static const icCompassOff = 'assets/icons/ic_compass_off.svg';
  static const icPlane = 'assets/icons/ic_plane.svg';
  static const icLocationCity = 'assets/icons/ic_building_2.svg';

  // ─── Gender ───
  static const icMale = 'assets/icons/ic_male.svg';
  static const icFemale = 'assets/icons/ic_female.svg';
  static const icTransgender = 'assets/icons/ic_transgender.svg';

  // ─── Diamond (add/remove indicators) ───
  static const icPlusCircle = 'assets/icons/ic_plus_circle.svg';
  static const icMinusCircle = 'assets/icons/ic_minus_circle.svg';

  // ─── Qulo Domain-Specific (mevcut V1 ikonlar) ───
  static const icGift = 'assets/icons/ic_gift.svg';
  static const icChats = 'assets/icons/ic_chats.svg';
  static const icCity = 'assets/icons/ic_city.svg';
  static const icDirectlyPass = 'assets/icons/ic_directly_pass.svg';
  static const icEditBio = 'assets/icons/ic_edit_bio.svg';
  static const icGenerally = 'assets/icons/ic_generally.svg';
  static const icHobbies = 'assets/icons/ic_hobbies.svg';
  static const icHobby = 'assets/icons/ic_hobby.svg';
  static const icJob = 'assets/icons/ic_job.svg';
  static const icMusic = 'assets/icons/ic_music.svg';
  static const icPets = 'assets/icons/ic_pets.svg';
  static const icSchool = 'assets/icons/ic_school.svg';
  static const icSmoke = 'assets/icons/ic_smoke.svg';
  static const icTouch = 'assets/icons/ic_touch.svg';
  static const icUseAlcohol = 'assets/icons/ic_use_alcohol.svg';
  static const icWho = 'assets/icons/ic_who.svg';
  static const icZodiac = 'assets/icons/ic_zodiac.svg';
  static const icLocation = 'assets/icons/ic_location.svg';
  static const icLocationTick = 'assets/icons/ic_location_tick.svg';
  static const icPhotoCamera = 'assets/icons/ic_photo_camera.svg';
  static const icTravel = 'assets/icons/ic_travel.svg';
}
```

**Step 2: AppAssets'i güncelle — ikonları QIcons'a yönlendir, brand/illustration path'lerini güncelle**

`lib/core/constants/app_assets.dart` dosyasını tamamen yeniden yaz:

```dart
abstract final class AppAssets {
  // ─── Brand ───
  static const logoSvg = 'assets/brand/qulo_splash.svg';
  static const greenDiamond = 'assets/brand/green_diamond.svg';
  static const purpleDiamond = 'assets/brand/purple_diamond.svg';
  static const greenDiamondSlideLeft = 'assets/brand/green_diamond_slide_left.svg';
  static const greenDiamondSlideRight = 'assets/brand/green_diamond_slide_right.svg';
  static const purpleDiamondSlideLeft = 'assets/brand/purple_diamond_slide_left.svg';
  static const purpleDiamondSlideRight = 'assets/brand/purple_diamond_slide_right.svg';

  // ─── Lottie ───
  static const lottieBoardQuestion = 'assets/lottie/boardQuestion.json';
  static const lottieBuyDiamond = 'assets/lottie/buydiamond.json';
  static const lottieCarryMan = 'assets/lottie/carryMan.json';
  static const lottieGiftBox = 'assets/lottie/giftBox.json';
  static const lottieLocation = 'assets/lottie/location.json';
  static const lottieRadar = 'assets/lottie/lottie_radar.json';
  static const lottieNoConnection = 'assets/lottie/noConnectionCat.json';
  static const lottieStatics = 'assets/lottie/statics_lottie.json';
  static const lottieStaticsSecond = 'assets/lottie/statics_lottie_second.json';
  static const lottieSubscribe = 'assets/lottie/subscribe.json';

  // ─── Illustrations ───
  static const illustBeer = 'assets/illustrations/beer.svg';
  static const illustBottomShape = 'assets/illustrations/bottom_shape.svg';
  static const illustBottomTriangle = 'assets/illustrations/bottom_triangle.svg';
  static const illustChart = 'assets/illustrations/chart.svg';
  static const illustCoffee = 'assets/illustrations/coffee.svg';
  static const illustCurse = 'assets/illustrations/curse.svg';
  static const illustDirectPass = 'assets/illustrations/direct_pass.svg';
  static const illustGiftLog = 'assets/illustrations/gift_log.svg';
  static const illustLeftCircle = 'assets/illustrations/left_circle.svg';
  static const illustNoMessage = 'assets/illustrations/no_message.svg';
  static const illustNoReason = 'assets/illustrations/no_reason.svg';
  static const illustRightCircle = 'assets/illustrations/right_circle.svg';
  static const illustStaticsTop = 'assets/illustrations/statics_top.svg';
  static const illustPermissionLocation = 'assets/illustrations/permission_location.svg';
  static const illustPermissionPhoto = 'assets/illustrations/permission_photo.svg';
  static const illustPreview = 'assets/illustrations/preview.svg';
  static const illustTrackingPermission = 'assets/illustrations/tracking_permission.svg';
  static const illustTeas = 'assets/illustrations/teas.svg';
  static const illustWine = 'assets/illustrations/wine.svg';
}
```

**Step 3: Eski AppAssets referanslarını güncelle**

Sadece 2 dosyada `AppAssets.logoSvg` kullanılıyor — path değiştiği için otomatik çalışacak (AppAssets'teki sabit güncellendi).

Kontrol et: `grep -r "AppAssets\." lib/` çıktısında başka referans varsa güncelle.

**Step 4: Commit**

```bash
git add lib/core/constants/q_icons.dart lib/core/constants/app_assets.dart
git commit -m "feat: create QIcons class and update AppAssets paths"
```

---

### Task 3: QIcon widget'ını oluştur

**Files:**
- Create: `lib/core/widgets/q_icon.dart`

**Step 1: QIcon widget'ını yaz**

Create `lib/core/widgets/q_icon.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Qulo SVG ikon widget'ı.
/// Material Icon yerine SVG asset render eder.
/// [color] verilmezse tema ikonColor kullanılır.
class QIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;

  const QIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color;
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: iconColor != null
          ? ColorFilter.mode(iconColor, BlendMode.srcIn)
          : null,
    );
  }
}
```

**Step 2: flutter analyze**

```bash
flutter analyze
```
Expected: No issues.

**Step 3: Commit**

```bash
git add lib/core/widgets/q_icon.dart
git commit -m "feat: add QIcon widget as SvgPicture wrapper"
```

---

### Task 4: Lucide SVG ikonlarını indir

**Files:**
- Create: 30+ SVG dosya `assets/icons/` altında

**Step 1: Lucide ikonlarını indir**

Her ikon için Lucide GitHub raw SVG'sini indir. Lucide SVG'leri 24x24 viewport, stroke-based, tek renkli.

```bash
cd assets/icons

# Navigation
curl -sL "https://unpkg.com/lucide-static@latest/icons/compass.svg" -o ic_compass.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/heart.svg" -o ic_heart.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/user.svg" -o ic_user.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/user-round.svg" -o ic_user_outline.svg

# Actions
curl -sL "https://unpkg.com/lucide-static@latest/icons/send.svg" -o ic_send.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/x.svg" -o ic_x.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/plus.svg" -o ic_plus.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/pencil.svg" -o ic_pencil.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/trash-2.svg" -o ic_trash_2.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/log-out.svg" -o ic_log_out.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/arrow-left.svg" -o ic_arrow_left.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/chevron-right.svg" -o ic_chevron_right.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/check-circle.svg" -o ic_check_circle.svg

# Powers (Quiz)
curl -sL "https://unpkg.com/lucide-static@latest/icons/copy.svg" -o ic_copy.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/split.svg" -o ic_split.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/skip-forward.svg" -o ic_skip_forward.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/lightbulb.svg" -o ic_lightbulb.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/clock.svg" -o ic_clock.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/fast-forward.svg" -o ic_fast_forward.svg

# Status / Info
curl -sL "https://unpkg.com/lucide-static@latest/icons/gem.svg" -o ic_gem.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/eye.svg" -o ic_eye.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/eye-off.svg" -o ic_eye_off.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/zap.svg" -o ic_zap.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/map-pin.svg" -o ic_map_pin.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/globe.svg" -o ic_globe.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/circle-help.svg" -o ic_help_circle.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/settings.svg" -o ic_settings.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/lock.svg" -o ic_lock.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/mail.svg" -o ic_mail.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/cake.svg" -o ic_cake.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/calendar.svg" -o ic_calendar.svg

# Discover
curl -sL "https://unpkg.com/lucide-static@latest/icons/compass-off.svg" -o ic_compass_off.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/plane.svg" -o ic_plane.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/building-2.svg" -o ic_building_2.svg

# Diamond indicators
curl -sL "https://unpkg.com/lucide-static@latest/icons/plus-circle.svg" -o ic_plus_circle.svg
curl -sL "https://unpkg.com/lucide-static@latest/icons/minus-circle.svg" -o ic_minus_circle.svg

cd ../..
```

NOT: `ic_male.svg`, `ic_female.svg`, `ic_transgender.svg` — bunlar Lucide'de yok. Mevcut `man.svg`/`woman.svg` dosyaları zaten Task 1'de `ic_male.svg`/`ic_female.svg` olarak adlandırıldı. `ic_transgender.svg` için mevcut Material icon kullanılmaya devam edecek veya basit bir SVG oluşturulacak.

**Step 2: SVG dosyalarını doğrula**

```bash
ls -la assets/icons/ic_*.svg | wc -l
```
Expected: 35+ dosya

**Step 3: Commit**

```bash
git add assets/icons/
git commit -m "feat: add Lucide SVG icons for Qulo icon system"
```

---

## Faz 2: Kritik Ekranlarda Lucide Geçişi

### Task 5: Bottom Navigation geçişi

**Files:**
- Modify: `lib/routing/app_routes.dart:136-140`

**Step 1: Import ekle ve ikonları değiştir**

`lib/routing/app_routes.dart` dosyasında:

Import ekle:
```dart
import '../core/widgets/q_icon.dart';
import '../core/constants/q_icons.dart';
```

Satır 136-140'ı değiştir:

```dart
destinations: [
  NavigationDestination(icon: QIcon(QIcons.icCompass, size: 24), label: 'Discover'),
  NavigationDestination(icon: QIcon(QIcons.icHeart, size: 24), label: 'Matches'),
  NavigationDestination(icon: QIcon(QIcons.icUser, size: 24), label: 'Profile'),
],
```

NOT: `const` kaldırılacak çünkü QIcon widget const constructor ile oluşturulamayabilir (SvgPicture.asset const değil).

**Step 2: flutter analyze**

```bash
flutter analyze
```

**Step 3: Commit**

```bash
git add lib/routing/app_routes.dart
git commit -m "feat: replace Material icons with Lucide SVGs in bottom navigation"
```

---

### Task 6: Profile Screen geçişi

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`

**Step 1: Import ekle**

```dart
import '../../../core/widgets/q_icon.dart';
import '../../../core/constants/q_icons.dart';
```

**Step 2: _StatCard widget'ını güncelle**

`_StatCard` class'ında `IconData icon` → `String iconPath` olarak değiştir:

```dart
class _StatCard extends StatelessWidget {
  final String iconPath;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.iconPath, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          QIcon(iconPath, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 3: _MenuItem widget'ını güncelle**

```dart
class _MenuItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback onTap;
  const _MenuItem({required this.iconPath, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: QIcon(iconPath, color: AppColors.primary, size: 24),
        title: Text(title),
        trailing: QIcon(QIcons.icChevronRight, color: AppColors.textHint, size: 20),
        onTap: onTap,
      ),
    );
  }
}
```

**Step 4: Build method'daki referansları güncelle**

Satır 37:
```dart
icon: QIcon(QIcons.icSettings, color: AppColors.textSecondary, size: 24),
```
NOT: `IconButton`'ın `icon` parametresi `Widget` kabul eder, QIcon da Widget olduğu için çalışır.

Satır 62:
```dart
child: QIcon(QIcons.icUser, color: AppColors.textHint, size: 80),
```

Satır 88-91 (stat cards):
```dart
_StatCard(iconPath: QIcons.icHeart, value: '${user.likeReceivedCount}', label: context.tr('likes'), color: AppColors.primary),
_StatCard(iconPath: QIcons.icEye, value: '${user.timesShownCount}', label: context.tr('views'), color: AppColors.secondary),
_StatCard(iconPath: QIcons.icGem, value: '${user.purpleDiamonds}', label: context.tr('purple_diamonds'), color: AppColors.primary),
_StatCard(iconPath: QIcons.icGem, value: '${user.greenDiamonds}', label: context.tr('green_diamonds'), color: AppColors.secondary),
```

Satır 107-110 (menu items):
```dart
_MenuItem(iconPath: QIcons.icPencil, title: context.tr('edit_profile'), onTap: () => context.goNamed(RouteNames.editProfile)),
_MenuItem(iconPath: QIcons.icHelpCircle, title: context.tr('my_questions'), onTap: () => context.goNamed(RouteNames.questions)),
_MenuItem(iconPath: QIcons.icGem, title: context.tr('diamonds'), onTap: () => context.goNamed(RouteNames.diamonds)),
_MenuItem(iconPath: QIcons.icPlane, title: context.tr('passport'), onTap: () => context.goNamed(RouteNames.passport)),
```

**Step 5: flutter analyze**

```bash
flutter analyze
```

**Step 6: Commit**

```bash
git add lib/features/profile/screens/profile_screen.dart
git commit -m "feat: replace Material icons with Lucide SVGs in profile screen"
```

---

### Task 7: Discover Screen geçişi

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`
- Modify: `lib/features/discover/widgets/profile_card.dart`

**Step 1: discover_screen.dart — Import ekle ve ikonları değiştir**

Import:
```dart
import '../../../core/widgets/q_icon.dart';
import '../../../core/constants/q_icons.dart';
```

Satır 43 (empty state):
```dart
QIcon(QIcons.icCompassOff, size: 64, color: AppColors.textHint),
```

`_ActionButton` class'ında `IconData icon` → `String iconPath`:

```dart
class _ActionButton extends StatelessWidget {
  final String iconPath;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.iconPath,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    this.size = 56,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [BoxShadow(color: borderColor.withValues(alpha: 0.2), blurRadius: 8)],
        ),
        child: Center(child: QIcon(iconPath, color: iconColor, size: size * 0.5)),
      ),
    );
  }
}
```

Satır 91, 103 (action buttons):
```dart
_ActionButton(
  iconPath: QIcons.icX,
  // ... geri kalan aynı
),
_ActionButton(
  iconPath: QIcons.icHeart,
  // ... geri kalan aynı
),
```

**Step 2: profile_card.dart — Import ekle ve ikonları değiştir**

Import:
```dart
import '../../../core/widgets/q_icon.dart';
import '../../../core/constants/q_icons.dart';
```

Satır 25 (placeholder):
```dart
QIcon(QIcons.icUser, color: AppColors.textHint, size: 80),
```

Satır 55 (boost):
```dart
QIcon(QIcons.icZap, color: AppColors.warning, size: 20),
```

Satır 63 (location):
```dart
QIcon(QIcons.icMapPin, color: Colors.white70, size: 16),
```

**Step 3: flutter analyze**

```bash
flutter analyze
```

**Step 4: Commit**

```bash
git add lib/features/discover/
git commit -m "feat: replace Material icons with Lucide SVGs in discover screen"
```

---

### Task 8: Quiz Power Bar geçişi

**Files:**
- Modify: `lib/features/quiz/widgets/power_bar.dart`
- Modify: `lib/features/quiz/screens/quiz_screen.dart`

**Step 1: power_bar.dart — SVG path'leri kullan**

Import:
```dart
import '../../../core/widgets/q_icon.dart';
import '../../../core/constants/q_icons.dart';
```

`_powers` listesini `IconData` yerine `String` path ile değiştir:

```dart
static const _powers = [
  ('COPY', QIcons.icCopy, 'power_copy'),
  ('HALF', QIcons.icSplit, 'power_half'),
  ('SKIP', QIcons.icSkipForward, 'power_skip'),
  ('HINT', QIcons.icLightbulb, 'power_hint'),
  ('TIME_EXTEND', QIcons.icClock, 'power_time'),
  ('SKIP_ALL', QIcons.icFastForward, 'power_skip_all'),
];
```

Build method'da `Icon(p.$2, ...)` → `QIcon(p.$2, ...)`:

```dart
avatar: QIcon(p.$2, size: 18, color: AppColors.primaryDark),
```

**Step 2: quiz_screen.dart — ikonları değiştir**

Import:
```dart
import '../../../core/widgets/q_icon.dart';
import '../../../core/constants/q_icons.dart';
```

Satır 58 (result dialog heart):
```dart
QIcon(QIcons.icHeart, ...)
```

Satır 90 (close button):
```dart
QIcon(QIcons.icX, ...)
```

**Step 3: flutter analyze**

```bash
flutter analyze
```

**Step 4: Commit**

```bash
git add lib/features/quiz/
git commit -m "feat: replace Material icons with Lucide SVGs in quiz screen"
```

---

### Task 9: Faz 2 doğrulama

**Step 1: Tam analiz**

```bash
flutter analyze
```
Expected: No issues

**Step 2: Kullanılmayan Material icon import'larını kontrol et**

```bash
grep -rn "Icons\." lib/routing/app_routes.dart lib/features/profile/screens/profile_screen.dart lib/features/discover/ lib/features/quiz/
```
Expected: Hiç Material icon kalmamalı (bu dosyalarda).

**Step 3: Uygulamayı çalıştır ve görsel doğrulama yap**

```bash
flutter run
```

Kontrol listesi:
- [ ] Bottom navigation ikonları görünüyor
- [ ] Profile screen stat card ikonları görünüyor
- [ ] Profile menu item ikonları görünüyor
- [ ] Discover empty state ikonu görünüyor
- [ ] Discover action button ikonları görünüyor
- [ ] Profile card boost/location ikonları görünüyor
- [ ] Quiz power bar ikonları görünüyor

**Step 4: Commit (eğer düzeltme yapıldıysa)**

```bash
git add -A
git commit -m "fix: visual verification fixes for Lucide icon migration"
```

---

## Faz 3: Geri Kalan Ekranlar (Sonraki İterasyon)

Bu faz şimdi implementasyona dahil DEĞİL. Faz 2 tamamlandıktan sonra ayrı task olarak planlanacak.

Kalan dosyalar ve ikonları:
- `lib/features/settings/screens/settings_screen.dart` — language, logout, delete_forever
- `lib/features/auth/screens/login_screen.dart` — email, lock, visibility
- `lib/features/auth/screens/register_screen.dart` — arrow_back
- `lib/features/auth/widgets/register_step_email.dart` — email, lock, visibility
- `lib/features/auth/widgets/register_step_name.dart` — person_outline
- `lib/features/auth/widgets/register_step_gender.dart` — male, female, transgender, check_circle
- `lib/features/auth/widgets/register_step_location.dart` — check_circle, location_on_outlined
- `lib/features/auth/screens/forgot_password_screen.dart` — email
- `lib/features/diamonds/screens/diamonds_screen.dart` — diamond, add_circle, remove_circle
- `lib/features/chat/screens/chat_screen.dart` — send
- `lib/features/chat/screens/matches_screen.dart` — favorite_border, person
- `lib/features/onboarding/screens/onboarding_screen.dart` — favorite, quiz, person
- `lib/features/passport/screens/passport_screen.dart` — flight, location_city
- `lib/features/profile/screens/questions_screen.dart` — add, delete_outline
- `lib/core/widgets/app_date_picker.dart` — cake_outlined, calendar_today_outlined
