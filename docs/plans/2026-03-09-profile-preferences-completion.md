# Profile Preferences & Completion Incentive System — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix existing preference bugs, add relationship_goal + preferred_languages, redesign edit profile with card-based UI, and implement a karma completion incentive system (diamonds + boost + badge).

**Architecture:** DB migration adds new fields/enums → backend validators/services updated → Flutter models updated → UI refactored to card layout with progress tracking → completion rewards system wired end-to-end.

**Tech Stack:** PostgreSQL (Supabase), Node.js/Express/TypeScript (Zod validation), Flutter/Dart (Riverpod + GoRouter), existing diamond service for rewards.

---

## Task 1: Bug Fix — Gender Pref Enum Tutarsızlığı

**Files:**
- Modify: `lib/features/profile/screens/edit_profile_screen.dart:566-568`

**Problem:** Flutter SegmentedButton `'MALE'`/`'FEMALE'`/`'ALL'` gönderiyor, backend enum `'MAN'`/`'WOMAN'`/`'BOTH'` bekliyor.

**Step 1: Fix SegmentedButton values**

`lib/features/profile/screens/edit_profile_screen.dart` satır 566-568'de:

```dart
// ÖNCE (HATALI):
ButtonSegment(value: 'MALE', label: Text(context.tr('male'))),
ButtonSegment(value: 'FEMALE', label: Text(context.tr('female'))),
ButtonSegment(value: 'ALL', label: Text(context.tr('all'))),

// SONRA (DOĞRU):
ButtonSegment(value: 'MAN', label: Text(context.tr('male'))),
ButtonSegment(value: 'WOMAN', label: Text(context.tr('female'))),
ButtonSegment(value: 'BOTH', label: Text(context.tr('all'))),
```

**Step 2: Fix genderPref display in profile_screen.dart**

`lib/features/profile/screens/profile_screen.dart`'daki `_genderPrefLabel` metodunu kontrol et ve `'MAN'`/`'WOMAN'`/`'BOTH'` değerleriyle çalıştığından emin ol.

**Step 3: Fix editProfileProvider initialization**

`lib/providers/edit_profile_provider.dart`'da `initFromUser()` metodunda gelen `genderPref` değerinin (`'MAN'`/`'WOMAN'`/`'BOTH'`) SegmentedButton'a doğru aktarıldığını doğrula.

**Step 4: Test**

Run: `flutter analyze`
Manual test: Edit profile → change gender pref → save → check backend receives MAN/WOMAN/BOTH

**Step 5: Commit**

```bash
git add lib/features/profile/screens/edit_profile_screen.dart lib/features/profile/screens/profile_screen.dart lib/providers/edit_profile_provider.dart
git commit -m "fix: align gender_pref enum values with backend (MAN/WOMAN/BOTH)"
```

---

## Task 2: DB Migration — Yeni Alanlar

**Files:**
- Create: `supabase/migrations/012_profile_preferences_completion.sql`

**Step 1: Write migration SQL**

```sql
-- Yeni enum: ilişki amacı
CREATE TYPE relationship_goal_type AS ENUM ('SERIOUS', 'FRIENDSHIP', 'NOT_SURE');

-- Users tablosuna yeni alanlar
ALTER TABLE users ADD COLUMN relationship_goal relationship_goal_type DEFAULT 'NOT_SURE';
ALTER TABLE users ADD COLUMN preferred_languages TEXT[] DEFAULT ARRAY['tr'];
ALTER TABLE users ADD COLUMN completion_rewards_claimed JSONB DEFAULT '{}';
```

**Step 2: Commit**

```bash
git add supabase/migrations/012_profile_preferences_completion.sql
git commit -m "feat: add migration 012 — relationship_goal, preferred_languages, completion_rewards"
```

> **Not:** Migration Supabase SQL Editor'dan manuel çalıştırılacak.

---

## Task 3: Backend — Validator Güncellemesi

**Files:**
- Modify: `server/src/validators/user.validator.ts:4-17`

**Step 1: Add new fields to updateProfileSchema**

`server/src/validators/user.validator.ts` satır 4-17'deki `updateProfileSchema`'ya ekle:

