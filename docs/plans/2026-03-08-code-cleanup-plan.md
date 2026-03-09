# Code Cleanup & SOLID Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Tüm relative importları package importlara çevirmek, hardcoded theme değerlerini temizlemek, SOLID ihlallerini düzeltmek ve repository interface'leri eklemek.

**Architecture:** 4 fazlı refactor — önce mekanik import değişikliği, sonra theme tutarlılığı, ardından büyük dosyaların parçalanması, son olarak repository abstraction.

**Tech Stack:** Flutter, Dart, Riverpod

---

## Faz 1: Import Refactor

### Task 1: Tüm relative importları package importlara çevir

**Files:**
- Modify: `lib/` altındaki tüm 155 dart dosyası

**Step 1: Otomatik dönüşüm script'i çalıştır**

Proje kök dizininde çalıştır:

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
find lib -name "*.dart" -exec sed -i '' "s|import '\.\./|import 'package:qulov2/|g" {} +
find lib -name "*.dart" -exec sed -i '' "s|import '\./|import 'package:qulov2/|g" {} +
```

**UYARI:** Bu sed komutu basit relative importları çevirir ama path'leri doğru çözmez. Bunun yerine şu yaklaşım daha güvenli:

Dart'ın kendi fix aracını kullan:
```bash
dart fix --apply --code=always_use_package_imports
```

Eğer bu lint kuralı aktif değilse, önce `analysis_options.yaml`'a ekle:
```yaml
linter:
  rules:
    always_use_package_imports: true
```

Sonra:
```bash
dart fix --apply
```

**Step 2: Manuel kontrol**

Özellikle `part` ve `part of` directive'leri relative kalmalı (Retrofit `.g.dart` dosyaları). Bunları kontrol et:
```bash
grep -r "part '" lib/ --include="*.dart" | grep -v ".g.dart"
```

`part` dosyaları (`*.g.dart`) relative import kullanmaya devam etmeli — bunlara dokunma.

**Step 3: Doğrulama**

```bash
dart analyze lib/
```
Hata olmamalı.

**Step 4: Commit**

```bash
git add lib/ analysis_options.yaml
git commit -m "refactor: convert all relative imports to package imports"
```

---

## Faz 2: Theme Tutarlılığı

### Task 2: AppColors'a eksik renk sabitleri ekle

**Files:**
- Modify: `lib/core/theme/app_colors.dart`

**Step 1: Badge renkleri ekle**

AppColors class'ına ekle:
```dart
  // Badge colors
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
```

**Step 2: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat: add badge colors (gold, silver, bronze) to AppColors"
```

---

### Task 3: app_scaffold.dart hardcoded Color(0x...) düzelt

**Files:**
- Modify: `lib/core/widgets/app_scaffold.dart`

**Step 1: _BackgroundPainter'daki hardcoded renkleri değiştir**

Satır 83-84'teki:
```dart
const Color(0xFFBB86FC).withValues(alpha: 0.06),
const Color(0xFFBB86FC).withValues(alpha: 0.0),
```
→
```dart
AppColors.primary.withValues(alpha: 0.06),
AppColors.primary.withValues(alpha: 0.0),
```

Satır 97-98'deki:
```dart
const Color(0xFF69F0AE).withValues(alpha: 0.04),
const Color(0xFF69F0AE).withValues(alpha: 0.0),
```
→
```dart
AppColors.secondary.withValues(alpha: 0.04),
AppColors.secondary.withValues(alpha: 0.0),
```

**Not:** `const` kaldırılmalı çünkü `AppColors.primary.withValues()` const değil.

**Step 2: Commit**

```bash
git add lib/core/widgets/app_scaffold.dart
git commit -m "refactor: replace hardcoded colors with AppColors in app_scaffold"
```

---

### Task 4: badge_bar.dart hardcoded Color(0x...) düzelt

**Files:**
- Modify: `lib/features/profile/widgets/badge_bar.dart`

**Step 1: AppColors import'u ekle (yoksa)**

**Step 2: Hardcoded badge renkleri değiştir**

```dart
// ÖNCE
Color(0xFFFFD700) → AppColors.gold
Color(0xFFC0C0C0) → AppColors.silver
Color(0xFFCD7F32) → AppColors.bronze
```

**Step 3: Commit**

```bash
git add lib/features/profile/widgets/badge_bar.dart
git commit -m "refactor: replace hardcoded badge colors with AppColors constants"
```

---

