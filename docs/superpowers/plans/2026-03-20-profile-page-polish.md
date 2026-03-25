# Profile Page Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix missing l10n keys showing raw underscore text, prevent celebration popup from re-firing, and modernize profile layout with visual grouping.

**Architecture:** Three independent fixes in three files. L10n keys added to existing map. SharedPreferences flag guards popup. Profile screen layout restructured with Container-based grouping and increased spacing.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, AppLocalizations

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/core/l10n/app_localizations.dart` | Add 3 missing translation keys (TR + EN) |
| Modify | `lib/features/profile/screens/questions_screen.dart` | Guard celebration dialog with SharedPreferences |
| Modify | `lib/features/profile/screens/profile_screen.dart` | Restructure layout with grouping containers + spacing |

---

### Task 1: Add Missing L10n Keys

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart:747,1470`

- [ ] **Step 1: Add Turkish keys**

In the `_tr` map, before the closing `};` (line 747), add:

```dart
    // Profile section headers
    'about_me': 'Hakkımda',
    'details': 'Detaylar',
    'preferences': 'Tercihler',
```

- [ ] **Step 2: Add English keys**

In the `_en` map, before the closing `};` (line 1470), add:

```dart
    // Profile section headers
    'about_me': 'About Me',
    'details': 'Details',
    'preferences': 'Preferences',
```

- [ ] **Step 3: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/core/l10n/app_localizations.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "fix: add missing l10n keys for profile section headers (about_me, details, preferences)"
```

---

### Task 2: Guard Celebration Popup with SharedPreferences

**Files:**
- Modify: `lib/features/profile/screens/questions_screen.dart:1-168`

- [ ] **Step 1: Add SharedPreferences import**

Add at top of file:

```dart
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Step 2: Add prefs key constant and update _checkCelebration**

Add a constant inside `_QuestionsScreenState`:

```dart
static const _keyCelebrationShown = 'celebration_shown';
```

Replace the `_checkCelebration` method (lines 46-55) with:

```dart
  void _checkCelebration(List<QuestionModel> questions) async {
    final count = questions.length;
    if (_initialized &&
        _previousCount < AppConstants.minQuestions &&
        count >= AppConstants.minQuestions) {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_keyCelebrationShown) ?? false)) {
        await prefs.setBool(_keyCelebrationShown, true);
        if (mounted) _showCelebrationDialog();
      }
    }
    _previousCount = count;
    _initialized = true;
  }
```

- [ ] **Step 3: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/profile/screens/questions_screen.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/screens/questions_screen.dart
git commit -m "fix: show celebration dialog only once via SharedPreferences flag"
```

---

### Task 3: Modernize Profile Layout with Visual Grouping

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart:140-361`

- [ ] **Step 1: Replace the Column children inside SingleChildScrollView**

Replace the entire `children: [...]` list (lines 143-361) with the new grouped layout:

