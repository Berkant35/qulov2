# Qulo V2 UI Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Mevcut acik temali Material 3 UI'i, koyu temali neon aksanli dating app tasarimina donusturmek.

**Architecture:** Tema dosyalari (colors, theme, components) guncellenerek tum uygulamaya yayilir. Ekranlar tek tek koyu tema uyumlu hale getirilir. Provider/repository/service yapisi degismez.

**Tech Stack:** Flutter, Riverpod, GoRouter, Material 3

---

## Task 1: Koyu Tema — Renk Sistemi

**Files:**
- Modify: `lib/core/theme/app_colors.dart`

**Step 1: AppColors'i koyu tema renkleriyle degistir**

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // ─── Background & Surface ───
  static const background = Color(0xFF0D0D0D);
  static const scaffold = Color(0xFF121212);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF242424);
  static const surfaceInput = Color(0xFF2A2A2A);

  // ─── Primary (Mor Neon) ───
  static const primary = Color(0xFFBB86FC);
  static const primaryDark = Color(0xFF9C27B0);
  static const primaryLight = Color(0xFFE1BEE7);
  static const primarySurface = Color(0x1ABB86FC); // 10% opacity

  // ─── Secondary (Yesil Neon) ───
  static const secondary = Color(0xFF69F0AE);
  static const secondaryDark = Color(0xFF4CAF50);
  static const secondaryLight = Color(0xFFB9F6CA);
  static const secondarySurface = Color(0x1A69F0AE); // 10% opacity

  // ─── Semantic ───
  static const error = Color(0xFFCF6679);
  static const success = Color(0xFF69F0AE);
  static const warning = Color(0xFFFFB74D);
  static const info = Color(0xFF64B5F6);

  // ─── Text ───
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textHint = Color(0xFF666666);

  // ─── Border & Divider ───
  static const border = Color(0xFF2A2A2A);
  static const divider = Color(0xFF2A2A2A);

  // ─── Gradients ───
  static const purpleGradient = LinearGradient(
    colors: [Color(0xFFBB86FC), Color(0xFF9C27B0)],
  );

  static const greenGradient = LinearGradient(
    colors: [Color(0xFF69F0AE), Color(0xFF4CAF50)],
  );

  static const primaryButtonGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
  );
}
```

**Step 2: Hot reload ve gorsel dogrulama**

Run: `flutter run` (zaten calisan app'te hot reload)
Expected: Arka planlar koyulasir, renkler degisir

**Step 3: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat: update color system to dark theme with neon accents"
```

---

## Task 2: Koyu Tema — TextStyles & Theme

**Files:**
- Modify: `lib/core/theme/app_text_styles.dart`
- Modify: `lib/core/theme/app_theme.dart`
- Modify: `lib/core/theme/app_theme_components.dart`

**Step 1: app_text_styles.dart — beyaz metin renkleri**

Tum text style'larda `color` property'lerini guncelle:
- Display/Headline/Title: `AppColors.textPrimary` (#FFFFFF)
- Body: `AppColors.textPrimary`
- Label: `AppColors.textSecondary` (#B0B0B0)

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
    titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textHint),
  );
}
```

**Step 2: app_theme.dart — ColorScheme ve scaffold renkleri**

ColorScheme'i koyu tema icin guncelle:

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

part 'app_theme_components.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    textTheme: AppTextStyles.textTheme,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.black,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerHighest: AppColors.surfaceInput,
    ),
    scaffoldBackgroundColor: AppColors.scaffold,
    dividerColor: AppColors.divider,
    appBarTheme: _appBarTheme,
    elevatedButtonTheme: _elevatedButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
    cardTheme: _cardTheme,
    bottomNavigationBarTheme: _bottomNavTheme,
    navigationBarTheme: _navigationBarTheme,
    chipTheme: _chipTheme,
    dialogTheme: _dialogTheme,
    snackBarTheme: _snackBarTheme,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearMinHeight: 4,
      linearTrackColor: AppColors.surfaceInput,
    ),
  );
}
```

