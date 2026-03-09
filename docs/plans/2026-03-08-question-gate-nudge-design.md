# Question Gate & Nudge System Design

## Problem
Users without questions appear in discover but can't be matched — wasting time for both sides. No nudges exist to encourage question creation.

## Solution
1. Filter questionless users from discover
2. Add gamified nudges across the app to motivate question creation
3. Celebrate when user becomes discoverable

## Design Decisions
- **Minimum questions:** 2 (existing `AppConstants.minQuestions`)
- **Nudges are permanent** until resolved (not dismissable)
- **Gamification tone:** Progress bars, lock/unlock metaphor, celebration animation

---

## 1. Backend — Discover Filter

**File:** `server/src/services/matching.service.ts` → `discover()`

Add filter after batch question count fetch: exclude candidates with `question_count < 2`. Existing safety checks in swipe (LIKE) and quiz start remain as defense-in-depth.

**File:** `server/src/routes/user.routes.ts` → `/me` response

Add `question_count` field to `/me` response so frontend has this data without extra API calls.

---

## 2. Discover Screen — Blurred Lock Overlay

**File:** `lib/features/discover/screens/discover_screen.dart`

**Condition:** Current user's `question_count < 2`

**Visual:**
- Cards rendered with `BackdropFilter` blur effect
- Overlay with custom lock icon (Qulo SVG style)
- Progress bar: "0/2" or "1/2" questions
- Text: "Sorularini ekle, kesfetmeye basla!" / "Add your questions to start discovering!"
- CTA button → navigates to questions_screen
- Like/reject buttons disabled (onTap: null)

**When questions >= 2:** Blur removed, normal discover experience resumes.

---

## 3. Profile Screen — Banner + Badge

**File:** `lib/features/profile/screens/profile_screen.dart`

### A) Top Banner Card
- Gradient background (theme colors)
- Left: Lock/unlock icon (state-dependent)
- Center: "Add questions to be discovered!" + progress bar (0/2 or 1/2)
- Profile completion hint: "Your profile is 70% ready — just questions missing!"
- Right: "Add" button → questions_screen
- Disappears when questions >= 2

### B) "My Questions" Menu Item
- When questions < 2: Red badge dot + subtitle "2 questions required"
- When questions >= 2: Normal appearance (green check or question count)

---

## 4. Edit Profile Screen — Info Banner

**File:** `lib/features/profile/screens/edit_profile_screen.dart`

- Top info banner: "Editing your profile is great! Don't forget to add at least 2 questions to appear in matches."
- "Go to My Questions" text button
- Hidden when questions >= 2

---

## 5. Bottom Navigation — Badge Dot

**File:** `lib/core/widgets/` (bottom nav component)

- Small red/orange badge dot on Profile tab icon
- Active when questions < 2
- Disappears when questions >= 2

---

## 6. Celebration Moment

**File:** `lib/features/profile/screens/questions_screen.dart`

**Trigger:** When 2nd question is successfully created

- Confetti or check animation (Lottie or simple AnimationController)
- Message: "Congratulations! You're now discoverable!"
- "Start Discovering" button → navigates to discover tab

---

## 7. Data Flow

### Question Count Source
- `/me` endpoint returns `question_count` (new field)
- User provider exposes `hasMinQuestions` computed getter: `questionCount >= 2`
- All nudge widgets read from this single source of truth
- No extra API calls needed

### State Updates
- After question create/delete → refresh user provider's question count
- Nudges reactively appear/disappear via Riverpod watch

---

## 8. i18n Keys

All text in `app_localizations.dart` (TR + EN):

| Key | TR | EN |
|-----|----|----|
| `question_nudge_title` | Kesfedilmek icin sorularini ekle! | Add questions to be discovered! |
| `question_nudge_subtitle` | Profilin %{percent} hazir — sadece sorular eksik! | Your profile is %{percent} ready — just questions missing! |
| `question_nudge_progress` | {count}/2 soru | {count}/2 questions |
| `question_nudge_add_button` | Sorularimi Ekle | Add My Questions |
| `question_nudge_edit_hint` | Profilini duzenlemek harika! Eslesmelerde gorunmek icin en az 2 soru eklemeyi unutma. | Great job editing! Don't forget to add at least 2 questions to appear in matches. |
| `question_nudge_go_questions` | Sorularima Git | Go to My Questions |
| `question_nudge_discover_locked` | Sorularini ekle, kesfetmeye basla! | Add your questions to start discovering! |
| `question_nudge_celebration_title` | Tebrikler! Artik kesfedilebilirsin! | Congratulations! You're now discoverable! |
| `question_nudge_celebration_button` | Kesfetmeye Basla | Start Discovering |
| `question_nudge_menu_required` | 2 soru gerekli | 2 questions required |

---

## 9. Files to Modify

### Backend
- `server/src/services/matching.service.ts` — discover filter
- `server/src/services/user.service.ts` — add question_count to /me

### Frontend
- `lib/features/discover/screens/discover_screen.dart` — blur overlay
- `lib/features/profile/screens/profile_screen.dart` — banner + badge
- `lib/features/profile/screens/edit_profile_screen.dart` — info banner
- `lib/features/profile/screens/questions_screen.dart` — celebration
- `lib/core/widgets/` — bottom nav badge
- `lib/providers/user_provider.dart` — hasMinQuestions getter
- `lib/data/models/user_model.dart` — question_count field
- `lib/core/l10n/app_localizations.dart` — i18n keys
- `assets/icons/` — lock, unlock, question-gate SVG icons
