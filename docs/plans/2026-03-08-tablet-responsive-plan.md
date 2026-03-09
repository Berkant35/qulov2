# Tablet Responsive Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Tablet ekranlarda layout kırılmalarını önlemek, içeriği maxWidth: 560 ile ortalamak ve hardcoded değerleri AppSpacing sabitlerrine çevirmek.

**Architecture:** AppSpacing'e maxContentWidth sabiti ekle, AppScaffold'un body'sini Center > ConstrainedBox ile sar, ardından hardcoded piksel değerlerini AppSpacing sabitlerine çevir.

**Tech Stack:** Flutter, Dart

---

### Task 1: AppSpacing'e maxContentWidth sabiti ekle

**Files:**
- Modify: `lib/core/theme/app_spacing.dart`

**Step 1: Sabiti ekle**

```dart
// Responsive
static const double maxContentWidth = 560;
```

`AppSpacing` class'ının sonuna, `radiusFull` sabitinden sonra ekle.

**Step 2: Commit**

```bash
git add lib/core/theme/app_spacing.dart
git commit -m "feat: add maxContentWidth constant to AppSpacing"
```

---

### Task 2: AppScaffold'a ConstrainedBox + Center ekle

**Files:**
- Modify: `lib/core/widgets/app_scaffold.dart`

**Step 1: Body widget'ını ConstrainedBox ile sar**

Mevcut `body` bölümünü (satır 61-64 arası):
```dart
if (padding != null)
  Padding(padding: padding!, child: body)
else
  body,
```

Şu şekilde değiştir:
```dart
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
    child: padding != null
        ? Padding(padding: padding!, child: body)
        : body,
  ),
),
```

**Step 2: Test et**

Telefonda: Görsel fark yok (ekran zaten <560px).
Tablet/iPad simulator'da: İçerik ortalanmış, yanlar boş.

**Step 3: Commit**

```bash
git add lib/core/widgets/app_scaffold.dart
git commit -m "feat: add maxWidth constraint to AppScaffold for tablet support"
```

---

### Task 3: matches_screen.dart hardcoded değerleri düzelt

**Files:**
- Modify: `lib/features/chat/screens/matches_screen.dart`

**Step 1: Import ekle (yoksa)**

Dosyanın başına `app_spacing.dart` import'u ekle:
```dart
import '../../../core/theme/app_spacing.dart';
```

**Step 2: Hardcoded değerleri değiştir**

| Satır | Eski | Yeni |
|-------|------|------|
| 64 | `EdgeInsets.fromLTRB(16, 8, 16, 12)` | `EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.sm, AppSpacing.pagePadding, AppSpacing.md)` |
| 74 | `EdgeInsets.symmetric(horizontal: 16)` | `EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding)` |
| 76 | `SizedBox(width: 16)` | `SizedBox(width: AppSpacing.lg)` |
| 106 | `SizedBox(height: 4)` | `SizedBox(height: AppSpacing.xs)` |
| 123 | `SizedBox(height: 8)` | `SizedBox(height: AppSpacing.sm)` |
| 44 | `SizedBox(height: 16)` | `SizedBox(height: AppSpacing.lg)` |
| 46 | `SizedBox(height: 8)` | `SizedBox(height: AppSpacing.sm)` |
| 164 | `EdgeInsets.symmetric(horizontal: 12, vertical: 4)` | `EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs)` |
| 168 | `BorderRadius.circular(12)` | `BorderRadius.circular(AppSpacing.radiusMd)` |

Not: `radius: 28`, `radius: 24`, `width: 12, height: 12` (online dot), `width: 2` (border) gibi semantik UI boyutları olduğu gibi kalabilir — bunlar layout spacing değil, UI element boyutlarıdır.

**Step 3: Commit**

```bash
git add lib/features/chat/screens/matches_screen.dart
git commit -m "refactor: replace hardcoded values with AppSpacing in matches_screen"
```

---

### Task 4: settings_screen.dart hardcoded değerleri düzelt

**Files:**
- Modify: `lib/features/settings/screens/settings_screen.dart`

**Step 1: Import ekle**

```dart
import '../../../core/theme/app_spacing.dart';
```

**Step 2: Hardcoded değerleri değiştir**