```typescript
// Mevcut alanlara ek olarak:
relationship_goal: z.enum(["SERIOUS", "FRIENDSHIP", "NOT_SURE"]).optional(),
preferred_languages: z.array(z.enum(["tr", "en", "de", "fr", "ar", "ru", "es"])).min(1).max(7).optional(),
```

**Step 2: Run tests**

Run: `cd server && npm test`

**Step 3: Commit**

```bash
git add server/src/validators/user.validator.ts
git commit -m "feat: add relationship_goal and preferred_languages to profile validator"
```

---

## Task 4: Backend — Profil Tamamlama Formülü Güncelleme

**Files:**
- Modify: `server/src/services/user.service.ts:275-320`

**Step 1: Update recalculateProfileCompletion**

`server/src/services/user.service.ts` satır 275-320'deki `recalculateProfileCompletion` fonksiyonunda:

1. `total` değerini `14`'ten `16`'ya değiştir (satır 291)
2. Yeni alan kontrollerini ekle (detail field'lardan sonra):

```typescript
// Yeni alanlar (user tablosundan)
if (user.relationship_goal && user.relationship_goal !== 'NOT_SURE') score++;
if (user.preferred_languages && user.preferred_languages.length > 0) score++;
```

3. `recalculateProfileCompletion` fonksiyonundaki user fetch sorgusuna `relationship_goal` ve `preferred_languages` alanlarını ekle.

**Step 2: Add completion reward check logic**

Aynı dosyada, `recalculateProfileCompletion` fonksiyonunun sonuna milestone kontrolü ekle:

```typescript
// Milestone ödül kontrolü
const milestones = [
  { threshold: 25, reward: 5 },
  { threshold: 50, reward: 15 },
  { threshold: 75, reward: 30 },
  { threshold: 100, reward: 50 },
];

const claimed = user.completion_rewards_claimed || {};
const newCompletion = Math.round((score / total) * 100);

for (const m of milestones) {
  if (newCompletion >= m.threshold && !claimed[String(m.threshold)]) {
    // Mor elmas ver
    await diamondService.earnPurple(userId, m.reward, 'PROFILE_COMPLETION', `milestone_${m.threshold}`);
    claimed[String(m.threshold)] = true;

    // %100 ise 24 saatlik mini-boost
    if (m.threshold === 100) {
      const boostUntil = new Date(Date.now() + 24 * 60 * 60 * 1000);
      await supabase.from('users').update({ boost_until: boostUntil.toISOString() }).eq('id', userId);
    }
  }
}

// claimed güncelle
await supabase.from('users').update({ completion_rewards_claimed: claimed }).eq('id', userId);
```

**Step 3: Run tests**

Run: `cd server && npm test`

**Step 4: Commit**

```bash
git add server/src/services/user.service.ts
git commit -m "feat: update profile completion formula to 16 fields + milestone rewards"
```

---

## Task 5: Backend — Matching Service Güncelleme

**Files:**
- Modify: `server/src/services/matching.service.ts:205-227`

**Step 1: Enhance language filter with preferred_languages**

`server/src/services/matching.service.ts` satır 205-227'deki dil filtresini güncelle:

```typescript
// Kullanıcının preferred_languages'ını kullan (varsa), yoksa mevcut userLanguages'a fallback
const langPrefs = user.preferred_languages && user.preferred_languages.length > 0
  ? user.preferred_languages
  : userLanguages;

discoverableFiltered = discoverableFiltered.filter((c) => {
  const qLocales = questionLocalesByUser.get(c.id) || [];
  const matchingCount = qLocales.filter((l: string) => langPrefs.includes(l)).length;
  return matchingCount >= 2;
});
```

**Step 2: Add relationship_goal to discover card response**

Discover endpoint'in card build kısmında (satır 271-283) `relationship_goal` alanını response'a ekle.

**Step 3: Run tests**

Run: `cd server && npm test`

**Step 4: Commit**

```bash
git add server/src/services/matching.service.ts
git commit -m "feat: use preferred_languages in matching + expose relationship_goal in discover"
```

---

## Task 6: Flutter — Model Güncellemeleri

**Files:**
- Modify: `lib/data/models/user_model.dart`
- Modify: `lib/data/models/discover_model.dart`

**Step 1: Update UserModel**

`lib/data/models/user_model.dart`'a yeni alanlar ekle:

```dart
@JsonKey(name: 'relationship_goal')
final String? relationshipGoal;

@JsonKey(name: 'preferred_languages', defaultValue: [])
final List<String> preferredLanguages;

@JsonKey(name: 'completion_rewards_claimed', defaultValue: {})
final Map<String, dynamic> completionRewardsClaimed;
```

Constructor, fromJson, toJson, copyWith, == ve hashCode'u güncelle.

**Step 2: Update DiscoverModel**

`lib/data/models/discover_model.dart`'a `relationshipGoal` alanı ekle:

```dart
@JsonKey(name: 'relationship_goal')
final String? relationshipGoal;
```

**Step 3: Verify**

Run: `flutter analyze`

**Step 4: Commit**

```bash
git add lib/data/models/user_model.dart lib/data/models/discover_model.dart
git commit -m "feat: add relationship_goal, preferred_languages, completion_rewards to models"
```

---

## Task 7: Flutter — EditProfileProvider Güncelleme

**Files:**
- Modify: `lib/providers/edit_profile_provider.dart`

**Step 1: Add new state fields**

`EditProfileState` sınıfına (satır 5-52) ekle:

```dart
final String? selectedRelationshipGoal;
final List<String> selectedLanguages;
```

Default değerler: `selectedRelationshipGoal: null`, `selectedLanguages: const []`

**Step 2: Add setter methods**

`EditProfileNotifier`'a (satır 77-86) ekle:

```dart
void setRelationshipGoal(String? v) => state = state.copyWith(selectedRelationshipGoal: () => v);
void setLanguages(List<String> v) => state = state.copyWith(selectedLanguages: v);
void toggleLanguage(String lang) {
  final current = List<String>.from(state.selectedLanguages);
  if (current.contains(lang)) {
    if (current.length > 1) current.remove(lang); // En az 1 dil kalmalı
  } else {
    current.add(lang);
  }
  state = state.copyWith(selectedLanguages: current);
}
```

**Step 3: Update initFromUser**

`initFromUser` metodunda yeni alanları user'dan yükle:

```dart
selectedRelationshipGoal: user.relationshipGoal,
selectedLanguages: user.preferredLanguages.isNotEmpty ? user.preferredLanguages : [user.locale ?? 'tr'],
```

**Step 4: Update copyWith**

Tüm yeni alanlar için `copyWith` parametreleri ekle.

**Step 5: Commit**

```bash
git add lib/providers/edit_profile_provider.dart
git commit -m "feat: add relationship_goal and languages to edit profile state"
```

---

## Task 8: Flutter — ProfileSectionCard Widget

**Files:**
- Create: `lib/core/widgets/profile_section_card.dart`

**Step 1: Create shared widget**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? completionText; // ör. "3/4"
  final bool isComplete;
  final Widget child;

  const ProfileSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.completionText,
    this.isComplete = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (completionText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppColors.secondary.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isComplete)
                        const Icon(Icons.check, color: AppColors.secondary, size: 14),
                      if (isComplete) const SizedBox(width: 2),
                      Text(
                        completionText!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isComplete ? AppColors.secondary : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Content
          child,
        ],
      ),
    );
  }
}
```

**Step 2: Verify**

Run: `flutter analyze`

**Step 3: Commit**

```bash
git add lib/core/widgets/profile_section_card.dart
git commit -m "feat: add ProfileSectionCard shared widget"
```

---

## Task 9: Flutter — Edit Profile Ekranı Refactor

**Files:**
- Modify: `lib/features/profile/screens/edit_profile_screen.dart`

Bu en büyük task. Edit profile ekranını kartlı yapıya dönüştür.

**Step 1: Add progress bar at top**

Ekranın en üstüne (photo grid'den önce) global completion progress bar ekle:

```dart
// Profil tamamlama progress bar
Column(
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.tr('profile_completion'),
          style: theme.textTheme.titleSmall,
        ),
        Text(
          '%${user.profileCompletion}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
    const SizedBox(height: AppSpacing.sm),
    ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: LinearProgressIndicator(
        value: user.profileCompletion / 100,
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        minHeight: 8,
      ),
    ),
    // Motivasyon mesajı
    if (_nextMilestone(user.profileCompletion) != null) ...[
      const SizedBox(height: AppSpacing.sm),
      Text(
        _milestoneMessage(context, user.profileCompletion),
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
      ),
    ],
  ],
),
```

Helper metot:
```dart
int? _nextMilestone(int completion) {
  for (final m in [25, 50, 75, 100]) {
    if (completion < m) return m;
  }
  return null;
}

