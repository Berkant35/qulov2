# Language-Based Question Filter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Quiz'de cozucunun sadece tercih ettigi dillerdeki sorulari gormesi ve discover'da dil bazli 2+ soru esiginin uygulanmasi.

**Architecture:** Server-side degisiklik: quiz.service.ts'de `orderByLanguagePreference` → `filterByLanguagePreference`, filtrelenmis soru ID'leri session'a kaydedilir. matching.service.ts'de discover ve swipe filtreleri guclendirilir. Flutter'da `strict_language_mode` UI toggle'i kaldirilir.

**Tech Stack:** Node.js + Express + TypeScript (qulo-server), Supabase PostgreSQL, Flutter (minimal)

**Spec:** `docs/superpowers/specs/2026-03-22-language-based-question-filter-design.md`

---

## File Structure

### Server — Modified Files
- `qulo-server/src/services/quiz.service.ts` — filter logic + session'a question_ids kaydetme
- `qulo-server/src/services/matching.service.ts` — discover + swipe dil filtresi
- `qulo-server/migrations/022_quiz_session_question_ids.sql` — yeni migration

### Flutter — Modified Files
- `qulov2/lib/features/profile/widgets/edit_profile_preferences_section.dart` — strict_language_mode toggle kaldirilir
- `qulov2/lib/features/profile/mixins/edit_profile_screen_mixin.dart` — strict_language_mode save kaldirilir

---

## Task 1: Migration — quiz_sessions'a question_ids kolonu

**Files:**
- Create: `qulo-server/migrations/022_quiz_session_question_ids.sql`

- [ ] **Step 1:** Migration dosyasini olustur

```sql
-- Add question_ids column to quiz_sessions
-- Stores the filtered+ordered question IDs at session creation time
-- This prevents race conditions when questions change during a quiz
ALTER TABLE quiz_sessions ADD COLUMN IF NOT EXISTS question_ids JSONB DEFAULT NULL;

-- Backfill: existing sessions don't need this — they'll complete with old logic
-- New sessions will always have question_ids set
```

- [ ] **Step 2:** Migration'i Supabase SQL Editor'de calistir

Supabase MCP tool ile calistir:
```
Project ref: vtntrtozgoyhjdvvurkj
SQL: ALTER TABLE quiz_sessions ADD COLUMN IF NOT EXISTS question_ids JSONB DEFAULT NULL;
```

- [ ] **Step 3:** Commit

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git add migrations/022_quiz_session_question_ids.sql
git commit -m "feat(quiz): add question_ids column to quiz_sessions"
```

---

## Task 2: quiz.service.ts — Filter + Session'a ID Kaydetme

**Files:**
- Modify: `qulo-server/src/services/quiz.service.ts`

- [ ] **Step 1:** `QuestionRow` interface'ine `locale` ekle (satir 22-35)

```typescript
interface QuestionRow {
  id: string;
  user_id: string;
  order_num: number;
  question_text: string;
  correct_answer: number;
  answer_1: string;
  answer_2: string;
  answer_3: string;
  answer_4: string;
  hint_text: string | null;
  stats_correct: number;
  stats_wrong: number;
  locale?: string;  // ← YENi
}
```

- [ ] **Step 2:** `SessionRow` interface'ine `question_ids` ekle (satir 11-20)

```typescript
interface SessionRow {
  id: string;
  solver_id: string;
  target_id: string;
  status: string;
  current_q: number;
  total_questions: number;
  expires_at: string;
  completed_at: string | null;
  question_ids: string[] | null;  // ← YENi
}
```

- [ ] **Step 3:** `orderByLanguagePreference` → `filterByLanguagePreference` degistir (satir 44-53)

Mevcut:
```typescript
  private orderByLanguagePreference(questions: any[], solverLanguages: string[]) {
    if (!solverLanguages.length) return questions;
    const preferred = questions.filter((q: any) => solverLanguages.includes(q.locale || 'tr'));
    const others = questions.filter((q: any) => !solverLanguages.includes(q.locale || 'tr'));
    return [...preferred, ...others];
  }
```

Yeni:
```typescript
  /**
   * Filter questions to only those matching solver's preferred languages.
   * If solverLanguages is empty, returns all questions (no filtering).
   */
  private filterByLanguagePreference(questions: any[], solverLanguages: string[]): any[] {
    if (!solverLanguages.length) return questions;
    const filtered = questions.filter((q: any) => solverLanguages.includes(q.locale || 'tr'));
    return filtered;
  }