**Step 3: app_theme_components.dart — Komponent temalari koyu yap**

```dart
part of 'app_theme.dart';

// ─── AppBar ───
const _appBarTheme = AppBarTheme(
  backgroundColor: AppColors.scaffold,
  foregroundColor: AppColors.textPrimary,
  elevation: 0,
  centerTitle: true,
  titleTextStyle: TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ),
);

// ─── ElevatedButton ───
final _elevatedButtonTheme = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryDark,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
);

// ─── OutlinedButton ───
final _outlinedButtonTheme = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary),
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
);

// ─── TextButton ───
final _textButtonTheme = TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),
);

// ─── TextField ───
final _inputDecorationTheme = InputDecorationTheme(
  filled: true,
  fillColor: AppColors.surfaceInput,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.primary, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.error),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.error, width: 2),
  ),
  hintStyle: const TextStyle(color: AppColors.textHint),
  labelStyle: const TextStyle(color: AppColors.textSecondary),
  errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
);

// ─── Card ───
final _cardTheme = CardThemeData(
  color: AppColors.surface,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: AppColors.border, width: 0.5),
  ),
);

// ─── BottomNavigationBar (legacy) ───
const _bottomNavTheme = BottomNavigationBarThemeData(
  backgroundColor: AppColors.surface,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textHint,
  type: BottomNavigationBarType.fixed,
  elevation: 0,
);

// ─── NavigationBar (Material 3) ───
final _navigationBarTheme = NavigationBarThemeData(
  backgroundColor: AppColors.surface,
  indicatorColor: AppColors.primarySurface,
  elevation: 0,
  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
  iconTheme: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return const IconThemeData(color: AppColors.primary);
    }
    return const IconThemeData(color: AppColors.textHint);
  }),
  labelTextStyle: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      );
    }
    return const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      color: AppColors.textHint,
    );
  }),
);

// ─── Chip ───
final _chipTheme = ChipThemeData(
  backgroundColor: AppColors.surface,
  selectedColor: AppColors.primarySurface,
  side: const BorderSide(color: AppColors.border),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
  labelStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: AppColors.textPrimary,
  ),
);

// ─── Dialog ───
final _dialogTheme = DialogThemeData(
  backgroundColor: AppColors.surfaceElevated,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  titleTextStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ),
  contentTextStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: AppColors.textSecondary,
  ),
);

// ─── SnackBar ───
final _snackBarTheme = SnackBarThemeData(
  backgroundColor: AppColors.surfaceElevated,
  contentTextStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: AppColors.textPrimary,
  ),
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);
```

**Step 4: Hot reload ve gorsel dogrulama**

Tum ekranlar koyu temaya gecmeli. Scaffold, AppBar, kartlar, butonlar, input'lar hepsi koyu.

**Step 5: Commit**

```bash
git add lib/core/theme/
git commit -m "feat: apply dark theme with neon accents across theme system"
```

---

## Task 3: AppScaffold — Koyu Arka Plan

**Files:**
- Modify: `lib/core/widgets/app_scaffold.dart`

**Step 1: BackgroundPainter renklerini koyu tema neon gradient'lere guncelle**

Mor gradient: `AppColors.primary` %6 opacity (siyah uzerinde subtle)
Yesil gradient: `AppColors.secondary` %4 opacity

```dart
// BackgroundPainter icindeki _paintCircle cagrilarini guncelle:
// Mor daire (sag ust): color = AppColors.primary.withValues(alpha: 0.06)
// Yesil daire (sol alt): color = AppColors.secondary.withValues(alpha: 0.04)
```

Ayrica scaffold'un `backgroundColor`'ini `AppColors.scaffold` yap:
```dart
backgroundColor: widget.backgroundColor ?? AppColors.scaffold,
```