### Task 5: Hardcoded TextStyle'ları theme.textTheme ile değiştir

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`
- Modify: `lib/features/chat/screens/matches_screen.dart`

**Step 1: discover_screen.dart satır 81**

```dart
// ÖNCE
const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)

// SONRA
theme.textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)
```

Not: `theme` değişkeni yoksa `final theme = Theme.of(context);` ekle.

**Step 2: matches_screen.dart _MatchCard içinde**

Satır 199:
```dart
// ÖNCE
const TextStyle(fontWeight: FontWeight.w600)
// SONRA
theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
```

Satır 205:
```dart
// ÖNCE
TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)
// SONRA
theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)
```

Satır 210:
```dart
// ÖNCE
TextStyle(color: AppColors.secondary, fontSize: 12)
// SONRA
theme.textTheme.labelSmall?.copyWith(color: AppColors.secondary)
```

**Step 3: Commit**

```bash
git add lib/features/discover/screens/discover_screen.dart lib/features/chat/screens/matches_screen.dart
git commit -m "refactor: replace hardcoded TextStyles with theme.textTheme"
```

---

### Task 6: Hardcoded Türkçe string'leri i18n'e çevir

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`
- Modify: `lib/features/chat/screens/matches_screen.dart`
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: i18n key'leri ekle**

`app_localizations.dart`'taki `_tr` map'ine:
```dart
'solve_questions': 'Soruları Çöz',
'new_matches': 'Yeni Eşleşmeler',
'unknown_user': 'Bilinmeyen',
```

`_en` map'ine:
```dart
'solve_questions': 'Solve Questions',
'new_matches': 'New Matches',
'unknown_user': 'Unknown',
```

**Step 2: Ekranlardaki hardcoded string'leri değiştir**

discover_screen.dart:
```dart
// ÖNCE
'Soruları Çöz'
// SONRA
context.tr('solve_questions')
```

matches_screen.dart:
```dart
// ÖNCE
'Yeni Eslesmeler'
// SONRA
context.tr('new_matches')

// ÖNCE
'Unknown'
// SONRA
context.tr('unknown_user')
```

**Step 3: Commit**

```bash
git add lib/core/l10n/app_localizations.dart lib/features/discover/screens/discover_screen.dart lib/features/chat/screens/matches_screen.dart
git commit -m "refactor: replace hardcoded strings with i18n keys"
```

---

### Task 7: AppColors.textSecondary/textHint → theme.colorScheme (core widgets)

**Files:**
- Modify: `lib/core/widgets/app_button.dart`
- Modify: `lib/core/widgets/app_date_picker.dart`
- Modify: `lib/core/widgets/diamond_icon.dart`
- Modify: `lib/core/navigation/widgets/confirm_dialog_widget.dart`
- Modify: `lib/core/navigation/widgets/list_bottom_sheet_widget.dart`

**Step 1: Her dosyada `AppColors.textSecondary` ve `AppColors.textHint` kullanımlarını bul**

Değiştirme kuralı:
```dart
AppColors.textSecondary → theme.colorScheme.onSurfaceVariant
AppColors.textHint → theme.hintColor
AppColors.textPrimary → theme.colorScheme.onSurface
```

Her widget'ta `final theme = Theme.of(context);` olduğundan emin ol.

**Not:** `AppColors.primary` ve `AppColors.secondary` brand renkleri olarak kalabilir — bunlar tema değişse de sabit. Ama `textSecondary`, `textHint` gibi semantik renkler theme'den gelmeli.

**Step 2: Doğrulama**

```bash
dart analyze lib/core/
```

**Step 3: Commit**

```bash
git add lib/core/
git commit -m "refactor: replace AppColors.text* with theme colors in core widgets"
```

---

### Task 8: AppColors.textSecondary/textHint → theme.colorScheme (feature widgets)

**Files:**
- Modify: Tüm `lib/features/` altındaki dosyalar (20+ dosya)

**Step 1: Tüm feature dosyalarında aynı dönüşümü uygula**

Değiştirme kuralı (Task 7 ile aynı):
```dart
AppColors.textSecondary → theme.colorScheme.onSurfaceVariant
AppColors.textHint → theme.hintColor
AppColors.textPrimary → theme.colorScheme.onSurface
AppColors.divider → theme.dividerColor
AppColors.surfaceElevated → theme.colorScheme.surfaceContainerHigh
```