| Satır | Eski | Yeni |
|-------|------|------|
| 25 | `SizedBox(height: 8)` | `SizedBox(height: AppSpacing.sm)` |
| 27 | `EdgeInsets.symmetric(horizontal: 12, vertical: 4)` | `EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs)` |
| 30 | `BorderRadius.circular(12)` | `BorderRadius.circular(AppSpacing.radiusMd)` |
| 51 | `EdgeInsets.symmetric(horizontal: 12, vertical: 4)` | `EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs)` |
| 52 | `EdgeInsets.all(16)` | `EdgeInsets.all(AppSpacing.pagePadding)` |
| 55 | `BorderRadius.circular(12)` | `BorderRadius.circular(AppSpacing.radiusMd)` |
| 63 | `SizedBox(width: 16)` | `SizedBox(width: AppSpacing.lg)` |
| 67 | `SizedBox(height: 12)` | `SizedBox(height: AppSpacing.md)` |
| 85 | `SizedBox(height: 8)` | `SizedBox(height: AppSpacing.sm)` |
| 87 | `EdgeInsets.symmetric(horizontal: 12, vertical: 4)` | `EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs)` |
| 90 | `BorderRadius.circular(12)` | `BorderRadius.circular(AppSpacing.radiusMd)` |
| 115 | `EdgeInsets.symmetric(horizontal: 12, vertical: 4)` | `EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs)` |
| 118 | `BorderRadius.circular(12)` | `BorderRadius.circular(AppSpacing.radiusMd)` |

**Step 3: Commit**

```bash
git add lib/features/settings/screens/settings_screen.dart
git commit -m "refactor: replace hardcoded values with AppSpacing in settings_screen"
```

---

### Task 5: diamond_balance_card.dart hardcoded değerleri düzelt

**Files:**
- Modify: `lib/features/diamonds/widgets/diamond_balance_card.dart`

**Step 1: Divider'ı düzelt**

Satır 40-43'teki:
```dart
Container(
  width: 1,
  height: 56,
  color: theme.colorScheme.outline.withValues(alpha: 0.2),
),
```

Değiştir:
```dart
Container(
  width: 1,
  height: AppSpacing.xxxl + AppSpacing.sm, // 56
  color: theme.colorScheme.outline.withValues(alpha: 0.2),
),
```

Veya daha temiz: `IntrinsicHeight` ile otomatik yükseklik al. Ama bu semantik bir divider boyutu olduğu için hardcoded kalabilir. Sadece height'ı orantılı yap.

**Step 2: Commit**

```bash
git add lib/features/diamonds/widgets/diamond_balance_card.dart
git commit -m "refactor: replace hardcoded divider height with AppSpacing in diamond_balance_card"
```

---

### Task 6: upsell_sheets.dart temizliği

**Files:**
- Modify: `lib/features/diamonds/widgets/upsell_sheets.dart`

**Step 1: Kalan hardcoded değerleri değiştir**

Bu dosya zaten AppSpacing kullanıyor. Sadece drag handle ve icon container boyutları hardcoded:

| Eski | Yeni | Not |
|------|------|-----|
| `width: 40, height: 4` (drag handle) | Olduğu gibi kalabilir | Semantik UI boyutu |
| `BorderRadius.circular(2)` (drag handle) | Olduğu gibi kalabilir | Çok küçük radius |
| `width: 32, height: 32` (feature icon) | `AppSpacing.xxl` (32) kullan | |
| `size: 18` (icon) | Olduğu gibi kalabilir | Icon boyutu |
| `width: 64, height: 64` (swipe limit icon) | Olduğu gibi kalabilir | Semantik boyut |
| `size: 32` (swipe limit icon) | `AppSpacing.xxl` kullan | |

Sadece anlamlı olanları değiştir:
```dart
// _FeatureRow icon container
Container(
  width: AppSpacing.xxl,  // 32
  height: AppSpacing.xxl, // 32
  ...
)
```

**Step 2: Commit**

```bash
git add lib/features/diamonds/widgets/upsell_sheets.dart
git commit -m "refactor: replace hardcoded icon sizes with AppSpacing in upsell_sheets"
```

---

### Task 7: Doğrulama

**Step 1: Flutter analyze çalıştır**

```bash
flutter analyze
```
Hata olmamalı.

**Step 2: Farklı ekran boyutlarında test**

- iPhone SE (küçük telefon): Layout normal
- iPhone 15 (standart telefon): Layout normal
- iPad: İçerik ortalanmış, maxWidth: 560

**Step 3: Final commit**

```bash
git add -A
git commit -m "feat: tablet responsive support with maxWidth constraint"
```