String _milestoneMessage(BuildContext context, int completion) {
  final next = _nextMilestone(completion);
  final rewards = {25: 5, 50: 15, 75: 30, 100: 50};
  if (next == null) return '';
  return '%$next\'e az kaldı! ${rewards[next]} 💎 kazanmak için tamamla';
}
```

**Step 2: Wrap each section in ProfileSectionCard**

Mevcut 6 section'ı `ProfileSectionCard` ile sar. Her birinde:

| Section | icon | title | subtitle | completionText |
|---------|------|-------|----------|----------------|
| Fotoğraflar | Icons.photo_library | tr('photos') | tr('first_photo_is_profile') | "x/6" |
| Hakkımda | Icons.edit_note | tr('about') | tr('introduce_yourself') | "0/1" veya "1/1" |
| Temel Bilgiler | Icons.person | tr('basic_info') | tr('help_us_know_you') | "x/4" |
| Detaylar | Icons.interests | tr('details') | tr('enrich_profile_more_matches') | "x/8" |
| Tercihler | Icons.tune | tr('preferences') | tr('show_you_right_people') | "x/4" |
| İlişki Amacı | Icons.favorite | tr('relationship_goal') | tr('let_others_know_what_you_seek') | "0/1" veya "1/1" |

Eski `_sectionTitle()` metodunu kaldır, yerini `ProfileSectionCard` alsın.

**Step 3: Add relationship_goal SegmentedButton**

Son kart içine:

```dart
ProfileSectionCard(
  icon: Icons.favorite,
  title: context.tr('relationship_goal'),
  subtitle: context.tr('let_others_know_what_you_seek'),
  completionText: editState.selectedRelationshipGoal != null &&
      editState.selectedRelationshipGoal != 'NOT_SURE' ? '1/1' : '0/1',
  isComplete: editState.selectedRelationshipGoal != null &&
      editState.selectedRelationshipGoal != 'NOT_SURE',
  child: SegmentedButton<String>(
    segments: [
      ButtonSegment(value: 'SERIOUS', label: Text(context.tr('serious_relationship'))),
      ButtonSegment(value: 'FRIENDSHIP', label: Text(context.tr('friendship'))),
      ButtonSegment(value: 'NOT_SURE', label: Text(context.tr('not_sure'))),
    ],
    selected: {editState.selectedRelationshipGoal ?? 'NOT_SURE'},
    onSelectionChanged: (v) => editNotifier.setRelationshipGoal(v.first),
  ),
),
```

**Step 4: Add preferred_languages multi-select chips**

Tercihler kartı içine (mesafe slider'ından sonra):

```dart
const SizedBox(height: AppSpacing.lg),
Text(
  context.tr('language_preference'),
  style: theme.textTheme.bodyMedium?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  ),
),
const SizedBox(height: AppSpacing.sm),
Wrap(
  spacing: AppSpacing.sm,
  runSpacing: AppSpacing.sm,
  children: ['tr', 'en', 'de', 'fr', 'ar', 'ru', 'es'].map((lang) {
    final isSelected = editState.selectedLanguages.contains(lang);
    return FilterChip(
      label: Text(_languageLabel(lang)),
      selected: isSelected,
      onSelected: (_) => editNotifier.toggleLanguage(lang),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }).toList(),
),
```

Helper:
```dart
String _languageLabel(String code) {
  return switch (code) {
    'tr' => 'Türkçe',
    'en' => 'English',
    'de' => 'Deutsch',
    'fr' => 'Français',
    'ar' => 'العربية',
    'ru' => 'Русский',
    'es' => 'Español',
    _ => code,
  };
}
```

**Step 5: Update save method**

Save metoduna (satır 227-268) yeni alanları ekle:

```dart
// profileData'ya ekle:
'relationship_goal': editState.selectedRelationshipGoal,
'preferred_languages': editState.selectedLanguages,
```

**Step 6: Verify**

Run: `flutter analyze`

**Step 7: Commit**

```bash
git add lib/features/profile/screens/edit_profile_screen.dart
git commit -m "feat: refactor edit profile to card-based layout with new preferences"
```

---

## Task 10: Flutter — Profile Screen Güncelleme

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`

**Step 1: Add relationship_goal badge to preference chips**

Satır 218-243'teki preference chips section'ına ekle:

```dart
if (user.relationshipGoal != null && user.relationshipGoal != 'NOT_SURE')
  _PrefChip(
    iconPath: QIcons.icHeart, // veya uygun ikon
    label: _relationshipGoalLabel(context, user.relationshipGoal),
  ),
```

Helper:
```dart
String _relationshipGoalLabel(BuildContext context, String? goal) {
  return switch (goal) {
    'SERIOUS' => context.tr('serious_relationship'),
    'FRIENDSHIP' => context.tr('friendship'),
    _ => context.tr('not_sure'),
  };
}
```

**Step 2: Add language chips**

```dart
if (user.preferredLanguages.isNotEmpty)
  _PrefChip(
    iconPath: QIcons.icLanguage, // veya uygun ikon
    label: user.preferredLanguages.map(_languageFlag).join(', '),
  ),
```

**Step 3: Commit**

```bash
git add lib/features/profile/screens/profile_screen.dart
git commit -m "feat: show relationship_goal and languages on profile screen"
```

---

## Task 11: Flutter — Discover Card'da Relationship Goal Badge

**Files:**
- Modify: `lib/features/discover/widgets/profile_card.dart`

**Step 1: Add relationship_goal badge**

Kullanıcı bilgi alanında (satır 48-73), isim/yaş satırından sonra:

```dart
if (card.relationshipGoal != null && card.relationshipGoal != 'NOT_SURE')
  Container(
    margin: const EdgeInsets.only(top: AppSpacing.xs),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    ),
    child: Text(
      _relationshipGoalLabel(context, card.relationshipGoal),
      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary),
    ),
  ),
```

**Step 2: Commit**

```bash
git add lib/features/discover/widgets/profile_card.dart
git commit -m "feat: show relationship_goal badge on discover cards"
```

---

## Task 12: Flutter — Milestone Celebration Bottom Sheet

**Files:**
- Create: `lib/core/widgets/milestone_celebration_sheet.dart`

**Step 1: Create celebration widget**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'diamond_icon.dart';

class MilestoneCelebrationSheet extends StatelessWidget {
  final int milestone;
  final int diamondReward;

  const MilestoneCelebrationSheet({
    super.key,
    required this.milestone,
    required this.diamondReward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Celebration icon
          const Icon(Icons.celebration, color: AppColors.primary, size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tebrikler!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Profilini %$milestone tamamladın!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Diamond reward
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DiamondIcon.purple(size: 32),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '+$diamondReward',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mor elmas kazandın!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (milestone == 100) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppColors.secondary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '24 saatlik ücretsiz boost kazandın!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/widgets/milestone_celebration_sheet.dart
git commit -m "feat: add MilestoneCelebrationSheet widget"
```

---

## Task 13: Flutter — Milestone Ödül Kontrolü Entegrasyonu

**Files:**
- Modify: `lib/providers/user_provider.dart`
- Modify: `lib/features/profile/screens/edit_profile_screen.dart`

**Step 1: Add milestone check to userProvider**

`updateProfile` ve `updateDetails` response'unda backend'den dönen `completion_rewards_claimed` değerini kontrol et. Önceki state ile karşılaştır — yeni milestone varsa bildir.

```dart
// userProvider.updateProfile() içinde, response'dan sonra:
final oldClaimed = state.value?.completionRewardsClaimed ?? {};
final newClaimed = updatedUser.completionRewardsClaimed;

// Yeni kazanılan milestone'ları bul
final newMilestones = <int>[];
for (final m in [25, 50, 75, 100]) {
  if (newClaimed[m.toString()] == true && oldClaimed[m.toString()] != true) {
    newMilestones.add(m);
  }
}

// Return olarak newMilestones dön (veya callback ile bildir)
```

**Step 2: Show celebration in edit_profile_screen**

Save başarılı olduktan sonra, yeni milestone varsa bottom sheet göster:

```dart
// _save() metodunda, başarılı save sonrası:
final milestoneRewards = {25: 5, 50: 15, 75: 30, 100: 50};
for (final m in newMilestones) {
  if (context.mounted) {
    showModalBottomSheet(
      context: context,
      builder: (_) => MilestoneCelebrationSheet(
        milestone: m,
        diamondReward: milestoneRewards[m]!,
      ),
    );
    break; // Birden fazla milestone varsa en büyüğünü göster
  }
}
```

**Step 3: Verify**

Run: `flutter analyze`

**Step 4: Commit**

```bash
git add lib/providers/user_provider.dart lib/features/profile/screens/edit_profile_screen.dart
git commit -m "feat: milestone reward detection and celebration sheet integration"
```

---

## Task 14: i18n — Çeviri Anahtarları

**Files:**
- Modify: `lib/core/l10n/` içindeki TR ve EN çeviri dosyaları

**Step 1: Add new translation keys**

```
// Profile sections
first_photo_is_profile: "İlk fotoğrafın profil fotoğrafın olur" / "Your first photo is your profile photo"
introduce_yourself: "Kendini kısaca tanıt" / "Briefly introduce yourself"
help_us_know_you: "Seni tanımamıza yardımcı ol" / "Help us get to know you"
enrich_profile_more_matches: "Profilini zenginleştir, daha fazla eşleşme al" / "Enrich your profile, get more matches"
show_you_right_people: "Sana uygun kişileri görelim" / "Let us show you the right people"
let_others_know_what_you_seek: "Ne aradığını karşı taraf görsün" / "Let others know what you're looking for"
profile_completion: "Profil Tamamlama" / "Profile Completion"

// Relationship goal
relationship_goal: "İlişki Amacı" / "Relationship Goal"
serious_relationship: "Ciddi İlişki" / "Serious Relationship"
friendship: "Arkadaşlık" / "Friendship"
not_sure: "Henüz Bilmiyorum" / "Not Sure Yet"

// Language preference
language_preference: "Dil Tercihi" / "Language Preference"
```

**Step 2: Commit**

```bash
git add lib/core/l10n/
git commit -m "feat: add i18n keys for profile sections, relationship_goal, languages"
```

---

## Task 15: Backend Tests

**Files:**
- Modify: İlgili test dosyaları `server/src/__tests__/` altında

**Step 1: Test profile completion calculation**

- 16 alan üzerinden doğru hesaplandığını test et
- relationship_goal = NOT_SURE olduğunda sayılmadığını test et
- preferred_languages boş olduğunda sayılmadığını test et

**Step 2: Test milestone rewards**

- %25 geçildiğinde 5 elmas verildiğini test et
- Aynı milestone'ın tekrar ödül vermediğini test et
- %100'de boost verildiğini test et

**Step 3: Test validator**

- relationship_goal geçerli/geçersiz değerlerle test et
- preferred_languages min 1, max 7 kuralını test et

**Step 4: Run all tests**

Run: `cd server && npm test`

**Step 5: Commit**

```bash
git add server/src/__tests__/
git commit -m "test: add profile completion, milestone rewards, and validator tests"
```

---

## Task 16: Final Verification & Cleanup

**Step 1: Full analyze**

Run: `flutter analyze`
Run: `cd server && npm test`

**Step 2: Manual test checklist**

- [ ] Gender pref MAN/WOMAN/BOTH doğru kaydediliyor
- [ ] Age range slider doğru çalışıyor
- [ ] Distance slider doğru çalışıyor
- [ ] Relationship goal seçimi kaydediliyor
- [ ] Dil tercihi multi-select çalışıyor, en az 1 dil zorunlu
- [ ] Kartlı tasarım düzgün render ediliyor
- [ ] Progress bar doğru yüzdeyi gösteriyor
- [ ] Motivasyon mesajı doğru milestone'u gösteriyor
- [ ] Milestone ödülü verildiğinde bottom sheet açılıyor
- [ ] %100 tamamlamada boost veriliyor
- [ ] Discover card'da relationship_goal badge görünüyor
- [ ] Profile ekranında yeni chip'ler görünüyor

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: profile preferences & completion incentive system — final cleanup"
```