**Step 2: Hot reload, arka plan rengi dogrula**

**Step 3: Commit**

```bash
git add lib/core/widgets/app_scaffold.dart
git commit -m "feat: update AppScaffold to dark theme background"
```

---

## Task 4: Core Widgets — Koyu Tema Uyumu

**Files:**
- Modify: `lib/core/widgets/app_button.dart`
- Modify: `lib/core/widgets/app_text_field.dart`
- Modify: `lib/core/widgets/app_date_picker.dart`
- Modify: `lib/core/widgets/app_progress_bar.dart`

**Step 1: app_button.dart — Gradient buton desteği ekle**

Primary buton icin gradient Container wrapper ekle:

```dart
// Primary variant icinde ElevatedButton'u gradient Container ile sar:
if (variant == AppButtonVariant.primary) {
  return Container(
    decoration: BoxDecoration(
      gradient: isLoading ? null : AppColors.primaryButtonGradient,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: _buildChild(),
    ),
  );
}
```

**Step 2: app_text_field.dart — Koyu tema uyumu kontrol et**

Input zaten theme'den stil aliyor. Sadece label/hint text renklerini kontrol et:
- Label: `AppColors.textSecondary`
- Error: `AppColors.error`

Eger hardcoded renk varsa guncelle.

**Step 3: app_date_picker.dart — DatePicker dialog koyu tema**

DatePicker dialog'unu koyu temaya uyumlu yap:
```dart
// showDatePicker icinde theme override:
builder: (context, child) {
  return Theme(
    data: Theme.of(context).copyWith(
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceElevated,
        headerBackgroundColor: AppColors.primaryDark,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStatePropertyAll(AppColors.textPrimary),
        yearForegroundColor: WidgetStatePropertyAll(AppColors.textPrimary),
      ),
    ),
    child: child!,
  );
},
```

**Step 4: app_progress_bar.dart — Mor neon progress**

Theme'den renk aliyorsa otomatik degisir. Kontrol et, gerekirse:
```dart
color: AppColors.primary,
backgroundColor: AppColors.surfaceInput,
```

**Step 5: Hot reload, tum widget'lari gorsel dogrula**

**Step 6: Commit**

```bash
git add lib/core/widgets/
git commit -m "feat: update core widgets for dark theme compatibility"
```

---

## Task 5: Bottom Navigation — Koyu Tema + Mor Cizgi

**Files:**
- Modify: `lib/routing/app_routes.dart`

**Step 1: _MainShell widget'indaki NavigationBar'i guncelle**

```dart
// _MainShell build metodu icinde NavigationBar'i Column ile sar:
bottomNavigationBar: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      height: 1,
      color: AppColors.primary.withValues(alpha: 0.3),
    ),
    NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (i) => navigationShell.goBranch(i),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.explore_outlined),
          selectedIcon: const Icon(Icons.explore),
          label: context.tr('discover'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_outline),
          selectedIcon: const Icon(Icons.favorite),
          label: context.tr('matches'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: context.tr('profile'),
        ),
      ],
    ),
  ],
),
```

AppColors import'unu ekle dosyanin basina.

**Step 2: Hot reload, bottom nav koyu + mor cizgi gorsel dogrula**

**Step 3: Commit**

```bash
git add lib/routing/app_routes.dart
git commit -m "feat: update bottom navigation to dark theme with purple accent line"
```

---

## Task 6: Splash Ekrani — Koyu Tema + Neon Glow

**Files:**
- Modify: `lib/features/splash/splash_screen.dart`

**Step 1: Splash'i koyu arka plan + neon glow efektiyle guncelle**

- `AppScaffold` backgroundColor: `AppColors.background` (siyah)
- Logo etrafina mor neon glow efekti (BoxDecoration + boxShadow):
```dart
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.3),
        blurRadius: 60,
        spreadRadius: 20,
      ),
    ],
  ),
  child: /* logo widget */,
),
```
- "QULO" text: beyaz, letterSpacing: 4