```

- [ ] **Step 4:** Dil tercihi cozumleme helper'i ekle (yeni private metod)

```typescript
  /**
   * Resolve solver's language preferences with fallback chain:
   * 1. user.preferred_languages (explicit user setting)
   * 2. userLanguageService.getUserLanguages() (user_languages table)
   * 3. empty array (no filtering)
   */
  private async resolveSolverLanguages(solverId: string): Promise<string[]> {
    // Check preferred_languages first
    const { data: userData } = await supabase
      .from('users')
      .select('preferred_languages')
      .eq('id', solverId)
      .single();

    const prefLangs = userData?.preferred_languages as string[] | null;
    if (prefLangs && prefLangs.length > 0) return prefLangs;

    // Fallback to user_languages table
    return userLanguageService.getUserLanguages(solverId);
  }
```

- [ ] **Step 5:** `startSession` metodunu guncelle (satir 56-128)

Degisiklikler:
1. `userLanguageService.getUserLanguages` yerine `this.resolveSolverLanguages` kullan
2. `orderByLanguagePreference` yerine `filterByLanguagePreference` kullan
3. Session insert'e `question_ids` ekle

Mevcut satir 67-69:
```typescript
    const solverLanguages = await userLanguageService.getUserLanguages(solverId);
    const filteredQuestions = this.orderByLanguagePreference(allQuestions, solverLanguages);
```

Yeni:
```typescript
    const solverLanguages = await this.resolveSolverLanguages(solverId);
    const filteredQuestions = this.filterByLanguagePreference(allQuestions, solverLanguages);
```

Mevcut satir 112-123 (session insert):
```typescript
    const { data: session, error: createErr } = await supabase
      .from("quiz_sessions")
      .insert({
        solver_id: solverId,
        target_id: targetId,
        status: "IN_PROGRESS",
        current_q: 1,
        total_questions: totalQuestions,
        expires_at: expiresAt,
      })
```

Yeni:
```typescript
    const questionIds = filteredQuestions.map((q: any) => q.id as string);

    const { data: session, error: createErr } = await supabase
      .from("quiz_sessions")
      .insert({
        solver_id: solverId,
        target_id: targetId,
        status: "IN_PROGRESS",
        current_q: 1,
        total_questions: totalQuestions,
        expires_at: expiresAt,
        question_ids: questionIds,
      })
```

- [ ] **Step 6:** `getCurrentQuestion` metodunu guncelle (satir 130-172)

Session'dan `question_ids` al, re-filter YAPMA. Mevcut sorgu + ordering yerine kaydedilmis ID'lerden soru cek.

Mevcut satir 131-151'i degistir:

```typescript
  async getCurrentQuestion(sessionId: string, solverId: string) {
    const session = await this.getActiveSession(sessionId, solverId);

    const questionIndex = session.current_q - 1;

    // Use stored question_ids if available (new sessions), fallback to old logic
    let questionId: string;
    if (session.question_ids && session.question_ids.length > 0) {
      if (questionIndex >= session.question_ids.length) throw Errors.SERVER_ERROR();
      questionId = session.question_ids[questionIndex];
    } else {
      // Legacy: re-fetch and order (for sessions created before migration)
      const { data: allQ } = await supabase
        .from("questions")
        .select("id, locale")
        .eq("user_id", session.target_id)
        .order("order_num", { ascending: true });

      const solverLanguages = await this.resolveSolverLanguages(solverId);
      const ordered = this.filterByLanguagePreference(allQ || [], solverLanguages);
      if (questionIndex >= ordered.length) throw Errors.SERVER_ERROR();
      questionId = ordered[questionIndex].id as string;
    }

    // Fetch full question data by ID
    const { data: q, error: qErr } = await supabase
      .from("questions")
      .select("id, order_num, question_text, answer_1, answer_2, answer_3, answer_4, hint_text, time_limit, locale")
      .eq("id", questionId)
      .single();

    if (qErr || !q) throw Errors.SERVER_ERROR();

    // Build answers and shuffle
    const answers = [
      { index: 1, text: q.answer_1 as string },
      { index: 2, text: q.answer_2 as string },
      { index: 3, text: q.answer_3 as string },
      { index: 4, text: q.answer_4 as string },
    ];
    const shuffledAnswers = shuffleArray(answers);

    return {
      session_id: sessionId,
      question_number: session.current_q,
      total_questions: session.total_questions,
      question_id: q.id as string,
      question_text: q.question_text as string,
      answers: shuffledAnswers,
      has_hint: q.hint_text != null && (q.hint_text as string).length > 0,
      time_limit_seconds: (q as any).time_limit ?? 30,
    };
  }
