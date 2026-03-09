# Profile & Photo Management Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the profile screen with Tinder-style 3x2 photo grid, gamification badge system with real diamond rewards, and a full edit profile screen.

**Architecture:** Profile screen becomes view-only with photo grid, badge bar, detail chips, and menu items. Edit Profile is a separate route with interactive photo grid (upload/delete/reorder), bio editor, details form, and preferences. Badge service on backend handles one-time diamond rewards per level threshold.

**Tech Stack:** Flutter, Riverpod, GoRouter, Dio (multipart upload), Supabase Storage, Zod validation, image_picker

**Design Doc:** `docs/plans/2026-03-08-profile-photo-management-design.md`

---

## Phase 1: Backend — Badge Reward System

### Task 1: Database Migration for Badge Rewards

**Files:**
- Create: `supabase/migrations/006_badge_rewards.sql`

**Step 1: Create migration file**

```sql
-- supabase/migrations/006_badge_rewards.sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS badge_rewards_claimed TEXT[] DEFAULT '{}';
```

**Step 2: Run migration**

User runs this in Supabase SQL Editor manually.

**Step 3: Commit**

```bash
git add supabase/migrations/006_badge_rewards.sql
git commit -m "feat(db): add badge_rewards_claimed column to users table"
```

---

### Task 2: Badge Service + Endpoint

