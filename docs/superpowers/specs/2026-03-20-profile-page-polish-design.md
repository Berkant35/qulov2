# Profile Page Polish — Design Spec

**Date:** 2026-03-20
**Branch:** APP-1915
**Scope:** Profile screen UI improvements — l10n fixes, celebration popup bug, layout modernization

---

## Problem

1. **Missing l10n keys**: `about_me`, `details`, `preferences` keys have no translation entries. Fallback shows raw keys on screen (e.g. "about_me" instead of "Hakkımda").
2. **Celebration popup bug**: `_showCelebrationDialog()` in `questions_screen.dart` fires every time the user navigates to the questions page if they have >= `minQuestions`. Should only show once.
3. **Cramped layout below photos**: All profile sections stack with minimal spacing, no visual grouping. Feels like a flat list rather than organized sections.

---

## Solution

### Fix 1: Add Missing L10n Keys

Add to `app_localizations.dart`:

| Key | Turkish | English |
|-----|---------|---------|
| `about_me` | Hakkımda | About Me |
| `details` | Detaylar | Details |
| `preferences` | Tercihler | Preferences |

### Fix 2: Celebration Popup — Show Once via SharedPreferences

- On `_showCelebrationDialog()`, first check `SharedPreferences` for `celebration_shown` flag.
- If flag is `true`, skip the dialog.
- After showing the dialog, set `celebration_shown = true`.
- This ensures it only shows once per device, regardless of re-navigation.

**File:** `lib/features/profile/screens/questions_screen.dart` (lines ~130-168)

### Fix 3: Layout Modernization — Spacing + Visual Grouping

Reorganize `profile_screen.dart` body with grouped containers and increased spacing.

**New layout flow:**

```
PhotoGridFull
  ↓ 24px (was 16px)
VitrinCard / GateBanner
  ↓ 24px (was 16px)
┌─ Identity Group (Container: surfaceElevated, radiusLg, cardPadding) ─┐
│  Name, Age (headlineSmall, bold)                                      │
│  SubscriptionBadge (conditional, 8px top)                             │
│  City + MapPin (conditional, 8px top)                                 │
└───────────────────────────────────────────────────────────────────────┘
  ↓ 16px
ReferralInviteCard (compact)
  ↓ 16px
┌─ Progress Group (Container: surfaceElevated, radiusLg, cardPadding) ─┐
│  ProfileCompletionBar                                                 │
│  Divider (12px vertical padding, subtle)                              │
│  BadgeBar                                                             │
└───────────────────────────────────────────────────────────────────────┘
  ↓ 16px
PowerInventoryGrid (already wrapped in SectionCard)
  ↓ 24px
AboutMe SectionCard
  ↓ 12px
Details SectionCard
  ↓ 12px
Preferences SectionCard
  ↓ 24px
Menu Items (Edit Profile, My Questions, Diamonds, Subscription, Passport)
```

**Container style:**
- Background: `AppColors.surfaceElevated` (`#242424`)
- Border radius: `AppSpacing.radiusLg` (16px)
- Padding: `AppSpacing.cardPadding` (12px)
- No border (clean, dark theme aesthetic)

**Spacing changes:**
- Major section gaps: 24px (up from 12-16px)
- Inner group gaps: 8px
- Menu items section separated by 24px from cards

---

## Files to Modify

1. `lib/core/l10n/app_localizations.dart` — add 3 missing keys
2. `lib/features/profile/screens/questions_screen.dart` — SharedPreferences celebration flag
3. `lib/features/profile/screens/profile_screen.dart` — layout restructure with grouping containers

## Files NOT Modified

- No new widget files needed (grouping done inline with Container)
- No theme changes (using existing colors/spacing)
- No backend changes

---

## Testing

- Verify profile screen shows "Hakkımda", "Detaylar", "Tercihler" (TR) / "About Me", "Details", "Preferences" (EN)
- Navigate to questions page with existing questions → no celebration popup
- Delete SharedPreferences → add questions to threshold → celebration popup shows once
- Visual check: profile sections have clear breathing room, identity and progress sections feel grouped