**Step 2: Hot reload, gorsel dogrula**

**Step 3: Commit**

```bash
git add lib/features/splash/splash_screen.dart
git commit -m "feat: update splash screen to dark theme with neon glow"
```

---

## Task 7: Login Ekrani — Koyu Tema

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart`

**Step 1: Login ekranini koyu tema'ya uyumlu yap**

- AppScaffold zaten koyu (Task 3'te guncellendi)
- Logo: Beyaz/neon renkli (SVG fill guncellenmesi gerekebilir)
- Input'lar: Theme'den koyu stil alacak (Task 2)
- Hata mesaji: `AppColors.error` rengi
- "Sifremi Unuttum" link: `AppColors.primary` (mor neon)
- Login butonu: Gradient (Task 4'te eklendi)
- Register link: `AppColors.primary`
- Hardcoded acik tema renklerini kaldir (varsa)

Kontrol et: Eger input veya buton widget'larinda hardcoded beyaz/acik renkler varsa `AppColors` ile degistir.

**Step 2: Hot reload, gorsel dogrula**

**Step 3: Commit**

```bash
git add lib/features/auth/screens/login_screen.dart
git commit -m "feat: update login screen to dark theme"
```

---

## Task 8: Register Ekrani + Step Widgets — Koyu Tema

**Files:**
- Modify: `lib/features/auth/screens/register_screen.dart`
- Modify: `lib/features/auth/widgets/register_step_name.dart`
- Modify: `lib/features/auth/widgets/register_step_birthday.dart`
- Modify: `lib/features/auth/widgets/register_step_gender.dart`
- Modify: `lib/features/auth/widgets/register_step_location.dart`
- Modify: `lib/features/auth/widgets/register_step_email.dart`
- Modify: `lib/features/auth/widgets/register_step_terms.dart`

**Step 1: register_screen.dart — Progress bar ve arka plan**

- AppScaffold zaten koyu
- Progress bar: Mor neon (theme'den gelir)
- Back butonu icon rengi: beyaz (theme'den gelir)

**Step 2: Gender kartlari koyu tema**

`register_step_gender.dart` icinde `_GenderCard`:
```dart
// Secili: mor border + mor glow
Container(
  decoration: BoxDecoration(
    color: isSelected ? AppColors.primarySurface : AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isSelected ? AppColors.primary : AppColors.border,
      width: isSelected ? 2 : 1,
    ),
    boxShadow: isSelected ? [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.2),
        blurRadius: 12,
      ),
    ] : null,
  ),
  // ...
)
```

**Step 3: Diger step widget'lari — hardcoded renkleri temizle**

Her step widget'inda:
- Beyaz/acik arka plan referanslarini kaldir
- Metin renkleri theme'den gelsin
- Error text: `AppColors.error`
- Ikon renkleri: `AppColors.primary` veya `AppColors.textSecondary`

**Step 4: Hot reload, tum 6 step'i gorsel dogrula**

**Step 5: Commit**

```bash
git add lib/features/auth/
git commit -m "feat: update register flow to dark theme with neon accents"
```

---

## Task 9: Forgot Password Ekrani — Koyu Tema

**Files:**
- Modify: `lib/features/auth/screens/forgot_password_screen.dart`

**Step 1: Hardcoded acik tema renklerini kaldir**

- AppScaffold + input + buton theme'den stil alir
- Varsa hardcoded renkler `AppColors` ile degistir

**Step 2: Hot reload, gorsel dogrula**

**Step 3: Commit**

```bash
git add lib/features/auth/screens/forgot_password_screen.dart
git commit -m "feat: update forgot password screen to dark theme"
```

---

## Task 10: Discover Ekrani — Hybrid Swipe + Quiz

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`
- Modify: `lib/features/discover/widgets/profile_card.dart`

**Step 1: discover_screen.dart — Koyu tema + quiz butonu**