**Files:**
- Create: `server/src/services/badge.service.ts`
- Modify: `server/src/routes/user.routes.ts`
- Modify: `server/src/services/user.service.ts` (getMe'de badge_rewards_claimed return et)
- Modify: `server/src/validators/user.validator.ts` (photos array ekle)

**Step 1: Create badge service**

```typescript
// server/src/services/badge.service.ts
import { supabase } from "../config/supabase.js";
import { diamondService } from "./diamond.service.js";
import { AppError } from "../utils/errors.js";

type BadgeLevel = "SILVER" | "GOLD";

const BADGE_CONFIG: Record<BadgeLevel, { minCompletion: number; reward: number }> = {
  SILVER: { minCompletion: 60, reward: 3 },
  GOLD: { minCompletion: 85, reward: 10 },
};

export class BadgeService {
  async claimReward(userId: string, level: BadgeLevel) {
    // Fetch user
    const { data: user, error } = await supabase
      .from("users")
      .select("profile_completion, badge_rewards_claimed")
      .eq("id", userId)
      .eq("is_deleted", false)
      .maybeSingle();

    if (error || !user) {
      throw new AppError("USER_NOT_FOUND", 404, "User not found");
    }

    const config = BADGE_CONFIG[level];
    if (!config) {
      throw new AppError("INVALID_BADGE_LEVEL", 400, "Invalid badge level");
    }

    // Check completion threshold
    if (user.profile_completion < config.minCompletion) {
      throw new AppError("BADGE_THRESHOLD_NOT_MET", 400, "Profile completion too low for this badge");
    }

    // Check if already claimed
    const claimed: string[] = user.badge_rewards_claimed ?? [];
    if (claimed.includes(level)) {
      throw new AppError("BADGE_ALREADY_CLAIMED", 400, "Badge reward already claimed");
    }

    // Award purple diamonds
    await diamondService.addPurple(userId, config.reward, `BADGE_${level}`);

    // Mark as claimed
    claimed.push(level);
    const { error: updateError } = await supabase
      .from("users")
      .update({ badge_rewards_claimed: claimed })
      .eq("id", userId);

    if (updateError) {
      throw new AppError("SERVER_ERROR", 500, "Failed to update badge rewards");
    }

    return {
      level,
      diamonds_awarded: config.reward,
      badge_rewards_claimed: claimed,
    };
  }
}

export const badgeService = new BadgeService();
```

**Step 2: Add badge claim handler to user controller**

Add to `server/src/controllers/user.controller.ts`:

```typescript
// Add import at top
import { badgeService } from "../services/badge.service.js";

// Add handler
export const claimBadgeRewardHandler: RequestHandler = async (req, res, next) => {
  try {
    const userId = req.user!.id;
    const { level } = req.body;
    const result = await badgeService.claimReward(userId, level);
    res.json(result);
  } catch (error) {
    next(error);
  }
};
```

**Step 3: Add route to user.routes.ts**

Add after the `router.post("/me/boost", boostHandler);` line:

```typescript
import { claimBadgeRewardHandler } from "../controllers/user.controller.js";

router.post("/me/claim-badge-reward", claimBadgeRewardHandler);
```

**Step 4: Update user validator — add photos to updateProfileSchema**

In `server/src/validators/user.validator.ts`, add to `updateProfileSchema`:

```typescript
photos: z.array(z.string().url()).max(6).optional(),
```

**Step 5: Update getMe to return badge_rewards_claimed**

In `server/src/services/user.service.ts`, update the `getMe` select query to include `badge_rewards_claimed`:

```typescript
.select(
  "id, email, name, surname, bio, age, gender, gender_pref, match_radius_km, age_pref_min, age_pref_max, city, country, locale, lat, lng, photos, profile_completion, green_diamonds, purple_diamonds, is_online, last_seen_at, push_token, email_verified, passport_city, passport_lat, passport_lng, boost_until, like_received_count, times_shown_count, created_at, badge_rewards_claimed",
)
```

**Step 6: Verify backend compiles**

```bash
cd server && npx tsc --noEmit
```

**Step 7: Commit**

```bash
git add server/src/services/badge.service.ts server/src/controllers/user.controller.ts server/src/routes/user.routes.ts server/src/validators/user.validator.ts server/src/services/user.service.ts
git commit -m "feat(server): add badge reward system with diamond incentives"
```

---

## Phase 2: Flutter — Model & Provider Updates

### Task 3: Update UserModel for Badge Rewards

**Files:**
- Modify: `lib/data/models/user_model.dart`

**Step 1: Add badge_rewards_claimed field to UserModel**

Add field after `createdAt`:

```dart
@JsonKey(name: 'badge_rewards_claimed')
final List<String> badgeRewardsClaimed;
```

Add to constructor with default:

```dart
this.badgeRewardsClaimed = const [],
```

**Step 2: Regenerate JSON serialization**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/data/models/user_model.dart lib/data/models/user_model.g.dart
git commit -m "feat(model): add badge_rewards_claimed to UserModel"
```

---

### Task 4: Add Badge Claim to Repository & Provider

**Files:**
- Modify: `lib/data/repositories/user_repository.dart`
- Modify: `lib/providers/user_provider.dart`

**Step 1: Add claimBadgeReward to UserRepository**

Add method to `UserRepository`:

```dart
Future<Result<Map<String, dynamic>>> claimBadgeReward(String level) async {
  return _network.post('/users/me/claim-badge-reward', data: {'level': level});
}
```

**Step 2: Add reorderPhotos to UserRepository**

Add method to `UserRepository`:

```dart
Future<Result<UserModel>> reorderPhotos(List<String> photos) async {
  try {
    final response = await _service.updateProfile({'photos': photos});
    return Success(response);
  } on DioException catch (e) {
    return Failure(e.toAppFailure());
  }
}
```

**Step 3: Add methods to UserNotifier**

Add to `UserNotifier` in `lib/providers/user_provider.dart`:

```dart
Future<Result<Map<String, dynamic>>> claimBadgeReward(String level) async {
  final result = await ref.read(userRepositoryProvider).claimBadgeReward(level);
  result.when(success: (_) => fetchMe(), failure: (_) {});
  return result;
}

Future<Result<UserModel>> reorderPhotos(List<String> photos) async {
  final result = await ref.read(userRepositoryProvider).reorderPhotos(photos);
  result.when(
    success: (updated) => state = AsyncData(updated),
    failure: (_) {},
  );
  return result;
}
```

**Step 4: Commit**

```bash
git add lib/data/repositories/user_repository.dart lib/providers/user_provider.dart
git commit -m "feat(provider): add badge claim and photo reorder to user provider"
```

---

## Phase 3: SVG Icons

### Task 5: Create New SVG Icons

**Files:**
- Create: `assets/icons/ic_height.svg`
- Create: `assets/icons/ic_weight.svg`
- Create: `assets/icons/ic_personality.svg`
- Create: `assets/icons/ic_badge_bronze.svg`
- Create: `assets/icons/ic_badge_silver.svg`
- Create: `assets/icons/ic_badge_gold.svg`
- Create: `assets/icons/ic_image_plus.svg`
- Create: `assets/icons/ic_age_range.svg`
- Create: `assets/icons/ic_gender_pref.svg`
- Modify: `lib/core/constants/q_icons.dart`

**Step 1: Create SVG icon files**

Each icon should be a simple, clean SVG with viewBox="0 0 24 24", stroke-based, 2px stroke width, no fill, matching the Lucide style. Use `currentColor` as stroke color so QIcon can colorize them.

`ic_height.svg` — Ruler/height icon:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20"/><path d="M8 4h8"/><path d="M8 20h8"/><path d="M9 8h3"/><path d="M9 12h3"/><path d="M9 16h3"/></svg>
```

`ic_weight.svg` — Scale/weight icon:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="5" r="3"/><path d="M6.5 8a6 6 0 0 0-2.27 3.59L3 18a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2l-1.23-6.41A6 6 0 0 0 17.5 8"/></svg>
```

`ic_personality.svg` — Brain/personality icon:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a5 5 0 0 1 5 5c0 1.5-.5 2.5-1.5 3.5L12 14l-3.5-3.5C7.5 9.5 7 8.5 7 7a5 5 0 0 1 5-5z"/><path d="M12 14v8"/><path d="M8 18h8"/></svg>
```

`ic_badge_bronze.svg` — Bronze shield badge:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L3 7v5c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7L12 2z"/><path d="M9 12l2 2 4-4"/></svg>
```

`ic_badge_silver.svg` — Silver shield badge with star:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L3 7v5c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7L12 2z"/><path d="M12 8l1.5 3 3.5.5-2.5 2.5.5 3.5L12 16l-3 1.5.5-3.5L7 11.5l3.5-.5z"/></svg>
```

`ic_badge_gold.svg` — Gold shield badge with crown:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L3 7v5c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7L12 2z"/><path d="M8 13l1.5-3L12 12l2.5-2L16 13"/><path d="M8 13h8v2H8z"/></svg>
```

`ic_image_plus.svg` — Image with plus:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M12 8v8"/><path d="M8 12h8"/></svg>
```

`ic_age_range.svg` — Two people with range:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="7" cy="5" r="2"/><circle cx="17" cy="5" r="2"/><path d="M7 9v3"/><path d="M17 9v3"/><path d="M5 15h14"/><path d="M5 15l2-2"/><path d="M5 15l2 2"/><path d="M19 15l-2-2"/><path d="M19 15l-2 2"/></svg>
```

`ic_gender_pref.svg` — Heart with gender symbols:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21C8 17 3 13.5 3 8.5a4.5 4.5 0 0 1 9 0 4.5 4.5 0 0 1 9 0c0 5-5 8.5-9 12.5z"/></svg>
```

**Step 2: Register icons in QIcons**

Add to `lib/core/constants/q_icons.dart`:

```dart
// ─── Profile & Badge ───
static const icHeight = 'assets/icons/ic_height.svg';
static const icWeight = 'assets/icons/ic_weight.svg';
static const icPersonality = 'assets/icons/ic_personality.svg';
static const icBadgeBronze = 'assets/icons/ic_badge_bronze.svg';
static const icBadgeSilver = 'assets/icons/ic_badge_silver.svg';
static const icBadgeGold = 'assets/icons/ic_badge_gold.svg';
static const icImagePlus = 'assets/icons/ic_image_plus.svg';
static const icAgeRange = 'assets/icons/ic_age_range.svg';
static const icGenderPref = 'assets/icons/ic_gender_pref.svg';
```

**Step 3: Commit**

```bash
git add assets/icons/ic_height.svg assets/icons/ic_weight.svg assets/icons/ic_personality.svg assets/icons/ic_badge_bronze.svg assets/icons/ic_badge_silver.svg assets/icons/ic_badge_gold.svg assets/icons/ic_image_plus.svg assets/icons/ic_age_range.svg assets/icons/ic_gender_pref.svg lib/core/constants/q_icons.dart
git commit -m "feat(icons): add profile & badge SVG icons"
```

---

## Phase 4: i18n Keys

### Task 6: Add Profile i18n Keys

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: Add Turkish keys to the TR map**

Add after existing profile keys:

```dart
// Profile - Badge
'badge_rookie': 'Çaylak',
'badge_popular': 'Popüler',
'badge_master': 'Profil Ustası',
'badge_no_badge': 'Başlangıç',
'badge_progress_hint': 'kaldı',
'badge_reward_claimed': 'Tebrikler! mor elmas kazandın!',
'badge_discover_warning': 'Profilini tamamla, keşfette görün!',

// Profile - Hints
'hint_add_photos': '3 fotoğraf ekle → görünürlüğün %20 artar!',
'hint_add_bio': 'Bio ekle → daha fazla eşleşme!',
'hint_add_job': 'Mesleğini ekle → profilini tamamla!',
'hint_add_details': 'Detaylarını ekle → profil seviyeni yükselt!',

// Profile - Edit
'edit_profile': 'Profili Düzenle',
'edit_photos': 'Fotoğraflar',
'edit_about': 'Hakkımda',
'edit_basic_info': 'Temel Bilgiler',
'edit_details': 'Detaylar',
'edit_preferences': 'Tercihler',
'save_changes': 'Değişiklikleri Kaydet',
'bio_hint': 'Kendinden biraz bahset...',
'update_location': 'Konumu Güncelle',
'make_primary': 'Ana Fotoğraf Yap',
'delete_photo': 'Fotoğrafı Sil',
'delete_photo_confirm': 'Bu fotoğrafı silmek istediğine emin misin?',
'photo_upload_error': 'Fotoğraf yüklenemedi',
'photo_max_reached': 'En fazla 6 fotoğraf ekleyebilirsin',
'changes_saved': 'Değişiklikler kaydedildi',
'select_photo_source': 'Fotoğraf Kaynağı',
'from_gallery': 'Galeriden Seç',
'from_camera': 'Kamera',

// Details labels
'height': 'Boy',
'weight': 'Kilo',
'zodiac': 'Burç',
'job': 'Meslek',
'school': 'Okul',
'smoking': 'Sigara',
'alcohol': 'Alkol',
'pets_label': 'Evcil Hayvan',
'music_type': 'Müzik Türü',
'personality': 'Kişilik',
'cm': 'cm',
'kg': 'kg',

// Preferences
'gender_preference': 'Cinsiyet Tercihi',
'age_range': 'Yaş Aralığı',
'distance_range': 'Mesafe',
'km': 'km',
'men': 'Erkek',
'women': 'Kadın',
'both': 'Herkes',

// Zodiac signs
'zodiac_aries': 'Koç',
'zodiac_taurus': 'Boğa',
'zodiac_gemini': 'İkizler',
'zodiac_cancer': 'Yengeç',
'zodiac_leo': 'Aslan',
'zodiac_virgo': 'Başak',
'zodiac_libra': 'Terazi',
'zodiac_scorpio': 'Akrep',
'zodiac_sagittarius': 'Yay',
'zodiac_capricorn': 'Oğlak',
'zodiac_aquarius': 'Kova',
'zodiac_pisces': 'Balık',

// Frequency
'freq_yes': 'Evet',
'freq_no': 'Hayır',
'freq_sometimes': 'Bazen',
```

**Step 2: Add English keys to the EN map**

Same keys with English translations:

```dart
'badge_rookie': 'Rookie',
'badge_popular': 'Popular',
'badge_master': 'Profile Master',
'badge_no_badge': 'Beginner',
'badge_progress_hint': 'left',
'badge_reward_claimed': 'Congratulations! You earned purple diamonds!',
'badge_discover_warning': 'Complete your profile to appear in discover!',
'hint_add_photos': 'Add 3 photos → 20% more visibility!',
'hint_add_bio': 'Add a bio → more matches!',
'hint_add_job': 'Add your job → complete your profile!',
'hint_add_details': 'Add details → level up your profile!',
'edit_profile': 'Edit Profile',
'edit_photos': 'Photos',
'edit_about': 'About Me',
'edit_basic_info': 'Basic Info',
'edit_details': 'Details',
'edit_preferences': 'Preferences',
'save_changes': 'Save Changes',
'bio_hint': 'Tell a bit about yourself...',
'update_location': 'Update Location',
'make_primary': 'Make Primary Photo',
'delete_photo': 'Delete Photo',
'delete_photo_confirm': 'Are you sure you want to delete this photo?',
'photo_upload_error': 'Failed to upload photo',
'photo_max_reached': 'Maximum 6 photos allowed',
'changes_saved': 'Changes saved',
'select_photo_source': 'Photo Source',
'from_gallery': 'Choose from Gallery',
'from_camera': 'Camera',
'height': 'Height',
'weight': 'Weight',
'zodiac': 'Zodiac',
'job': 'Job',
'school': 'School',
'smoking': 'Smoking',
'alcohol': 'Alcohol',
'pets_label': 'Pets',
'music_type': 'Music Type',
'personality': 'Personality',
'cm': 'cm',
'kg': 'kg',
'gender_preference': 'Gender Preference',
'age_range': 'Age Range',
'distance_range': 'Distance',
'km': 'km',
'men': 'Men',
'women': 'Women',
'both': 'Everyone',
'zodiac_aries': 'Aries',
'zodiac_taurus': 'Taurus',
'zodiac_gemini': 'Gemini',
'zodiac_cancer': 'Cancer',
'zodiac_leo': 'Leo',
'zodiac_virgo': 'Virgo',
'zodiac_libra': 'Libra',
'zodiac_scorpio': 'Scorpio',
'zodiac_sagittarius': 'Sagittarius',
'zodiac_capricorn': 'Capricorn',
'zodiac_aquarius': 'Aquarius',
'zodiac_pisces': 'Pisces',
'freq_yes': 'Yes',
'freq_no': 'No',
'freq_sometimes': 'Sometimes',
```

**Step 3: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat(i18n): add profile, badge, and edit profile translation keys"
```

---

## Phase 5: Profile Widgets

### Task 7: Photo Grid Widget (View Mode)

**Files:**
- Create: `lib/features/profile/widgets/photo_grid.dart`

**Step 1: Create photo grid widget**

This is the Tinder-style 3x2 grid. First slot is 2x size (top-left, spanning 2 rows and 2 columns). Remaining 4 slots are small squares on the right (2) and bottom (2).

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/q_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/q_icon.dart';

class PhotoGrid extends StatelessWidget {
  final List<String> photos;
  final bool editMode;
  final void Function(int index)? onSlotTap;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.editMode = false,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // 3 columns: big slot takes 2 cols, small slots take 1 col
        final smallSlotSize = (totalWidth - gap * 2) / 3;
        final bigSlotSize = smallSlotSize * 2 + gap;

        return SizedBox(
          height: bigSlotSize, // 2 rows = big slot height
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big slot (index 0)
              _PhotoSlot(
                url: photos.isNotEmpty ? photos[0] : null,
                width: bigSlotSize,
                height: bigSlotSize,
                editMode: editMode,
                isPrimary: true,
                onTap: () => onSlotTap?.call(0),
              ),
              const SizedBox(width: gap),
              // Right column: 2 small slots (index 1, 2)
              Column(
                children: [
                  _PhotoSlot(
                    url: photos.length > 1 ? photos[1] : null,
                    width: smallSlotSize,
                    height: (bigSlotSize - gap) / 2,
                    editMode: editMode,
                    onTap: () => onSlotTap?.call(1),
                  ),
                  const SizedBox(height: gap),
                  _PhotoSlot(
                    url: photos.length > 2 ? photos[2] : null,
                    width: smallSlotSize,
                    height: (bigSlotSize - gap) / 2,
                    editMode: editMode,
                    onTap: () => onSlotTap?.call(2),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Bottom row: 3 more small slots (index 3, 4, 5)
class PhotoGridFull extends StatelessWidget {
  final List<String> photos;
  final bool editMode;
  final void Function(int index)? onSlotTap;

  const PhotoGridFull({
    super.key,
    required this.photos,
    this.editMode = false,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    const gap = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final smallSlotSize = (totalWidth - gap * 2) / 3;
        final bigSlotSize = smallSlotSize * 2 + gap;

        return Column(
          children: [
            // Top row: big + 2 small
            SizedBox(
              height: bigSlotSize,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PhotoSlot(
                    url: photos.isNotEmpty ? photos[0] : null,
                    width: bigSlotSize,
                    height: bigSlotSize,
                    editMode: editMode,
                    isPrimary: true,
                    onTap: () => onSlotTap?.call(0),
                  ),
                  const SizedBox(width: gap),
                  Column(
                    children: [
                      _PhotoSlot(
                        url: photos.length > 1 ? photos[1] : null,
                        width: smallSlotSize,
                        height: (bigSlotSize - gap) / 2,
                        editMode: editMode,
                        onTap: () => onSlotTap?.call(1),
                      ),
                      const SizedBox(height: gap),
                      _PhotoSlot(
                        url: photos.length > 2 ? photos[2] : null,
                        width: smallSlotSize,
                        height: (bigSlotSize - gap) / 2,
                        editMode: editMode,
                        onTap: () => onSlotTap?.call(2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: gap),
            // Bottom row: 3 small slots
            Row(
              children: [
                _PhotoSlot(
                  url: photos.length > 3 ? photos[3] : null,
                  width: smallSlotSize,
                  height: smallSlotSize,
                  editMode: editMode,
                  onTap: () => onSlotTap?.call(3),
                ),
                const SizedBox(width: gap),
                _PhotoSlot(
                  url: photos.length > 4 ? photos[4] : null,
                  width: smallSlotSize,
                  height: smallSlotSize,
                  editMode: editMode,
                  onTap: () => onSlotTap?.call(4),
                ),
                const SizedBox(width: gap),
                _PhotoSlot(
                  url: photos.length > 5 ? photos[5] : null,
                  width: smallSlotSize,
                  height: smallSlotSize,
                  editMode: editMode,
                  onTap: () => onSlotTap?.call(5),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final bool editMode;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _PhotoSlot({
    this.url,
    required this.width,
    required this.height,
    this.editMode = false,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = url != null && url!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: hasPhoto
              ? null
              : Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: url!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: theme.colorScheme.surface,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.surface,
                      child: QIcon(QIcons.icUser, color: theme.hintColor, size: 32),
                    ),
                  ),
                  if (editMode)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QIcon(QIcons.icPencil, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              )
            : Center(
                child: QIcon(
                  QIcons.icImagePlus,
                  color: AppColors.primary.withValues(alpha: 0.5),
                  size: isPrimary ? 40 : 24,
                ),
              ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/profile/widgets/photo_grid.dart
git commit -m "feat(widget): add Tinder-style 3x2 photo grid widget"
```

---

### Task 8: Badge Bar Widget

**Files:**
- Create: `lib/features/profile/widgets/badge_bar.dart`

**Step 1: Create badge bar widget**

```dart
import 'package:flutter/material.dart';
import '../../../core/constants/q_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/q_icon.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/user_model.dart';

enum BadgeLevel { none, bronze, silver, gold }

class BadgeInfo {
  final BadgeLevel level;
  final String name;
  final String iconPath;
  final Color color;
  final double progress; // 0.0 - 1.0
  final String? hint;
  final BadgeLevel? nextLevel;
  final int? percentToNext;

  const BadgeInfo({
    required this.level,
    required this.name,
    required this.iconPath,
    required this.color,
    required this.progress,
    this.hint,
    this.nextLevel,
    this.percentToNext,
  });
}

BadgeInfo calculateBadgeInfo(BuildContext context, UserModel user) {
  final completion = user.profileCompletion;
  final photos = user.photos ?? [];
  final details = user.details;

  // Determine current level
  BadgeLevel level;
  if (completion >= 85) {
    level = BadgeLevel.gold;
  } else if (completion >= 60) {
    level = BadgeLevel.silver;
  } else if (completion >= 30) {
    level = BadgeLevel.bronze;
  } else {
    level = BadgeLevel.none;
  }

  // Calculate hint
  String? hint;
  if (level != BadgeLevel.gold) {
    if (photos.length < 3) {
      hint = context.tr('hint_add_photos');
    } else if (user.bio == null || user.bio!.isEmpty) {
      hint = context.tr('hint_add_bio');
    } else if (details?.job == null) {
      hint = context.tr('hint_add_job');
    } else {
      hint = context.tr('hint_add_details');
    }
  }

  // Next level info
  BadgeLevel? nextLevel;
  int? percentToNext;
  if (level == BadgeLevel.none) {
    nextLevel = BadgeLevel.bronze;
    percentToNext = 30 - completion;
  } else if (level == BadgeLevel.bronze) {
    nextLevel = BadgeLevel.silver;
    percentToNext = 60 - completion;
  } else if (level == BadgeLevel.silver) {
    nextLevel = BadgeLevel.gold;
    percentToNext = 85 - completion;
  }

  return BadgeInfo(
    level: level,
    name: _badgeName(context, level),
    iconPath: _badgeIcon(level),
    color: _badgeColor(level),
    progress: completion / 100,
    hint: hint,
    nextLevel: nextLevel,
    percentToNext: percentToNext,
  );
}

String _badgeName(BuildContext context, BadgeLevel level) {
  switch (level) {
    case BadgeLevel.none:
      return context.tr('badge_no_badge');
    case BadgeLevel.bronze:
      return context.tr('badge_rookie');
    case BadgeLevel.silver:
      return context.tr('badge_popular');
    case BadgeLevel.gold:
      return context.tr('badge_master');
  }
}

String _badgeIcon(BadgeLevel level) {
  switch (level) {
    case BadgeLevel.none:
      return QIcons.icBadgeBronze;
    case BadgeLevel.bronze:
      return QIcons.icBadgeBronze;
    case BadgeLevel.silver:
      return QIcons.icBadgeSilver;
    case BadgeLevel.gold:
      return QIcons.icBadgeGold;
  }
}

Color _badgeColor(BadgeLevel level) {
  switch (level) {
    case BadgeLevel.none:
      return AppColors.textHint;
    case BadgeLevel.bronze:
      return const Color(0xFFCD7F32);
    case BadgeLevel.silver:
      return const Color(0xFFC0C0C0);
    case BadgeLevel.gold:
      return const Color(0xFFFFD700);
  }
}

class BadgeBar extends StatelessWidget {
  final UserModel user;

  const BadgeBar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = calculateBadgeInfo(context, user);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: badge.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge icon + name + percentage
          Row(
            children: [
              QIcon(badge.iconPath, color: badge.color, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                badge.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: badge.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${user.profileCompletion}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: badge.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: badge.progress,
              backgroundColor: theme.colorScheme.outline,
              color: badge.color,
              minHeight: 6,
            ),
          ),

          // Hint text
          if (badge.hint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              badge.hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          // Discover warning for level none
          if (badge.level == BadgeLevel.none) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.tr('badge_discover_warning'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
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
git add lib/features/profile/widgets/badge_bar.dart
git commit -m "feat(widget): add badge bar with level progress and hints"
```

---

### Task 9: Detail Chips Widget

**Files:**
- Create: `lib/features/profile/widgets/detail_chips.dart`

**Step 1: Create detail chips widget**

```dart
import 'package:flutter/material.dart';
import '../../../core/constants/q_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/q_icon.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/user_model.dart';

class DetailChips extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const DetailChips({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = user.details;

    final chips = <_ChipData>[
      if (details?.height != null)
        _ChipData(QIcons.icHeight, '${details!.height} ${context.tr('cm')}', true)
      else
        _ChipData(QIcons.icHeight, context.tr('height'), false),

      if (details?.job != null)
        _ChipData(QIcons.icJob, details!.job!, true)
      else
        _ChipData(QIcons.icJob, context.tr('job'), false),

      if (details?.school != null)
        _ChipData(QIcons.icSchool, details!.school!, true)
      else
        _ChipData(QIcons.icSchool, context.tr('school'), false),

      if (details?.zodiac != null)
        _ChipData(QIcons.icZodiac, details!.zodiac!, true)
      else
        _ChipData(QIcons.icZodiac, context.tr('zodiac'), false),

      if (details?.smoking != null)
        _ChipData(QIcons.icSmoke, _frequencyLabel(context, details!.smoking!), true)
      else
        _ChipData(QIcons.icSmoke, context.tr('smoking'), false),

      if (details?.alcohol != null)
        _ChipData(QIcons.icUseAlcohol, _frequencyLabel(context, details!.alcohol!), true)
      else
        _ChipData(QIcons.icUseAlcohol, context.tr('alcohol'), false),

      if (details?.pets != null)
        _ChipData(QIcons.icPets, details!.pets!, true)
      else
        _ChipData(QIcons.icPets, context.tr('pets_label'), false),

      if (details?.musicType != null)
        _ChipData(QIcons.icMusic, details!.musicType!, true)
      else
        _ChipData(QIcons.icMusic, context.tr('music_type'), false),

      if (details?.personality != null)
        _ChipData(QIcons.icPersonality, details!.personality!, true)
      else
        _ChipData(QIcons.icPersonality, context.tr('personality'), false),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: chips.map((chip) => _DetailChip(data: chip)).toList(),
      ),
    );
  }

  String _frequencyLabel(BuildContext context, String freq) {
    switch (freq) {
      case 'YES':
        return context.tr('freq_yes');
      case 'NO':
        return context.tr('freq_no');
      case 'SOMETIMES':
        return context.tr('freq_sometimes');
      default:
        return freq;
    }
  }
}

class _ChipData {
  final String iconPath;
  final String label;
  final bool filled;
  const _ChipData(this.iconPath, this.label, this.filled);
}

class _DetailChip extends StatelessWidget {
  final _ChipData data;
  const _DetailChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alpha = data.filled ? 1.0 : 0.4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: data.filled
            ? AppColors.primarySurface
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: data.filled
              ? AppColors.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QIcon(
            data.iconPath,
            color: (data.filled ? AppColors.primary : theme.hintColor)
                .withValues(alpha: alpha),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            data.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: (data.filled
                      ? theme.colorScheme.onSurface
                      : theme.hintColor)
                  .withValues(alpha: alpha),
            ),
          ),
          if (!data.filled) ...[
            const SizedBox(width: 2),
            QIcon(
              QIcons.icPlus,
              color: theme.hintColor.withValues(alpha: 0.4),
              size: 10,
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
git add lib/features/profile/widgets/detail_chips.dart
git commit -m "feat(widget): add detail chips with filled/empty states"
```

---

## Phase 6: Profile Screen Rebuild

### Task 10: Rebuild Profile Screen

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart` (full rewrite)

**Step 1: Rewrite profile screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/q_icons.dart';
import '../../../core/navigation/navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/diamond_icon.dart';
import '../../../core/widgets/q_icon.dart';
import '../../../providers/user_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../routing/route_names.dart';
import '../widgets/photo_grid.dart';
import '../widgets/badge_bar.dart';
import '../widgets/detail_chips.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userProvider.notifier).fetchMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final theme = Theme.of(context);
    final nav = ref.read(navigationServiceProvider);

    return AppScaffold(
      title: context.tr('profile'),
      actions: [
        IconButton(
          icon: QIcon(QIcons.icSettings, color: theme.colorScheme.onSurfaceVariant, size: 24),
          onPressed: () => nav.go(RouteNames.settings),
        ),
      ],
      padding: EdgeInsets.zero,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('No user data'));
          final photos = user.photos ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Grid (view mode)
                PhotoGridFull(
                  photos: photos,
                  onSlotTap: (_) => nav.go(RouteNames.editProfile),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Name, Age, City
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${user.name ?? ''}, ${user.age ?? ''}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.city != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QIcon(QIcons.icMapPin, color: theme.colorScheme.onSurfaceVariant, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              user.city!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Badge Bar
                BadgeBar(user: user),
                const SizedBox(height: AppSpacing.lg),

                // About Me Card
                _SectionCard(
                  title: context.tr('edit_about'),
                  onTap: () => nav.go(RouteNames.editProfile),
                  child: Text(
                    user.bio != null && user.bio!.isNotEmpty
                        ? user.bio!
                        : context.tr('hint_add_bio'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: user.bio != null && user.bio!.isNotEmpty
                          ? theme.colorScheme.onSurface
                          : theme.hintColor,
                      fontStyle: user.bio == null || user.bio!.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Details Card
                _SectionCard(
                  title: context.tr('edit_details'),
                  onTap: () => nav.go(RouteNames.editProfile),
                  child: DetailChips(user: user),
                ),
                const SizedBox(height: AppSpacing.md),

                // Preferences Card
                _SectionCard(
                  title: context.tr('edit_preferences'),
                  onTap: () => nav.go(RouteNames.editProfile),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _PrefChip(
                        icon: QIcons.icGenderPref,
                        label: _genderPrefLabel(context, user.genderPref),
                      ),
                      _PrefChip(
                        icon: QIcons.icAgeRange,
                        label: '${user.agePrefMin ?? 18}-${user.agePrefMax ?? 45}',
                      ),
                      _PrefChip(
                        icon: QIcons.icMapPin,
                        label: '${user.matchRadiusKm ?? 50} ${context.tr('km')}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Menu Items
                _MenuItem(
                  iconPath: QIcons.icPencil,
                  title: context.tr('edit_profile'),
                  onTap: () => nav.go(RouteNames.editProfile),
                ),
                _MenuItem(
                  iconPath: QIcons.icHelpCircle,
                  title: context.tr('my_questions'),
                  onTap: () => nav.go(RouteNames.questions),
                ),
                _MenuItem(
                  iconWidget: const DiamondIcon.purple(size: 24),
                  title: context.tr('diamonds'),
                  onTap: () => nav.go(RouteNames.diamonds),
                ),
                _MenuItem(
                  iconPath: QIcons.icPlane,
                  title: context.tr('passport'),
                  onTap: () => nav.go(RouteNames.passport),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  String _genderPrefLabel(BuildContext context, String? pref) {
    switch (pref) {
      case 'MAN':
        return context.tr('men');
      case 'WOMAN':
        return context.tr('women');
      case 'BOTH':
        return context.tr('both');
      default:
        return context.tr('both');
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTap;

  const _SectionCard({required this.title, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                QIcon(QIcons.icChevronRight, color: theme.hintColor, size: 16),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _PrefChip extends StatelessWidget {
  final String icon;
  final String label;
  const _PrefChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QIcon(icon, color: AppColors.secondary, size: 14),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String? iconPath;
  final Widget? iconWidget;
  final String title;
  final VoidCallback onTap;
  const _MenuItem({this.iconPath, this.iconWidget, required this.title, required this.onTap})
      : assert(iconPath != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ListTile(
        leading: iconWidget ?? QIcon(iconPath!, color: AppColors.primary, size: 24),
        title: Text(title),
        trailing: QIcon(QIcons.icChevronRight, color: theme.hintColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/profile/screens/profile_screen.dart
git commit -m "feat(profile): rebuild profile screen with photo grid, badge bar, and detail chips"
```

---

## Phase 7: Edit Profile Screen

### Task 11: Add Edit Profile Route

**Files:**
- Modify: `lib/routing/route_names.dart` (editProfile zaten var, kontrol et)
- Modify: `lib/routing/app_routes.dart`

**Step 1: Verify editProfile route name exists**

`route_names.dart`'ta zaten `static const editProfile = 'edit-profile';` var.

**Step 2: Add route to app_routes.dart**

Profile routes listesine ekle (questions, diamonds, passport, settings yanina):

```dart
GoRoute(
  path: 'edit',
  name: RouteNames.editProfile,
  builder: (context, state) => const EditProfileScreen(),
),
```

Import ekle:

```dart
import '../features/profile/screens/edit_profile_screen.dart';
```

**Step 3: Commit**

```bash
git add lib/routing/app_routes.dart
git commit -m "feat(routing): add edit profile route"
```

---

### Task 12: Edit Profile Screen

**Files:**
- Create: `lib/features/profile/screens/edit_profile_screen.dart`

**Step 1: Create edit profile screen**

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/q_icons.dart';
import '../../../core/navigation/navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/q_icon.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/location_provider.dart';
import '../widgets/photo_grid.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _jobController = TextEditingController();
  final _schoolController = TextEditingController();
  final _petsController = TextEditingController();
  final _musicController = TextEditingController();
  final _personalityController = TextEditingController();

  int? _height;
  int? _weight;
  String? _zodiac;
  String? _smoking;
  String? _alcohol;
  String? _genderPref;
  int _agePrefMin = 18;
  int _agePrefMax = 45;
  int _matchRadiusKm = 50;

  bool _isLoading = false;
  bool _isUploading = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) return;

    _bioController.text = user.bio ?? '';
    _cityController.text = user.city ?? '';
    _genderPref = user.genderPref ?? 'BOTH';
    _agePrefMin = user.agePrefMin ?? 18;
    _agePrefMax = user.agePrefMax ?? 45;
    _matchRadiusKm = user.matchRadiusKm ?? 50;

    final d = user.details;
    if (d != null) {
      _height = d.height;
      _weight = d.weight;
      _zodiac = d.zodiac;
      _smoking = d.smoking;
      _alcohol = d.alcohol;
      _jobController.text = d.job ?? '';
      _schoolController.text = d.school ?? '';
      _petsController.text = d.pets ?? '';
      _musicController.text = d.musicType ?? '';
      _personalityController.text = d.personality ?? '';
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _jobController.dispose();
    _schoolController.dispose();
    _petsController.dispose();
    _musicController.dispose();
    _personalityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final photos = user.photos ?? [];

    return AppScaffold(
      title: context.tr('edit_profile'),
      showBackButton: true,
      padding: EdgeInsets.zero,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              100, // space for sticky button
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Photos ───
                _SectionTitle(context.tr('edit_photos')),
                const SizedBox(height: AppSpacing.sm),
                if (_isUploading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ))
                else
                  PhotoGridFull(
                    photos: photos,
                    editMode: true,
                    onSlotTap: (index) => _handlePhotoSlotTap(index, photos),
                  ),
                const SizedBox(height: AppSpacing.sectionGap),

                // ─── About ───
                _SectionTitle(context.tr('edit_about')),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _bioController,
                  hint: context.tr('bio_hint'),
                  maxLines: 4,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_bioController.text.length}/300',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // ─── Basic Info ───
                _SectionTitle(context.tr('edit_basic_info')),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: TextEditingController(text: user.name ?? ''),
                  label: context.tr('step_name'),
                  maxLines: 1,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _cityController,
                        label: context.tr('city'),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: _updateLocation,
                      icon: QIcon(QIcons.icLocationTick, color: AppColors.secondary, size: 24),
                      tooltip: context.tr('update_location'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // ─── Details ───
                _SectionTitle(context.tr('edit_details')),
                const SizedBox(height: AppSpacing.sm),
                // Height & Weight
                Row(
                  children: [
                    Expanded(child: _NumberField(
                      label: context.tr('height'),
                      suffix: context.tr('cm'),
                      value: _height,
                      min: 140, max: 220,
                      onChanged: (v) => setState(() => _height = v),
                    )),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _NumberField(
                      label: context.tr('weight'),
                      suffix: context.tr('kg'),
                      value: _weight,
                      min: 40, max: 200,
                      onChanged: (v) => setState(() => _weight = v),
                    )),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Zodiac
                _DropdownField(
                  label: context.tr('zodiac'),
                  value: _zodiac,
                  items: _zodiacSigns(context),
                  onChanged: (v) => setState(() => _zodiac = v),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _jobController, label: context.tr('job'), maxLines: 1),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _schoolController, label: context.tr('school'), maxLines: 1),
                const SizedBox(height: AppSpacing.md),
                // Smoking & Alcohol
                Row(
                  children: [
                    Expanded(child: _FrequencyField(
                      label: context.tr('smoking'),
                      value: _smoking,
                      onChanged: (v) => setState(() => _smoking = v),
                    )),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _FrequencyField(
                      label: context.tr('alcohol'),
                      value: _alcohol,
                      onChanged: (v) => setState(() => _alcohol = v),
                    )),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _petsController, label: context.tr('pets_label'), maxLines: 1),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _musicController, label: context.tr('music_type'), maxLines: 1),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _personalityController, label: context.tr('personality'), maxLines: 1),
                const SizedBox(height: AppSpacing.sectionGap),

                // ─── Preferences ───
                _SectionTitle(context.tr('edit_preferences')),
                const SizedBox(height: AppSpacing.sm),
                // Gender Pref
                Text(context.tr('gender_preference'), style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'MAN', label: Text(context.tr('men'))),
                    ButtonSegment(value: 'WOMAN', label: Text(context.tr('women'))),
                    ButtonSegment(value: 'BOTH', label: Text(context.tr('both'))),
                  ],
                  selected: {_genderPref ?? 'BOTH'},
                  onSelectionChanged: (v) => setState(() => _genderPref = v.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Age Range
                Text(
                  '${context.tr('age_range')}: $_agePrefMin - $_agePrefMax',
                  style: theme.textTheme.bodyMedium,
                ),
                RangeSlider(
                  values: RangeValues(_agePrefMin.toDouble(), _agePrefMax.toDouble()),
                  min: 18,
                  max: 99,
                  divisions: 81,
                  labels: RangeLabels('$_agePrefMin', '$_agePrefMax'),
                  onChanged: (v) => setState(() {
                    _agePrefMin = v.start.round();
                    _agePrefMax = v.end.round();
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                // Distance
                Text(
                  '${context.tr('distance_range')}: $_matchRadiusKm ${context.tr('km')}',
                  style: theme.textTheme.bodyMedium,
                ),
                Slider(
                  value: _matchRadiusKm.toDouble(),
                  min: 1,
                  max: 500,
                  divisions: 499,
                  label: '$_matchRadiusKm km',
                  onChanged: (v) => setState(() => _matchRadiusKm = v.round()),
                ),
              ],
            ),
          ),

          // Sticky Save Button
          Positioned(
            left: AppSpacing.pagePadding,
            right: AppSpacing.pagePadding,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.pagePadding,
            child: AppButton(
              label: context.tr('save_changes'),
              isLoading: _isLoading,
              fullWidth: true,
              onPressed: _isLoading ? null : _saveChanges,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePhotoSlotTap(int index, List<String> photos) async {
    final nav = ref.read(navigationServiceProvider);
    final hasPhoto = index < photos.length;

    if (hasPhoto) {
      // Show options: make primary / delete
      nav.showAppBottomSheet(
        ListBottomSheet(
          title: context.tr('edit_photos'),
          items: [
            if (index != 0)
              ListBottomSheetItem(
                title: context.tr('make_primary'),
                icon: QIcons.icCheckCircle,
                onTap: () => _makePrimary(index, photos),
              ),
            ListBottomSheetItem(
              title: context.tr('delete_photo'),
              icon: QIcons.icTrash2,
              isDestructive: true,
              onTap: () => _confirmDeletePhoto(index),
            ),
          ],
        ),
      );
    } else {
      // Upload new photo
      if (photos.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('photo_max_reached'))),
        );
        return;
      }
      _showPhotoSourcePicker();
    }
  }

  void _showPhotoSourcePicker() {
    ref.read(navigationServiceProvider).showAppBottomSheet(
      ListBottomSheet(
        title: context.tr('select_photo_source'),
        items: [
          ListBottomSheetItem(
            title: context.tr('from_gallery'),
            icon: QIcons.icImagePlus,
            onTap: () => _pickAndUpload(ImageSource.gallery),
          ),
          ListBottomSheetItem(
            title: context.tr('from_camera'),
            icon: QIcons.icPhotoCamera,
            onTap: () => _pickAndUpload(ImageSource.camera),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1080, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploading = true);
    final bytes = await picked.readAsBytes();
    final mimeType = picked.path.endsWith('.png') ? 'image/png' : 'image/jpeg';

    final result = await ref.read(userProvider.notifier).uploadPhoto(bytes, mimeType);
    result.when(
      success: (_) {},
      failure: (f) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('photo_upload_error'))),
          );
        }
      },
    );
    if (mounted) setState(() => _isUploading = false);
  }

  Future<void> _makePrimary(int index, List<String> photos) async {
    final reordered = List<String>.from(photos);
    final photo = reordered.removeAt(index);
    reordered.insert(0, photo);
    await ref.read(userProvider.notifier).reorderPhotos(reordered);
  }

  Future<void> _confirmDeletePhoto(int index) async {
    ref.read(navigationServiceProvider).showAppDialog(
      ConfirmDialog(
        title: context.tr('delete_photo'),
        message: context.tr('delete_photo_confirm'),
        confirmLabel: context.tr('delete'),
        onConfirm: () async {
          await ref.read(userProvider.notifier).deletePhoto(index);
        },
      ),
    );
  }

  Future<void> _updateLocation() async {
    final location = ref.read(locationProvider);
    if (location != null) {
      await ref.read(userProvider.notifier).updateLocation(
        lat: location.latitude,
        lng: location.longitude,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('location_granted'))),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    // 1. Update profile (bio, city, preferences)
    await ref.read(userProvider.notifier).updateProfile({
      'bio': _bioController.text.isEmpty ? null : _bioController.text,
      'city': _cityController.text.isEmpty ? null : _cityController.text,
      'gender_pref': _genderPref,
      'age_pref_min': _agePrefMin,
      'age_pref_max': _agePrefMax,
      'match_radius_km': _matchRadiusKm,
    });

    // 2. Update details
    await ref.read(userProvider.notifier).updateDetails({
      'height': _height,
      'weight': _weight,
      'zodiac': _zodiac,
      'job': _jobController.text.isEmpty ? null : _jobController.text,
      'school': _schoolController.text.isEmpty ? null : _schoolController.text,
      'smoking': _smoking,
      'alcohol': _alcohol,
      'pets': _petsController.text.isEmpty ? null : _petsController.text,
      'music_type': _musicController.text.isEmpty ? null : _musicController.text,
      'personality': _personalityController.text.isEmpty ? null : _personalityController.text,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('changes_saved'))),
      );
      ref.read(navigationServiceProvider).pop();
    }
  }

  List<DropdownMenuItem<String>> _zodiacSigns(BuildContext context) {
    final signs = [
      'zodiac_aries', 'zodiac_taurus', 'zodiac_gemini', 'zodiac_cancer',
      'zodiac_leo', 'zodiac_virgo', 'zodiac_libra', 'zodiac_scorpio',
      'zodiac_sagittarius', 'zodiac_capricorn', 'zodiac_aquarius', 'zodiac_pisces',
    ];
    return signs.map((s) {
      final value = context.tr(s);
      return DropdownMenuItem(value: value, child: Text(value));
    }).toList();
  }
}