```

- [ ] **Step 7:** `answerQuestion` metodunu ayni sekilde guncelle (satir 175+)

Mevcut satir 182-198'i degistir — session'dan `question_ids` al:

```typescript
    const session = await this.getActiveSession(sessionId, solverId);
    const questionIndex = session.current_q - 1;

    // Use stored question_ids if available, fallback to legacy
    let currentQuestion: QuestionRow;
    if (session.question_ids && session.question_ids.length > 0) {
      if (questionIndex >= session.question_ids.length) throw Errors.SERVER_ERROR();
      const qId = session.question_ids[questionIndex];
      const { data: qData, error: qErr } = await supabase
        .from("questions")
        .select("id, order_num, question_text, correct_answer, answer_1, answer_2, answer_3, answer_4, hint_text, stats_correct, stats_wrong, locale")
        .eq("id", qId)
        .single();
      if (qErr || !qData) throw Errors.SERVER_ERROR();
      currentQuestion = qData as unknown as QuestionRow;
    } else {
      // Legacy fallback
      const { data: allQuestions, error: qErr } = await supabase
        .from("questions")
        .select("id, order_num, question_text, correct_answer, answer_1, answer_2, answer_3, answer_4, hint_text, stats_correct, stats_wrong, locale")
        .eq("user_id", session.target_id)
        .order("order_num", { ascending: true });
      if (qErr || !allQuestions || allQuestions.length === 0) throw Errors.SERVER_ERROR();
      const solverLanguages = await this.resolveSolverLanguages(solverId);
      const questions = this.filterByLanguagePreference(allQuestions, solverLanguages);
      currentQuestion = questions[questionIndex] as unknown as QuestionRow;
    }
```

Geri kalan answer logic'i (power handling, stats update, session advance) ayni kalir — sadece `currentQuestion` referansi degisti.

- [ ] **Step 8:** `getActiveSession` sorgusuna `question_ids` ekle

Mevcut `getActiveSession` metodu `question_ids`'i select etmiyordur. Bul ve select listesine ekle:

```typescript
    .select("id, solver_id, target_id, status, current_q, total_questions, expires_at, completed_at, question_ids")
```

- [ ] **Step 9:** TypeScript derle ve test et

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npx tsc --noEmit
```

- [ ] **Step 10:** Commit

```bash
git add src/services/quiz.service.ts
git commit -m "feat(quiz): filter questions by solver language + store question_ids in session"
```

---

## Task 3: matching.service.ts — Discover + Swipe Dil Filtresi

**Files:**
- Modify: `qulo-server/src/services/matching.service.ts`

- [ ] **Step 1:** Discover language filter'i guncelle (satir 248-263)

Mevcut fallback mantigi kaldirilir. `strict_language_mode` kontrolu kaldirilir.

Mevcut satir 248-263:
```typescript
        const preferredCandidates = discoverableFiltered.filter((c) => {
          const qLocales = questionLocalesByUser.get(c.id) || [];
          const matchingCount = qLocales.filter((l: string) => langPrefs.includes(l)).length;
          return matchingCount >= 2;
        });
        const fallbackCandidates = discoverableFiltered.filter((c) => {
          const qLocales = questionLocalesByUser.get(c.id) || [];
          const matchingCount = qLocales.filter((l: string) => langPrefs.includes(l)).length;
          return matchingCount < 2;
        });

        const isStrictMode = (user as any).strict_language_mode === true;
        discoverableFiltered = isStrictMode
          ? preferredCandidates
          : [...preferredCandidates, ...fallbackCandidates];
```

Yeni:
```typescript
        // Language-based filtering: candidate MUST have 2+ questions in user's languages
        // No fallback — this is always strict now
        discoverableFiltered = discoverableFiltered.filter((c) => {
          const qLocales = questionLocalesByUser.get(c.id) || [];
          const matchingCount = qLocales.filter((l: string) => langPrefs.includes(l)).length;
          return matchingCount >= 2;
        });
```

- [ ] **Step 2:** Swipe LIKE language filter'i guncelle (satir 351-382)

Mevcut `strict_language_mode` kontrolu kaldirilir, her zaman dil bazli filtreleme yapilir.