- Arka plan: Koyu (AppScaffold'tan gelir)
- Reject butonu: Koyu arka plan, kirmizi border/ikon
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    shape: BoxShape.circle,
    border: Border.all(color: AppColors.error, width: 2),
  ),
  child: Icon(Icons.close, color: AppColors.error),
)
```
- Accept butonu: Koyu arka plan, yesil border/ikon (ayni pattern)
- Kart altina gradient CTA buton ekle: "Tanimak icin X soruyu coz"
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  decoration: BoxDecoration(
    gradient: AppColors.primaryButtonGradient,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => /* navigate to quiz */,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          '${l10n.get("solve_to_meet")} ${card.questionCount} ${l10n.get("questions_lower")}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    ),
  ),
),
```

- Empty state: Koyu arka plan, gri ikon, beyaz metin

**Step 2: profile_card.dart — Koyu overlay + soru badge**

- Gradient overlay: Daha koyu (siyah %70 → transparent)
- Soru sayisi badge: Mor pill (#BB86FC %20 arka plan, beyaz metin)
- Metin renkleri: Beyaz (zaten overlay uzerinde)
- Fallback (foto yok): `AppColors.surface` arka plan + person ikonu

**Step 3: Hot reload, gorsel dogrula**

**Step 4: Commit**

```bash
git add lib/features/discover/
git commit -m "feat: update discover screen to dark theme with quiz CTA"
```

---

## Task 11: Matches Ekrani — Bumble Tarzi

**Files:**
- Modify: `lib/features/chat/screens/matches_screen.dart`

**Step 1: Ust bolum — Yeni eslesmeler yatay scroll**

Mevcut ListView'in ustune yeni bolum ekle:

```dart
// Yeni eslesmeler yatay scroll bolumu
if (matches.isNotEmpty)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Text(
          context.tr('new_matches'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: matches.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final match = matches[index];
            return GestureDetector(
              onTap: () => /* navigate to chat */,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: /* hasUnread ? AppColors.primary : AppColors.border */,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: /* photo */,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(match.name, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Divider(color: AppColors.border, height: 1),
    ],
  ),
```

**Step 2: Alt bolum — Sohbet listesi koyu kart satirlar**

```dart
// Her satir koyu kart stili:
Container(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
  ),
  child: ListTile(
    leading: Stack(
      children: [
        CircleAvatar(radius: 24, /* photo */),
        if (match.isOnline)
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
      ],
    ),
    title: Text(match.name, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(
      match.lastMessage ?? '',
      maxLines: 1, overflow: TextOverflow.ellipsis,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
    ),
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(timeAgo, style: TextStyle(color: AppColors.textHint, fontSize: 11)),
        if (unreadCount > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ],
    ),
  ),
),
```

**Step 3: Empty state koyu tema**

```dart
Icon(Icons.favorite_border, size: 64, color: AppColors.textHint),
Text(context.tr('no_matches'), style: TextStyle(color: AppColors.textSecondary)),
```

**Step 4: Hot reload, gorsel dogrula**

**Step 5: Commit**

```bash
git add lib/features/chat/screens/matches_screen.dart
git commit -m "feat: redesign matches screen with horizontal scroll and dark cards"
```

---

## Task 12: Chat Ekrani — Koyu Balonlar

**Files:**
- Modify: `lib/features/chat/screens/chat_screen.dart`

**Step 1: AppBar — Avatar + online durum**

```dart
// AppBar'a leading olarak avatar ekle:
title: Row(
  children: [
    CircleAvatar(radius: 16, /* match photo */),
    const SizedBox(width: 8),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(matchName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.secondary : AppColors.textHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isOnline ? context.tr('online') : context.tr('offline'),
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ],
    ),
  ],
),
```

**Step 2: Mesaj balonlari — Mor gradient gonderici, koyu gri alici**

```dart
// Gonderici balonu:
Container(
  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    gradient: AppColors.primaryButtonGradient,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(4),
    ),
  ),
  child: Text(message.text, style: const TextStyle(color: Colors.white)),
)

// Alici balonu:
Container(
  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: AppColors.surfaceInput,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(16),
    ),
  ),
  child: Text(message.text, style: const TextStyle(color: AppColors.textPrimary)),
)
```

**Step 3: Input alani — Koyu arka plan + mor gonder butonu**

```dart
Container(
  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
  ),
  child: SafeArea(
    child: Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: context.tr('type_message'),
              filled: true,
              fillColor: AppColors.surfaceInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryButtonGradient,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
            onPressed: _sendMessage,
          ),
        ),
      ],
    ),
  ),
),
```

**Step 4: Hot reload, gorsel dogrula**

**Step 5: Commit**

```bash
git add lib/features/chat/screens/chat_screen.dart
git commit -m "feat: redesign chat screen with gradient bubbles and dark theme"
```

---

## Task 13: Profil Ekrani — Card-Based Moduler

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`

**Step 1: Fotograf karti — Koyu cerceve**

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Container(
    height: MediaQuery.of(context).size.height * 0.35,
    width: double.infinity,
    color: AppColors.surface,
    child: user.photos.isNotEmpty
        ? CachedNetworkImage(imageUrl: user.photos.first, fit: BoxFit.cover)
        : const Icon(Icons.person, size: 64, color: AppColors.textHint),
  ),
),
```

**Step 2: Istatistik kartlari — 2x2 Grid**

```dart
// Mevcut _DiamondChip yerine 2x2 grid:
GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  childAspectRatio: 2.2,
  children: [
    _StatCard(
      icon: Icons.quiz_outlined,
      value: '${user.questionCount}',
      label: context.tr('questions'),
      color: AppColors.primary,
    ),
    _StatCard(
      icon: Icons.favorite,
      value: '${user.matchCount}',
      label: context.tr('matches'),
      color: AppColors.secondary,
    ),
    _StatCard(
      icon: Icons.diamond,
      value: '${user.purpleDiamonds}',
      label: context.tr('purple_diamonds'),
      color: AppColors.primary,
    ),
    _StatCard(
      icon: Icons.diamond,
      value: '${user.greenDiamonds}',
      label: context.tr('green_diamonds'),
      color: AppColors.secondary,
    ),
  ],
),

// _StatCard widget:
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

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
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
```

**Step 3: Menu itemlari — Koyu ListTile**

```dart
// Her menu item:
Container(
  margin: const EdgeInsets.only(bottom: 8),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
  ),
  child: ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
    onTap: onTap,
  ),
),
```

**Step 4: Hot reload, gorsel dogrula**

**Step 5: Commit**

```bash
git add lib/features/profile/screens/profile_screen.dart
git commit -m "feat: redesign profile screen with stat cards and dark theme"
```

---

## Task 14: Settings Ekrani — Koyu Tema

**Files:**
- Modify: `lib/features/settings/screens/settings_screen.dart`

**Step 1: SegmentedButton ve ListTile koyu tema**

- SegmentedButton: Theme'den koyu stil alir
- ListTile'lar: Container ile sarip `AppColors.surface` arka plan
- Delete account: `AppColors.error` ikon ve metin
- Divider: `AppColors.divider`

**Step 2: Hot reload, gorsel dogrula**

**Step 3: Commit**

```bash
git add lib/features/settings/screens/settings_screen.dart
git commit -m "feat: update settings screen to dark theme"
```

---

## Task 15: Diamonds Ekrani — Koyu Tema + Gradient Border

**Files:**
- Modify: `lib/features/diamonds/screens/diamonds_screen.dart`

**Step 1: Bakiye kartlari — Koyu + gradient border**

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: isPurple ? AppColors.primary.withValues(alpha: 0.5) : AppColors.secondary.withValues(alpha: 0.5)),
  ),
  // ...
)
```

**Step 2: Satin alma chipleri — Koyu kartlar + mor gradient buton**

**Step 3: Islem gecmisi — Koyu satirlar, yesil/kirmizi amount renkleri korunur**

**Step 4: Hot reload, gorsel dogrula**

**Step 5: Commit**

```bash
git add lib/features/diamonds/screens/diamonds_screen.dart
git commit -m "feat: update diamonds screen to dark theme with gradient borders"
```

---

## Task 16: Passport, Quiz, Onboarding, Questions — Koyu Tema

**Files:**
- Modify: `lib/features/passport/screens/passport_screen.dart`
- Modify: `lib/features/quiz/screens/quiz_screen.dart`
- Modify: `lib/features/quiz/widgets/answer_button.dart`
- Modify: `lib/features/quiz/widgets/quiz_timer.dart`
- Modify: `lib/features/quiz/widgets/power_bar.dart`
- Modify: `lib/features/onboarding/screens/onboarding_screen.dart`
- Modify: `lib/features/profile/screens/questions_screen.dart`

**Step 1: passport_screen.dart**

- Ikon: `AppColors.primary` (mor neon)
- Input: Theme'den koyu stil
- Butonlar: Theme'den stil
- Maliyet mesaji: `AppColors.textSecondary`

**Step 2: quiz_screen.dart + widgets**

- Soru karti: `AppColors.surface` arka plan, `AppColors.primary` border
- answer_button.dart: Koyu arka plan, mor border, secilince mor glow
- quiz_timer.dart: Mor neon progress bar, renk degisimi korunur
- power_bar.dart: Koyu chip'ler, mor secili

**Step 3: onboarding_screen.dart**

- Siyah arka plan
- Ikonlar: `AppColors.primary` (mor neon)
- Dot indicators: Mor aktif (`AppColors.primary`), gri pasif (`AppColors.textHint`)
- Baslik/alt baslik: Beyaz/gri

**Step 4: questions_screen.dart**

- Soru kartlari: Koyu (`AppColors.surface`)
- Soru numarasi daire: `AppColors.primarySurface` arka plan
- Delete ikonu: `AppColors.error`
- FAB: `AppColors.primaryDark`
- Dialog: Theme'den koyu stil (Task 2'de ayarlandi)

**Step 5: Hot reload, tum ekranlari gorsel dogrula**

**Step 6: Commit**

```bash
git add lib/features/passport/ lib/features/quiz/ lib/features/onboarding/ lib/features/profile/screens/questions_screen.dart
git commit -m "feat: update passport, quiz, onboarding, questions screens to dark theme"
```

---

## Task 17: i18n — Yeni Anahtarlar

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: Yeni i18n key'leri ekle**

```dart
// Turkce
'new_matches': 'Yeni Eslesmeler',
'solve_to_meet': 'Tanimak icin',
'questions_lower': 'soruyu coz',
'online': 'Cevrimici',
'offline': 'Cevrimdisi',
'type_message': 'Mesaj yaz...',

// Ingilizce
'new_matches': 'New Matches',
'solve_to_meet': 'Solve',
'questions_lower': 'questions to meet',
'online': 'Online',
'offline': 'Offline',
'type_message': 'Type a message...',
```

**Step 2: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat: add i18n keys for redesigned screens"
```

---

## Task 18: Son Dogrulama + Flutter Analyze

**Step 1: Flutter analyze calistir**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart analyze lib/
```

Expected: No errors. Warning'ler kabul edilebilir.

**Step 2: Tum ekranlari test et**

1. Splash → Login → Register (tum step'ler) → Login
2. Discover → Quiz
3. Matches → Chat
4. Profile → Questions → Diamonds → Passport
5. Settings → Logout → Login

Her ekranda koyu tema, mor neon aksan, beyaz metin dogrula.

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: fix any remaining dark theme inconsistencies"
```