// ─── Helper Widgets ───

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final String suffix;
  final int? value;
  final int min;
  final int max;
  final ValueChanged<int?> onChanged;

  const _NumberField({
    required this.label,
    required this.suffix,
    this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: TextEditingController(text: value?.toString() ?? ''),
      label: '$label ($suffix)',
      keyboardType: TextInputType.number,
      maxLines: 1,
      validator: (v) {
        if (v == null || v.isEmpty) return null;
        final n = int.tryParse(v);
        if (n == null || n < min || n > max) return '$min-$max';
        return null;
      },
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(suffix, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),
      dropdownColor: theme.colorScheme.surface,
      items: items,
      onChanged: onChanged,
    );
  }
}

class _FrequencyField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _FrequencyField({
    required this.label,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _DropdownField(
      label: label,
      value: value,
      items: [
        DropdownMenuItem(value: 'YES', child: Text(context.tr('freq_yes'))),
        DropdownMenuItem(value: 'NO', child: Text(context.tr('freq_no'))),
        DropdownMenuItem(value: 'SOMETIMES', child: Text(context.tr('freq_sometimes'))),
      ],
      onChanged: onChanged,
    );
  }
}
```

**Step 2: Add image_picker dependency**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter pub add image_picker
```

**Step 3: Commit**