Dosya listesi:
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/widgets/register_step_gender.dart`
- `lib/features/auth/widgets/register_step_location.dart`
- `lib/features/auth/widgets/register_step_terms.dart`
- `lib/features/chat/screens/chat_screen.dart`
- `lib/features/diamonds/screens/diamonds_screen.dart`
- `lib/features/diamonds/screens/subscription_comparison_screen.dart`
- `lib/features/diamonds/widgets/diamond_balance_card.dart`
- `lib/features/diamonds/widgets/purchase_grid.dart`
- `lib/features/diamonds/widgets/subscription_banner.dart`
- `lib/features/diamonds/widgets/upsell_sheets.dart`
- `lib/features/discover/widgets/profile_card.dart`
- `lib/features/onboarding/screens/onboarding_screen.dart`
- `lib/features/passport/screens/passport_screen.dart`
- `lib/features/profile/screens/edit_profile_screen.dart`
- `lib/features/profile/screens/profile_screen.dart`
- `lib/features/profile/screens/questions_screen.dart`
- `lib/features/profile/widgets/detail_chips.dart`
- `lib/features/profile/widgets/photo_grid.dart`
- `lib/features/quiz/widgets/answer_button.dart`
- `lib/features/quiz/widgets/power_bar.dart`
- `lib/features/splash/splash_screen.dart`

**Not:** `AppColors.primary`, `AppColors.secondary`, `AppColors.error`, `AppColors.primarySurface` gibi brand/semantic renkler olduğu gibi kalabilir — bunlar her iki temada da aynı olacak şekilde tasarlandı. Sadece `text*`, `divider`, `surfaceElevated` gibi tema-bağımlı renkler değişmeli.

**Step 2: Doğrulama**

```bash
dart analyze lib/features/
```

**Step 3: Commit**

```bash
git add lib/features/
git commit -m "refactor: replace AppColors.text* with theme colors in feature widgets"
```

---

## Faz 3: SOLID Refactor

### Task 9: UpsellSheets — BaseUpsellSheet widget'ı çıkar

**Files:**
- Modify: `lib/features/diamonds/widgets/upsell_sheets.dart`

**Step 1: _BaseUpsellSheet private widget oluştur**

Dosyanın sonuna (mevcut class'lardan önce) ekle:

```dart
class _BaseUpsellSheet extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final Widget content;
  final VoidCallback? onDismiss;

  const _BaseUpsellSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.hintColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          icon,
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          content,
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onDismiss ?? () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                context.tr('maybe_later'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
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

**Step 2: PremiumUpsellSheet, ConsumableUpsellSheet, SwipeLimitSheet'i _BaseUpsellSheet kullancak şekilde refactor et**

PremiumUpsellSheet:
```dart
@override
Widget build(BuildContext context) {
  return _BaseUpsellSheet(
    icon: const DiamondIcon.purple(size: 48),
    title: isFirstMatch
        ? context.tr('first_match_congrats')
        : context.tr('premium_cta'),
    subtitle: isFirstMatch
        ? context.tr('want_more_matches')
        : context.tr('unlock_unlimited'),
    onDismiss: onDismiss,
    content: Column(
      children: [
        _FeatureRow(icon: Icons.all_inclusive, text: context.tr('sub_premium_swipes')),
        const SizedBox(height: AppSpacing.md),
        _FeatureRow(icon: Icons.diamond_outlined, text: context.tr('sub_premium_diamonds')),
        const SizedBox(height: AppSpacing.md),
        _FeatureRow(icon: Icons.undo, text: context.tr('sub_premium_undos')),
        const SizedBox(height: AppSpacing.md),
        _FeatureRow(icon: Icons.bolt, text: context.tr('sub_premium_boost')),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: '${context.tr('sub_plan_plus')} — ${context.tr('sub_price_plus')}',
          variant: AppButtonVariant.secondary,
          onPressed: onPlusTap,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: '${context.tr('sub_plan_premium')} — ${context.tr('sub_price_premium')}',
          onPressed: onPremiumTap,
        ),
      ],
    ),
  );
}
```

Aynı pattern'i ConsumableUpsellSheet ve SwipeLimitSheet için de uygula.

**Step 3: Doğrulama**

```bash
dart analyze lib/features/diamonds/widgets/upsell_sheets.dart
```

**Step 4: Commit**

```bash
git add lib/features/diamonds/widgets/upsell_sheets.dart
git commit -m "refactor: extract BaseUpsellSheet to eliminate duplication"
```

---

### Task 10: EditProfileScreen — Form state'ini provider'a taşı

**Files:**
- Create: `lib/providers/edit_profile_provider.dart`
- Modify: `lib/features/profile/screens/edit_profile_screen.dart`

**Step 1: EditProfileProvider oluştur**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulov2/core/network/result.dart';
import 'package:qulov2/providers/user_provider.dart';

class EditProfileState {
  final bool isSaving;
  final String? selectedZodiac;
  final String? selectedSmoking;
  final String? selectedAlcohol;
  final String? selectedGenderPref;
  final RangeValues ageRange;
  final double distanceKm;
  final List<String?> photos;

  const EditProfileState({
    this.isSaving = false,
    this.selectedZodiac,
    this.selectedSmoking,
    this.selectedAlcohol,
    this.selectedGenderPref,
    this.ageRange = const RangeValues(18, 50),
    this.distanceKm = 50,
    this.photos = const [null, null, null, null, null, null],
  });

  EditProfileState copyWith({
    bool? isSaving,
    String? selectedZodiac,
    String? selectedSmoking,
    String? selectedAlcohol,
    String? selectedGenderPref,
    RangeValues? ageRange,
    double? distanceKm,
    List<String?>? photos,
  }) {
    return EditProfileState(
      isSaving: isSaving ?? this.isSaving,
      selectedZodiac: selectedZodiac ?? this.selectedZodiac,
      selectedSmoking: selectedSmoking ?? this.selectedSmoking,
      selectedAlcohol: selectedAlcohol ?? this.selectedAlcohol,
      selectedGenderPref: selectedGenderPref ?? this.selectedGenderPref,
      ageRange: ageRange ?? this.ageRange,
      distanceKm: distanceKm ?? this.distanceKm,
      photos: photos ?? this.photos,
    );
  }
}

class EditProfileNotifier extends Notifier<EditProfileState> {
  @override
  EditProfileState build() {
    _loadFromUser();
    return const EditProfileState();
  }

  void _loadFromUser() {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) return;

    state = EditProfileState(
      selectedZodiac: user.details?.zodiac,
      selectedSmoking: user.details?.smoking,
      selectedAlcohol: user.details?.alcohol,
      selectedGenderPref: user.genderPref,
      ageRange: RangeValues(
        (user.agePrefMin ?? 18).toDouble(),
        (user.agePrefMax ?? 50).toDouble(),
      ),
      distanceKm: (user.matchRadiusKm ?? 50).toDouble(),
      photos: List.generate(6, (i) => i < (user.photos?.length ?? 0) ? user.photos![i] : null),
    );
  }

  void setZodiac(String? value) => state = state.copyWith(selectedZodiac: value);
  void setSmoking(String? value) => state = state.copyWith(selectedSmoking: value);
  void setAlcohol(String? value) => state = state.copyWith(selectedAlcohol: value);
  void setGenderPref(String? value) => state = state.copyWith(selectedGenderPref: value);
  void setAgeRange(RangeValues value) => state = state.copyWith(ageRange: value);
  void setDistanceKm(double value) => state = state.copyWith(distanceKm: value);

  void refreshPhotos() {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) return;
    final userPhotos = user.photos ?? [];
    state = state.copyWith(
      photos: List.generate(6, (i) => i < userPhotos.length ? userPhotos[i] : null),
    );
  }

  Future<Result<void>> saveProfile(Map<String, dynamic> profileData, Map<String, dynamic> detailsData) async {
    state = state.copyWith(isSaving: true);
    try {
      final profileResult = await ref.read(userProvider.notifier).updateProfile(profileData);
      detailsData.removeWhere((_, v) => v == null);
      final detailsResult = await ref.read(userProvider.notifier).updateDetails(detailsData);

      if (profileResult.isFailure) return profileResult;
      return detailsResult;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final editProfileProvider =
    NotifierProvider<EditProfileNotifier, EditProfileState>(EditProfileNotifier.new);
```

**Step 2: EditProfileScreen'i sadeleştir**

- Dropdown state'lerini (`_selectedZodiac`, `_selectedSmoking`, vb.) kaldır, provider'dan oku
- `_isSaving` kaldır, provider'dan oku
- `_photos` kaldır, provider'dan oku
- `_save()` metodunu sadeleştir — sadece controller'lardan data topla, provider'a gönder
- `_refreshPhotos()` → `ref.read(editProfileProvider.notifier).refreshPhotos()`

TextEditingController'lar screen'de kalmalı (Flutter widget lifecycle'ına bağlı).

**Step 3: Doğrulama**

```bash
dart analyze lib/providers/edit_profile_provider.dart lib/features/profile/screens/edit_profile_screen.dart
```

**Step 4: Commit**

```bash
git add lib/providers/edit_profile_provider.dart lib/features/profile/screens/edit_profile_screen.dart
git commit -m "refactor: extract EditProfileProvider from EditProfileScreen"
```

---

### Task 11: RegisterScreen — Step widget'larını ayrı dosyalara taşı

**Files:**
- Modify: `lib/features/auth/screens/register_screen.dart`

**Step 1: Mevcut yapıyı kontrol et**

Register screen zaten step widget'larını ayrı dosyalara taşımış olabilir (`lib/features/auth/widgets/register_step_*.dart`). Kontrol et. Eğer taşınmışsa, sadece ana screen'deki business logic'i temizle:

- `_register()` metodu → validation + API çağrısı ayrılmalı
- `_calculateAge()` → utility fonksiyon olarak ayrılabilir
- 11 error field → tek bir Map<String, String?> ile yönetilebilir

**Step 2: RegisterScreen'i sadeleştir**

Ana screen'de sadece:
- PageController yönetimi
- Step arası navigasyon
- `_register()` çağrısı

Her step widget kendi validation'ını yapmalı.

**Step 3: Doğrulama**

```bash
dart analyze lib/features/auth/
```

**Step 4: Commit**

```bash
git add lib/features/auth/
git commit -m "refactor: simplify RegisterScreen, move logic to step widgets"
```

---

## Faz 4: Repository Interface

### Task 12: Repository interface'leri oluştur

**Files:**
- Create: `lib/data/repositories/interfaces/` dizini
- Create: Her repository için interface dosyası
- Modify: Mevcut repository'ler interface'i implement etsin

**Step 1: Örnek interface oluştur (UserRepository)**

`lib/data/repositories/interfaces/i_user_repository.dart`:
```dart
import 'package:qulov2/core/network/result.dart';
import 'package:qulov2/data/models/user_model.dart';

abstract class IUserRepository {
  Future<Result<UserModel>> getMe();
  Future<Result<void>> updateProfile(Map<String, dynamic> data);
  Future<Result<void>> updateDetails(Map<String, dynamic> data);
  Future<Result<void>> updateLocation({required double lat, required double lng});
  Future<Result<void>> updatePushToken(String token);
  Future<Result<void>> deleteAccount();
  Future<Result<String>> uploadPhoto(List<int> bytes, String mimeType);
  Future<Result<void>> reorderPhotos(List<String> photos);
  Future<Result<void>> deletePhoto(int index);
}
```

**Step 2: UserRepository'yi interface'i implement edecek şekilde güncelle**

```dart
class UserRepository implements IUserRepository {
  // ... mevcut implementasyon
}
```

**Step 3: Diğer 10 repository için aynısını yap**

Interface dosyaları:
- `i_auth_repository.dart`
- `i_chat_repository.dart`
- `i_diamond_repository.dart`
- `i_match_repository.dart`
- `i_passport_repository.dart`
- `i_power_repository.dart`
- `i_question_repository.dart`
- `i_quiz_repository.dart`
- `i_report_repository.dart`
- `i_subscription_repository.dart`
- `i_user_repository.dart`

Her repository'nin public metodlarını interface'e çıkar, repository class'ına `implements` ekle.

**Step 4: Barrel dosyasını güncelle**

`lib/data/repositories/repositories.dart`'a interface export'larını ekle.

**Step 5: Doğrulama**

```bash
dart analyze lib/data/repositories/
```

**Step 6: Commit**

```bash
git add lib/data/repositories/
git commit -m "refactor: add abstract interfaces for all repositories"
```

---

### Task 13: Final doğrulama

**Step 1: Tüm projeyi analiz et**

```bash
dart analyze lib/
```

Hata olmamalı.

**Step 2: Relative import kalmadığını doğrula**

```bash
grep -r "import '\.\." lib/ --include="*.dart" | grep -v ".g.dart" | head -20
```

Sonuç boş olmalı (sadece .g.dart dosyalarında relative import kalmalı).

**Step 3: Hardcoded Color(0x) kalmadığını doğrula (theme dosyaları hariç)**

```bash
grep -rn "Color(0x" lib/ --include="*.dart" | grep -v "app_colors.dart" | grep -v "app_theme" | grep -v ".g.dart"
```

Sonuç boş olmalı.

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: final cleanup and verification"
```