Mevcut satir 352-382:
```typescript
    if (action === "LIKE") {
      const { data: targetQuestions, error: qError } = await supabase
        .from("questions")
        .select("id, locale")
        .eq("user_id", targetId);

      if (qError) throw Errors.SERVER_ERROR();

      const { data: swiperUser } = await supabase
        .from("users")
        .select("strict_language_mode")
        .eq("id", swiperId)
        .single();

      const isStrictMode = swiperUser?.strict_language_mode === true;

      let compatibleCount = targetQuestions?.length ?? 0;
      if (isStrictMode) {
        const swiperLanguages = await userLanguageService.getUserLanguages(swiperId);
        if (swiperLanguages.length > 0 && targetQuestions) {
          compatibleCount = targetQuestions.filter(
            (q: any) => swiperLanguages.includes(q.locale || 'tr')
          ).length;
        }
      }

      if (compatibleCount < 2) throw Errors.NO_QUESTIONS();
    }
```

Yeni:
```typescript
    if (action === "LIKE") {
      const { data: targetQuestions, error: qError } = await supabase
        .from("questions")
        .select("id, locale")
        .eq("user_id", targetId);

      if (qError) throw Errors.SERVER_ERROR();

      // Always filter by swiper's language preferences
      const swiperLanguages = await userLanguageService.getUserLanguages(swiperId);
      let compatibleCount = targetQuestions?.length ?? 0;

      if (swiperLanguages.length > 0 && targetQuestions) {
        compatibleCount = targetQuestions.filter(
          (q: any) => swiperLanguages.includes(q.locale || 'tr')
        ).length;
      }

      if (compatibleCount < 2) throw Errors.NO_QUESTIONS();
    }
```

- [ ] **Step 3:** TypeScript derle

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npx tsc --noEmit
```

- [ ] **Step 4:** Commit

```bash
git add src/services/matching.service.ts
git commit -m "feat(matching): enforce language-based 2+ question filter in discover and swipe"
```

---

## Task 4: Flutter — strict_language_mode UI Toggle Kaldirma

**Files:**
- Modify: `qulov2/lib/features/profile/widgets/edit_profile_preferences_section.dart`
- Modify: `qulov2/lib/features/profile/mixins/edit_profile_screen_mixin.dart`

- [ ] **Step 1:** `edit_profile_preferences_section.dart`'tan `strict_language_mode` toggle'ini kaldir

Dosyayi oku, `strict_language_mode` veya `strictLanguageMode` referanslarini bul ve UI toggle'ini kaldir. Widget'in geri kalani (dil secimi, mesafe slider, yas araligi) aynen kalir.

- [ ] **Step 2:** `edit_profile_screen_mixin.dart`'taki save() metodundan `strict_language_mode` kaldir

Mevcut save() icindeki `profileData` map'inden `strict_language_mode` key'ini cikar:

```dart
    final profileData = <String, dynamic>{
      'bio': bioController.text.trim(),
      'city': cityController.text.trim(),
      'gender_pref': epState.selectedGenderPref,
      'age_pref_min': epState.ageRange.start.round(),
      'age_pref_max': epState.ageRange.end.round(),
      'match_radius_km': epState.distanceKm.round(),
      'relationship_goal': epState.selectedRelationshipGoal,
      'preferred_languages': epState.selectedLanguages,
      // 'strict_language_mode': epState.strictLanguageMode,  ← KALDIRILDI
    };
```

- [ ] **Step 3:** `EditProfileState`'den `strictLanguageMode` field'ini kaldir (editProfileProvider'da)

`lib/providers/edit_profile_provider.dart`'ta `strictLanguageMode` field'ini ve ilgili init/update logic'ini kaldir.

- [ ] **Step 4:** `dart analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart analyze lib/features/profile/ lib/providers/edit_profile_provider.dart
```

- [ ] **Step 5:** Commit

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/features/profile/ lib/providers/edit_profile_provider.dart
git commit -m "feat(profile): remove strict_language_mode toggle — language filtering is now always strict"
```

---

## Task 5: Server Deploy + Final Verification

- [ ] **Step 1:** Server TypeScript derle

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npx tsc --noEmit
```

- [ ] **Step 2:** Flutter analyze

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart analyze lib/
```

- [ ] **Step 3:** Commit gecmisini dogrula

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && git log --oneline -5
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && git log --oneline -5
```

- [ ] **Step 4:** Manuel test plani

1. **Test kullanicisi A:** 2 TR + 2 ES soru hazirla
2. **Test kullanicisi B:** TR tercih et → A'yi discover'da gor → quiz baslat → sadece 2 TR soru gelir
3. **Test kullanicisi C:** ES tercih et → A'yi discover'da gor → quiz baslat → sadece 2 ES soru gelir
4. **Test kullanicisi D:** FR tercih et → A discover'da cikmaz
5. **Test kullanicisi E:** Dil tercihi bos → A'yi gor → tum 4 soru gelir
6. **Swipe test:** FR tercih eden kullanici A'yi LIKE edemez (2+ FR soru yok)