```bash
git add lib/features/profile/screens/edit_profile_screen.dart pubspec.yaml pubspec.lock
git commit -m "feat(profile): add edit profile screen with photo upload, details form, and preferences"
```

---

## Phase 8: Badge Reward Claim Integration

### Task 13: Badge Reward Claim Flow

**Files:**
- Modify: `lib/features/profile/widgets/badge_bar.dart` (add claim button)
- Modify: `lib/features/profile/screens/profile_screen.dart` (trigger claim check)

**Step 1: Add claim logic to BadgeBar**

Update `BadgeBar` to accept a callback and show claim button when a new level is reached but not yet claimed:

Add to `BadgeBar` widget params:

```dart
final Future<void> Function(String level)? onClaimReward;
```

Add inside the Column, after the hint text section:

```dart
// Claim button for unclaimed Silver/Gold
if (_canClaimReward(user, BadgeLevel.silver) || _canClaimReward(user, BadgeLevel.gold)) ...[
  const SizedBox(height: AppSpacing.sm),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () {
        final level = _canClaimReward(user, BadgeLevel.gold) ? 'GOLD' : 'SILVER';
        onClaimReward?.call(level);
      },
      icon: const DiamondIcon.purple(size: 16),
      label: Text(context.tr('badge_reward_claimed')),
      style: OutlinedButton.styleFrom(
        foregroundColor: badge.color,
        side: BorderSide(color: badge.color),
      ),
    ),
  ),
],
```