```dart
                children: [
                  // ─── Photo Grid ───
                  PhotoGridFull(
                    photos: photos.map<String?>((e) => e).toList(),
                    onSlotTap: (_) => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ─── Question Gate Banner / Vitrin ───
                  if (user.questionCount < AppConstants.minQuestions) ...[
                    QuestionGateBanner(
                      questionCount: user.questionCount,
                      profileCompletion: user.profileCompletion,
                      onAddQuestions: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ] else ...[
                    const QuestionVitrinCard(),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ─── Identity Group ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${user.name ?? ''}, ${user.age ?? ''}',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        // Subscription Badge
                        Builder(builder: (context) {
                          final subAsync = ref.watch(subscriptionProvider);
                          final sub = subAsync.valueOrNull;
                          if (sub == null || sub.isFree) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.purpleGradient,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              ),
                              child: Text(
                                sub.isPremium ? 'Premium' : 'Plus',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                        // City
                        if (user.city != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                QIcon(QIcons.icMapPin, color: theme.colorScheme.onSurfaceVariant, size: 16),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  user.city!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ─── Referral Invite (Compact) ───
                  ReferralInviteCard(
                    compact: true,
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.diamonds),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ─── Progress Group ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Column(
                      children: [
                        ProfileCompletionBar(
                          completionPercent: user.profileCompletion,
                          onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Divider(
                            color: theme.dividerColor.withValues(alpha: 0.3),
                            height: 1,
                          ),
                        ),
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
                              failure: (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(context.tr('badge_claim_failed'))),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ─── Power Inventory ───
                  const PowerInventoryGrid(),
                  const SizedBox(height: AppSpacing.xl),

                  // ─── About Me Card ───
                  SectionCard(
                    title: context.tr('about_me'),
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                    child: Text(
                      user.bio != null && user.bio!.isNotEmpty
                          ? user.bio!
                          : context.tr('hint_add_bio'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: user.bio != null && user.bio!.isNotEmpty
                            ? null
                            : theme.hintColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ─── Details Card ───
                  SectionCard(
                    title: context.tr('details'),
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                    child: DetailChips(
                      user: user,
                      isOwnProfile: true,
                      onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ─── Preferences Card ───
                  SectionCard(
                    title: context.tr('preferences'),
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (user.genderPref != null)
                          PrefChip(
                            iconPath: QIcons.icGenderPref,
                            label: _genderPrefLabel(context, user.genderPref),
                          ),
                        if (user.agePrefMin != null && user.agePrefMax != null)
                          PrefChip(
                            iconPath: QIcons.icAgeRange,
                            label: '${user.agePrefMin} - ${user.agePrefMax}',
                          ),
                        PrefChip(
                            iconPath: QIcons.icMapPin,
                            label: '${user.matchRadiusKm} km',
                          ),
                        if (user.relationshipGoal != null && user.relationshipGoal != 'NOT_SURE')
                          PrefChip(
                            iconPath: QIcons.icHeart,
                            label: _relationshipGoalLabel(context, user.relationshipGoal),
                          ),
                        if (user.preferredLanguages.isNotEmpty)
                          PrefChip(
                            iconPath: QIcons.icGlobe,
                            label: user.preferredLanguages.map(_languageFlag).join(', '),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ─── Menu Items ───
                  ProfileMenuItem(
                    iconPath: QIcons.icPencil,
                    title: context.tr('edit_profile'),
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                  ),
                  ProfileMenuItem(
                    iconPath: QIcons.icHelpCircle,
                    title: context.tr('my_questions'),
                    subtitle: user.questionCount < AppConstants.minQuestions
                        ? context.tr('question_nudge_menu_required')
                        : null,
                    showBadge: user.questionCount < AppConstants.minQuestions,
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                  ),
                  ProfileMenuItem(
                    iconWidget: const DiamondIcon.purple(size: 24),
                    title: context.tr('diamonds'),
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.diamonds),
                  ),
                  ProfileMenuItem(
                    iconPath: QIcons.icCrown,
                    title: context.tr('sub_my_subscription'),
                    subtitle: (() {
                      final sub = ref.watch(subscriptionProvider).valueOrNull;
                      if (sub == null || sub.isFree) return context.tr('sub_free_upgrade');
                      final planLabel = sub.isPremium ? 'Premium' : 'Plus';
                      if (sub.expiresAt != null) {
                        final date = DateTime.tryParse(sub.expiresAt!);
                        if (date != null) {
                          final formatted = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                          return '$planLabel • $formatted';
                        }
                      }
                      return planLabel;
                    })(),
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.subscription),
                  ),
                  ProfileMenuItem(
                    iconPath: QIcons.icPlane,
                    title: context.tr('passport'),
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.passport),
                  ),
                ],
```

- [ ] **Step 2: Verify**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/profile/screens/profile_screen.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/screens/profile_screen.dart
git commit -m "feat: modernize profile layout with visual grouping and improved spacing"
```

---

### Task 4: Final Verification

- [ ] **Step 1: Run full analyze**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: No issues found

- [ ] **Step 2: Visual smoke test notes**

Check on device/emulator:
- Profile section headers show "Hakkımda", "Detaylar", "Tercihler" (not raw keys)
- Identity group (name + badge + city) appears in rounded container
- Progress group (completion + badge bar) appears in rounded container
- Clear breathing room between major sections
- Questions screen: no celebration popup if already past threshold