Add helper:

```dart
bool _canClaimReward(UserModel user, BadgeLevel level) {
  final claimed = user.badgeRewardsClaimed;
  final levelStr = level == BadgeLevel.silver ? 'SILVER' : 'GOLD';
  final threshold = level == BadgeLevel.silver ? 60 : 85;
  return user.profileCompletion >= threshold && !claimed.contains(levelStr);
}
```

**Step 2: Wire claim in profile screen**

In `ProfileScreen`, pass callback to `BadgeBar`:

```dart
BadgeBar(
  user: user,
  onClaimReward: (level) async {
    final result = await ref.read(userProvider.notifier).claimBadgeReward(level);
    result.when(
      success: (data) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('badge_reward_claimed'))),
        );
      },
      failure: (_) {},
    );
  },
),
```

**Step 3: Commit**

```bash
git add lib/features/profile/widgets/badge_bar.dart lib/features/profile/screens/profile_screen.dart
git commit -m "feat(profile): add badge reward claim flow with diamond incentives"
```

---

## Phase 9: Final Wiring & Cleanup

### Task 14: Verify Compilation & Fix Imports

**Step 1: Run Flutter analyze**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze
```

**Step 2: Fix any import or type errors found**

Common issues to check:
- `ListBottomSheet`, `ListBottomSheetItem`, `ConfirmDialog` imports from navigation barrel
- `DiamondIcon` import in badge_bar.dart
- `locationProvider` import check
- `_NumberField` onChanged should capture text → parse to int

**Step 3: Run the app**

```bash
flutter run
```

**Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve compilation errors and missing imports"
```

---

### Task 15: Backend TypeScript Compilation Check

**Step 1: Verify server compiles**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2/server && npx tsc --noEmit
```

**Step 2: Check diamondService.addPurple exists**

Verify `server/src/services/diamond.service.ts` has an `addPurple` method. If not, it may be named differently (e.g., `addDiamonds` with type parameter). Adjust `badge.service.ts` accordingly.

**Step 3: Fix any TS errors and commit**

```bash
git add server/
git commit -m "fix(server): resolve badge service compilation issues"
```

---

### Task 16: Migration Reminder & Final Commit

**Step 1: Remind user to run migration**

Print reminder:
```
IMPORTANT: Run this SQL in Supabase SQL Editor:
ALTER TABLE users ADD COLUMN IF NOT EXISTS badge_rewards_claimed TEXT[] DEFAULT '{}';
```

**Step 2: Final integration commit**

```bash
git add -A
git commit -m "feat: complete profile & photo management feature with badge system"
```

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1 | 1-2 | Backend: Migration + Badge Service |
| 2 | 3-4 | Flutter: Model & Provider updates |
| 3 | 5 | SVG Icons (9 new icons) |
| 4 | 6 | i18n keys (TR + EN) |
| 5 | 7-9 | Profile widgets (PhotoGrid, BadgeBar, DetailChips) |
| 6 | 10 | Profile screen rebuild |
| 7 | 11-12 | Edit Profile screen + route |
| 8 | 13 | Badge reward claim integration |
| 9 | 14-16 | Compilation, fixes, final wiring |
