# Question System Overhaul — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Soru sistemini tam ekran wizard + AI destekli easy mode + gamified analytics + kuyruk sistemi + onboarding + app geneli entegrasyona dönüştürmek.

**Architecture:** Mevcut question/quiz backend servislerini genişlet (yeni kolonlar + tablolar), Gemini API proxy endpoint'i ekle, Flutter'da tam ekran soru oluşturma deneyimi (wizard + easy mode), gamified analytics dashboard, ve app genelinde soru entegrasyonu (discover kartı, profil vitrini, chat quiz özeti, haftalık bildirim).

**Tech Stack:** Node.js/Express (backend), Flutter/Riverpod (mobile), Supabase PostgreSQL (DB), Google Gemini API (AI öneriler), FCM (bildirimler)

**Design Doc:** `docs/plans/2026-03-08-question-system-overhaul-design.md`

---

## Phase 1: DB Migration (010)

### Task 1: Migration — questions tablosu yeni kolonlar + yeni tablolar

**Files:**
- Create: `supabase/migrations/010_question_system_overhaul.sql`

**Step 1: Migration SQL dosyasını yaz**

```sql
-- ============================================
-- Migration 010: Question System Overhaul
-- ============================================

-- 1. questions tablosuna yeni kolonlar
ALTER TABLE questions
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS time_limit INT NOT NULL DEFAULT 30,
  ADD COLUMN IF NOT EXISTS stats_copy_used INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_half_used INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_hint_used INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_time_extend_used INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_skip_used INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_total_time_spent INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_solve_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_green_earned INT NOT NULL DEFAULT 0;

-- time_limit constraint: 15, 30, 60, 90 saniye
ALTER TABLE questions
  ADD CONSTRAINT chk_time_limit CHECK (time_limit IN (15, 30, 60, 90));

-- 2. quiz_answers tablosuna time_spent kolonu
ALTER TABLE quiz_answers
  ADD COLUMN IF NOT EXISTS time_spent INT;

-- 3. question_pending_changes tablosu
CREATE TABLE IF NOT EXISTS question_pending_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  change_type TEXT NOT NULL CHECK (change_type IN ('UPDATE', 'DELETE')),
  payload JSONB,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPLIED', 'CANCELLED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  applied_at TIMESTAMPTZ
);

ALTER TABLE question_pending_changes DISABLE ROW LEVEL SECURITY;

CREATE INDEX idx_pending_changes_user ON question_pending_changes(user_id, status);
CREATE INDEX idx_pending_changes_question ON question_pending_changes(question_id, status);

-- 4. ai_question_suggestions tablosu (cache)
CREATE TABLE IF NOT EXISTS ai_question_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  question_text TEXT NOT NULL,
  answers JSONB NOT NULL,
  correct_answer INT NOT NULL CHECK (correct_answer BETWEEN 1 AND 4),
  hint TEXT,
  locale TEXT NOT NULL DEFAULT 'tr',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE ai_question_suggestions DISABLE ROW LEVEL SECURITY;

CREATE INDEX idx_ai_suggestions_category ON ai_question_suggestions(category, locale);

-- 5. quiz_sessions tablosuna quiz özeti alanları (chat kartı için)
ALTER TABLE quiz_sessions
  ADD COLUMN IF NOT EXISTS total_time_spent INT,
  ADD COLUMN IF NOT EXISTS powers_used JSONB DEFAULT '{}';

-- 6. stats_answer_distribution: hangi şık kaç kez seçildi
ALTER TABLE questions
  ADD COLUMN IF NOT EXISTS stats_answer_1_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_answer_2_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_answer_3_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stats_answer_4_count INT NOT NULL DEFAULT 0;
```

**Step 2: Kullanıcıya migration'ı Supabase SQL Editor'da çalıştırmasını söyle**

**Step 3: Commit**
```bash
git add supabase/migrations/010_question_system_overhaul.sql
git commit -m "feat: add migration 010 — question system overhaul schema"
```

---

## Phase 2: Backend — Question Service Enhancements

### Task 2: Validator güncelle — category + time_limit alanları

**Files:**
- Modify: `server/src/validators/question.validator.ts`

**Step 1: createQuestionSchema'ya yeni alanlar ekle**

```typescript
// Mevcut schema'ya ekle:
export const QUESTION_CATEGORIES = [
  'personality', 'music', 'film', 'sports', 'travel',
  'food', 'technology', 'general', 'other'
] as const;

export const TIME_PRESETS = [15, 30, 60, 90] as const;

export const createQuestionSchema = z.object({
  order_num: z.number().int().min(1).max(6),
  question_text: z.string().min(5).max(500),
  correct_answer: z.number().int().min(1).max(4),
  answer_1: z.string().min(1).max(200),
  answer_2: z.string().min(1).max(200),
  answer_3: z.string().min(1).max(200),
  answer_4: z.string().min(1).max(200),
  hint_text: z.string().max(300).optional(),
  category: z.enum(QUESTION_CATEGORIES).optional(),
  time_limit: z.number().int().refine(v => TIME_PRESETS.includes(v as any), {
    message: 'time_limit must be 15, 30, 60, or 90'
  }).optional().default(30),
});
```

**Step 2: updateQuestionSchema'ya da ekle**

```typescript
export const updateQuestionSchema = z.object({
  question_text: z.string().min(5).max(500).optional(),
  correct_answer: z.number().int().min(1).max(4).optional(),
  answer_1: z.string().min(1).max(200).optional(),
  answer_2: z.string().min(1).max(200).optional(),
  answer_3: z.string().min(1).max(200).optional(),
  answer_4: z.string().min(1).max(200).optional(),
  hint_text: z.string().max(300).optional(),
  category: z.enum(QUESTION_CATEGORIES).optional(),
  time_limit: z.number().int().refine(v => TIME_PRESETS.includes(v as any), {
    message: 'time_limit must be 15, 30, 60, or 90'
  }).optional(),
});
```

**Step 3: Commit**
```bash
git add server/src/validators/question.validator.ts
git commit -m "feat: add category and time_limit to question validators"
```

---

### Task 3: Question service — category + time_limit desteği + analytics endpoint

**Files:**
- Modify: `server/src/services/question.service.ts`

**Step 1: createQuestion'a category ve time_limit ekle**

Mevcut `createQuestion` metodundaki insert objesine ekle:
```typescript
category: input.category ?? null,
time_limit: input.time_limit ?? 30,
```

**Step 2: updateQuestion'a category ve time_limit ekle**

Mevcut update objesine ekle (undefined olmayanları):
```typescript
...(input.category !== undefined && { category: input.category }),
...(input.time_limit !== undefined && { time_limit: input.time_limit }),
```

**Step 3: getQuestionAnalytics metodu ekle**

```typescript
async getQuestionAnalytics(userId: string) {
  const { data: questions, error } = await supabase
    .from('questions')
    .select('*')
    .eq('user_id', userId)
    .order('order_num', { ascending: true });

  if (error) throw Errors.SERVER_ERROR();

  const analytics = (questions ?? []).map(q => {
    const totalAttempts = q.stats_correct + q.stats_wrong;
    const successRate = totalAttempts > 0
      ? Math.round((q.stats_correct / totalAttempts) * 100)
      : 0;
    const avgTime = q.stats_solve_count > 0
      ? Math.round(q.stats_total_time_spent / q.stats_solve_count)
      : 0;

    let difficultyBadge = 'unranked';
    if (totalAttempts >= 10) {
      if (successRate > 70) difficultyBadge = 'easy';
      else if (successRate > 40) difficultyBadge = 'medium';
      else if (successRate > 20) difficultyBadge = 'hard';
      else difficultyBadge = 'legendary';
    }

    return {
      order_num: q.order_num,
      question_text: q.question_text,
      category: q.category,
      time_limit: q.time_limit,
      stats: {
        correct: q.stats_correct,
        wrong: q.stats_wrong,
        total_attempts: totalAttempts,
        success_rate: successRate,
        solve_count: q.stats_solve_count,
        avg_time: avgTime,
        green_earned: q.stats_green_earned,
        answer_distribution: {
          answer_1: q.stats_answer_1_count,
          answer_2: q.stats_answer_2_count,
          answer_3: q.stats_answer_3_count,
          answer_4: q.stats_answer_4_count,
        },
        powers: {
          copy: q.stats_copy_used,
          half: q.stats_half_used,
          hint: q.stats_hint_used,
          time_extend: q.stats_time_extend_used,
          skip: q.stats_skip_used,
        },
      },
      difficulty_badge: difficultyBadge,
    };
  });

  // Toplam istatistikler
  const totals = {
    total_solve_count: analytics.reduce((s, a) => s + a.stats.solve_count, 0),
    total_green_earned: analytics.reduce((s, a) => s + a.stats.green_earned, 0),
    overall_success_rate: (() => {
      const totalCorrect = analytics.reduce((s, a) => s + a.stats.correct, 0);
      const totalAttempts = analytics.reduce((s, a) => s + a.stats.total_attempts, 0);
      return totalAttempts > 0 ? Math.round((totalCorrect / totalAttempts) * 100) : 0;
    })(),
    best_question_order: analytics.reduce((best, a) =>
      a.stats.green_earned > (best?.stats.green_earned ?? 0) ? a : best, analytics[0])?.order_num ?? null,
  };

  return { questions: analytics, totals };
}
```

**Step 4: Commit**
```bash
git add server/src/services/question.service.ts
git commit -m "feat: add category, time_limit support and analytics to question service"
```

---

### Task 4: Question controller + routes — analytics endpoint

**Files:**
- Modify: `server/src/controllers/question.controller.ts`
- Modify: `server/src/routes/question.routes.ts`

**Step 1: Controller'a analytics handler ekle**

```typescript
export async function getQuestionAnalyticsHandler(
  req: Request, res: Response, next: NextFunction
) {
  try {
    const userId = req.user!.userId;
    const data = await questionService.getQuestionAnalytics(userId);
    res.json(data);
  } catch (err) {
    next(err);
  }
}
```

**Step 2: Route ekle**

```typescript
router.get('/me/analytics', getQuestionAnalyticsHandler);
```

**Step 3: Commit**
```bash
git add server/src/controllers/question.controller.ts server/src/routes/question.routes.ts
git commit -m "feat: add question analytics endpoint"
```

---

## Phase 3: Backend — Quiz Enhancements (time_spent + power stats)

### Task 5: Quiz service — soru bazlı time_limit + time_spent + güç istatistikleri

**Files:**
- Modify: `server/src/services/quiz.service.ts`

**Step 1: getCurrentQuestion'da soru bazlı time_limit dön**

Mevcut `getCurrentQuestion` metodunda `time_limit_seconds: 30` sabit değerini değiştir:
```typescript
time_limit_seconds: currentQuestion.time_limit ?? 30,
```

**Step 2: startSession'da expires_at hesaplamasını soru bazlı yap**

Mevcut sabit `totalQuestions * 30` yerine:
```typescript
// Tüm soruları çek, time_limit'leri topla
const { data: questions } = await supabase
  .from('questions')
  .select('time_limit')
  .eq('user_id', targetId)
  .order('order_num', { ascending: true });

const totalTimeLimit = (questions ?? []).reduce(
  (sum, q) => sum + (q.time_limit ?? 30), 0
);
// Buffer olarak +10sn ekle (ağ gecikmesi vb.)
const expiresAt = new Date(Date.now() + (totalTimeLimit + 10) * 1000).toISOString();
```

**Step 3: answerQuestion'da time_spent kaydet + güç istatistiklerini güncelle**

`recordAnswer` metoduna `timeSpent` parametresi ekle:
```typescript
private async recordAnswer(
  sessionId: string, questionId: string,
  selectedAnswer: number, isCorrect: boolean,
  powerUsed: string | null, timeSpent: number | null
) {
  await supabase.from('quiz_answers').insert({
    session_id: sessionId,
    question_id: questionId,
    selected_answer: selectedAnswer,
    is_correct: isCorrect,
    power_used: powerUsed,
    time_spent: timeSpent,
  });
}
```

**Step 4: updateQuestionStats'ı genişlet — güç + süre + cevap dağılımı**

```typescript
private async updateQuestionStats(
  questionId: string, isCorrect: boolean,
  powerUsed: string | null, timeSpent: number | null,
  selectedAnswer: number
) {
  const updates: Record<string, any> = {};

  // Mevcut doğru/yanlış sayacı
  if (isCorrect) {
    updates.stats_correct = supabase.rpc('increment', { row_id: questionId, field: 'stats_correct' });
  } else {
    updates.stats_wrong = supabase.rpc('increment', { row_id: questionId, field: 'stats_wrong' });
  }

  // Basit increment yaklaşımı — mevcut double-read pattern'i kullan
  const { data: question } = await supabase
    .from('questions')
    .select('stats_correct, stats_wrong, stats_solve_count, stats_total_time_spent, stats_copy_used, stats_half_used, stats_hint_used, stats_time_extend_used, stats_skip_used, stats_answer_1_count, stats_answer_2_count, stats_answer_3_count, stats_answer_4_count')
    .eq('id', questionId)
    .single();

  if (!question) return;

  const updatePayload: Record<string, number> = {
    stats_solve_count: question.stats_solve_count + 1,
    [isCorrect ? 'stats_correct' : 'stats_wrong']:
      (isCorrect ? question.stats_correct : question.stats_wrong) + 1,
  };

  // Süre
  if (timeSpent != null) {
    updatePayload.stats_total_time_spent = question.stats_total_time_spent + timeSpent;
  }

  // Güç istatistikleri
  if (powerUsed) {
    const powerStatMap: Record<string, string> = {
      COPY: 'stats_copy_used',
      HALF: 'stats_half_used',
      HINT: 'stats_hint_used',
      TIME_EXTEND: 'stats_time_extend_used',
      SKIP: 'stats_skip_used',
      SKIP_ALL: 'stats_skip_used',
    };
    const field = powerStatMap[powerUsed];
    if (field) {
      updatePayload[field] = (question[field] ?? 0) + 1;
    }
  }

  // Cevap dağılımı
  const answerField = `stats_answer_${selectedAnswer}_count`;
  updatePayload[answerField] = (question[answerField] ?? 0) + 1;

  await supabase
    .from('questions')
    .update(updatePayload)
    .eq('id', questionId);
}
```

**Step 5: answerQuestion'a time_spent parametresi ekle**

Mevcut `answerQuestion` metod imzasını güncelle:
```typescript
async answerQuestion(
  sessionId: string, solverId: string,
  selectedAnswer: number, powerUsed?: string,
  timeSpent?: number  // yeni parametre
)
```

Ve `recordAnswer` + `updateQuestionStats` çağrılarını güncelle.

**Step 6: Quiz session bitiminde özet bilgileri kaydet**

`completeSession` ve `FAILED` durumlarında:
```typescript
// Session tamamlandığında powers_used ve total_time_spent güncelle
const { data: answers } = await supabase
  .from('quiz_answers')
  .select('power_used, time_spent')
  .eq('session_id', sessionId);

const totalTime = (answers ?? []).reduce((s, a) => s + (a.time_spent ?? 0), 0);
const powersUsed: Record<string, number> = {};
for (const a of answers ?? []) {
  if (a.power_used) {
    powersUsed[a.power_used] = (powersUsed[a.power_used] ?? 0) + 1;
  }
}

await supabase.from('quiz_sessions').update({
  total_time_spent: totalTime,
  powers_used: powersUsed,
}).eq('id', sessionId);
```

**Step 7: Commit**
```bash
git add server/src/services/quiz.service.ts
git commit -m "feat: add per-question time_limit, time_spent tracking, and power stats to quiz"
```

---

### Task 6: Quiz validator + controller — time_spent parametresi

**Files:**
- Modify: `server/src/validators/quiz.validator.ts`
- Modify: `server/src/controllers/quiz.controller.ts`

**Step 1: answerQuizSchema'ya time_spent ekle**

```typescript
export const answerQuizSchema = z.object({
  selected_answer: z.number().int().min(1).max(4),
  power_used: z.enum(["COPY", "HALF", "SKIP", "SKIP_ALL", "TIME_EXTEND", "HINT"]).optional(),
  time_spent: z.number().int().min(0).max(120).optional(),
});
```

**Step 2: Controller'da time_spent'i service'e ilet**

```typescript
export async function answerQuestionHandler(req, res, next) {
  try {
    const userId = req.user!.userId;
    const { session_id } = req.params;
    const { selected_answer, power_used, time_spent } = req.body;
    const data = await quizService.answerQuestion(
      session_id, userId, selected_answer, power_used, time_spent
    );
    res.json(data);
  } catch (err) {
    next(err);
  }
}
```

**Step 3: Commit**
```bash
git add server/src/validators/quiz.validator.ts server/src/controllers/quiz.controller.ts
git commit -m "feat: add time_spent to quiz answer endpoint"
```

---

### Task 7: Quiz service — green diamond earned istatistiği soru bazında

**Files:**
- Modify: `server/src/services/quiz.service.ts`

**Step 1: Power kullanıldığında sorunun stats_green_earned'ını güncelle**

Mevcut güç kullanım bloğunda, `diamondService.earnGreen()` çağrısından sonra:
```typescript
// Soru sahibine kazandırılan yeşil elması sorunun istatistiğine yaz
const { data: currentQ } = await supabase
  .from('questions')
  .select('stats_green_earned')
  .eq('id', questionId)
  .single();

if (currentQ) {
  await supabase
    .from('questions')
    .update({ stats_green_earned: currentQ.stats_green_earned + greenReward })
    .eq('id', questionId);
}
```

**Step 2: Commit**
```bash
git add server/src/services/quiz.service.ts
git commit -m "feat: track green diamond earnings per question"
```

---

## Phase 4: Backend — Pending Changes Queue

### Task 8: Pending changes service + controller + routes

**Files:**
- Create: `server/src/services/pending-change.service.ts`
- Create: `server/src/controllers/pending-change.controller.ts`
- Create: `server/src/validators/pending-change.validator.ts`
- Modify: `server/src/routes/question.routes.ts`
- Modify: `server/src/services/question.service.ts`

**Step 1: pending-change.service.ts oluştur**

```typescript
import { supabase } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';

class PendingChangeService {
  async hasActiveQuiz(userId: string): Promise<boolean> {
    const { count } = await supabase
      .from('quiz_sessions')
      .select('id', { count: 'exact', head: true })
      .eq('target_id', userId)
      .eq('status', 'IN_PROGRESS');
    return (count ?? 0) > 0;
  }

  async queueChange(userId: string, orderNum: number, changeType: 'UPDATE' | 'DELETE', payload?: any) {
    // Soru ID'sini bul
    const { data: question } = await supabase
      .from('questions')
      .select('id')
      .eq('user_id', userId)
      .eq('order_num', orderNum)
      .single();

    if (!question) throw Errors.SESSION_NOT_FOUND();

    // Aynı soru için bekleyen değişiklik varsa iptal et
    await supabase
      .from('question_pending_changes')
      .update({ status: 'CANCELLED' })
      .eq('question_id', question.id)
      .eq('status', 'PENDING');

    const { data, error } = await supabase
      .from('question_pending_changes')
      .insert({
        question_id: question.id,
        user_id: userId,
        change_type: changeType,
        payload: changeType === 'UPDATE' ? payload : null,
        status: 'PENDING',
      })
      .select()
      .single();

    if (error) throw Errors.SERVER_ERROR();
    return data;
  }

  async getPendingChanges(userId: string) {
    const { data, error } = await supabase
      .from('question_pending_changes')
      .select('*, questions(order_num, question_text)')
      .eq('user_id', userId)
      .eq('status', 'PENDING')
      .order('created_at', { ascending: false });

    if (error) throw Errors.SERVER_ERROR();
    return data ?? [];
  }

  async cancelPendingChange(userId: string, changeId: string) {
    const { data, error } = await supabase
      .from('question_pending_changes')
      .update({ status: 'CANCELLED' })
      .eq('id', changeId)
      .eq('user_id', userId)
      .eq('status', 'PENDING')
      .select()
      .single();

    if (error || !data) throw Errors.SESSION_NOT_FOUND();
    return data;
  }

  async applyPendingChanges(userId: string) {
    const pending = await this.getPendingChanges(userId);
    if (pending.length === 0) return;

    for (const change of pending) {
      try {
        if (change.change_type === 'DELETE') {
          await supabase
            .from('questions')
            .delete()
            .eq('id', change.question_id);
        } else if (change.change_type === 'UPDATE' && change.payload) {
          await supabase
            .from('questions')
            .update(change.payload)
            .eq('id', change.question_id);
        }

        await supabase
          .from('question_pending_changes')
          .update({ status: 'APPLIED', applied_at: new Date().toISOString() })
          .eq('id', change.id);
      } catch {
        // Soru zaten silinmişse ignore
      }
    }

    // Bildirim gönder
    const { NotificationService } = await import('./notification.service.js');
    await NotificationService.sendPush(userId, 'campaign', {
      body: 'Bekleyen soru değişikliklerin uygulandı.',
    }, undefined, {
      title: 'Qulo',
      actionUrl: '/profile/questions',
    });
  }
}

export const pendingChangeService = new PendingChangeService();
```

**Step 2: Quiz service'de session bitiminde applyPendingChanges çağır**

`quiz.service.ts`'de `completeSession` ve FAILED durumunda:
```typescript
import { pendingChangeService } from './pending-change.service.js';

// Session bittiğinde target'ın bekleyen değişikliklerini uygula
await pendingChangeService.applyPendingChanges(targetId);
```

**Step 3: Question service'de update/delete'i kuyruk ile entegre et**

`question.service.ts`'de `updateQuestion` ve `deleteQuestion` metodlarını güncelle:
```typescript
async updateQuestion(userId: string, orderNum: number, input: UpdateQuestionInput) {
  const hasActive = await pendingChangeService.hasActiveQuiz(userId);
  if (hasActive) {
    return { queued: true, change: await pendingChangeService.queueChange(userId, orderNum, 'UPDATE', input) };
  }
  // ... mevcut güncelleme kodu
  return { queued: false, question: data };
}

async deleteQuestion(userId: string, orderNum: number) {
  const hasActive = await pendingChangeService.hasActiveQuiz(userId);
  if (hasActive) {
    return { queued: true, change: await pendingChangeService.queueChange(userId, orderNum, 'DELETE') };
  }
  // ... mevcut silme kodu
  return { queued: false };
}
```

**Step 4: Controller + validator + route'ları ekle**

```typescript
// pending-change.validator.ts
export const queueChangeSchema = z.object({
  change_type: z.enum(['UPDATE', 'DELETE']),
  payload: z.object({
    question_text: z.string().min(5).max(500).optional(),
    correct_answer: z.number().int().min(1).max(4).optional(),
    answer_1: z.string().min(1).max(200).optional(),
    answer_2: z.string().min(1).max(200).optional(),
    answer_3: z.string().min(1).max(200).optional(),
    answer_4: z.string().min(1).max(200).optional(),
    hint_text: z.string().max(300).optional(),
    category: z.enum(QUESTION_CATEGORIES).optional(),
    time_limit: z.number().int().optional(),
  }).optional(),
});
```

Routes:
```typescript
router.get('/me/pending', getPendingChangesHandler);
router.post('/me/:order/queue-change', validate(queueChangeSchema), queueChangeHandler);
router.delete('/me/pending/:changeId', cancelPendingChangeHandler);
```

**Step 5: Commit**
```bash
git add server/src/services/pending-change.service.ts server/src/controllers/pending-change.controller.ts server/src/validators/pending-change.validator.ts server/src/routes/question.routes.ts server/src/services/question.service.ts server/src/services/quiz.service.ts
git commit -m "feat: add question pending changes queue system"
```

---

## Phase 5: Backend — AI Question Suggestions (Gemini)

### Task 9: Gemini AI suggest service + endpoint

**Files:**
- Create: `server/src/services/ai-suggest.service.ts`
- Create: `server/src/controllers/ai-suggest.controller.ts`
- Create: `server/src/validators/ai-suggest.validator.ts`
- Modify: `server/src/routes/question.routes.ts`
- Modify: `server/src/config/env.ts`

**Step 1: env.ts'e GEMINI_API_KEY ekle**

```typescript
// envSchema'ya ekle:
GEMINI_API_KEY: z.string().default(''),
```

**Step 2: ai-suggest.service.ts oluştur**

```typescript
import { supabase } from '../config/supabase.js';
import { env } from '../config/env.js';
import { Errors } from '../utils/errors.js';

const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

class AiSuggestService {
  // Kategori bazlı — cache'den döner
  async getCachedSuggestions(category: string, locale: string = 'tr', count: number = 5) {
    const { data, error } = await supabase
      .from('ai_question_suggestions')
      .select('*')
      .eq('category', category)
      .eq('locale', locale)
      .limit(count * 3); // Fazladan çek, rastgele seç

    if (error) throw Errors.SERVER_ERROR();
    if (!data || data.length === 0) {
      // Cache boşsa gerçek zamanlı üret
      return this.generateFromGemini(category, locale, count);
    }

    // Rastgele count adet seç
    const shuffled = data.sort(() => Math.random() - 0.5);
    return shuffled.slice(0, count).map(s => ({
      question_text: s.question_text,
      answers: s.answers,
      correct_answer: s.correct_answer,
      hint: s.hint,
      category: s.category,
    }));
  }

  // Profil bazlı — gerçek zamanlı Gemini
  async getProfileBasedSuggestions(userId: string, locale: string = 'tr', count: number = 5) {
    if (!env.GEMINI_API_KEY) throw Errors.SERVER_ERROR();

    const { data: user } = await supabase
      .from('users')
      .select('name, age, gender, bio')
      .eq('id', userId)
      .single();

    if (!user) throw Errors.USER_NOT_FOUND();

    const profileContext = [
      user.name ? `İsim: ${user.name}` : '',
      user.age ? `Yaş: ${user.age}` : '',
      user.gender ? `Cinsiyet: ${user.gender}` : '',
      user.bio ? `Bio: ${user.bio}` : '',
    ].filter(Boolean).join(', ');

    return this.callGemini(profileContext, locale, count);
  }

  // Gemini API çağrısı
  private async callGemini(context: string, locale: string, count: number) {
    const lang = locale === 'tr' ? 'Türkçe' : 'English';
    const prompt = `Sen bir dating uygulaması için kişisel soru oluşturucususun.

Kurallar:
- Sorular kişisel olmalı, Google'da aranamaz olmalı
- Her sorunun 4 şıkkı ve 1 doğru cevabı olmalı
- Sorular eğlenceli, flörtöz veya kişilik yansıtıcı olmalı
- ${lang} dilinde yaz
- JSON formatında dön

Profil bilgisi: ${context || 'Genel profil'}

${count} adet soru üret. Her soru için:
{
  "question_text": "soru metni",
  "answers": ["şık1", "şık2", "şık3", "şık4"],
  "correct_answer": 1,
  "hint": "ipucu (opsiyonel)",
  "category": "personality"
}

Sadece JSON array dön, başka bir şey yazma: [...]`;

    const response = await fetch(`${GEMINI_URL}?key=${env.GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.9, maxOutputTokens: 2048 },
      }),
    });

    if (!response.ok) throw Errors.SERVER_ERROR();

    const result = await response.json();
    const text = result.candidates?.[0]?.content?.parts?.[0]?.text ?? '[]';

    try {
      // JSON parse — markdown code block varsa temizle
      const cleaned = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      const suggestions = JSON.parse(cleaned);
      return Array.isArray(suggestions) ? suggestions.slice(0, count) : [];
    } catch {
      return [];
    }
  }

  // Cache'e yeni öneriler ekle (admin/cron için)
  private async generateFromGemini(category: string, locale: string, count: number) {
    const suggestions = await this.callGemini(`Kategori: ${category}`, locale, count);

    // Cache'e kaydet
    for (const s of suggestions) {
      await supabase.from('ai_question_suggestions').insert({
        category,
        question_text: s.question_text,
        answers: s.answers,
        correct_answer: s.correct_answer,
        hint: s.hint ?? null,
        locale,
      });
    }

    return suggestions;
  }

  // Admin: Toplu cache doldur
  async populateCache(category: string, locale: string = 'tr', count: number = 20) {
    return this.callGemini(`Kategori: ${category}`, locale, count).then(async (suggestions) => {
      for (const s of suggestions) {
        await supabase.from('ai_question_suggestions').insert({
          category,
          question_text: s.question_text,
          answers: s.answers,
          correct_answer: s.correct_answer,
          hint: s.hint ?? null,
          locale,
        });
      }
      return { inserted: suggestions.length };
    });
  }
}

export const aiSuggestService = new AiSuggestService();
```

**Step 3: Validator oluştur**

```typescript
// ai-suggest.validator.ts
import { z } from 'zod';
import { QUESTION_CATEGORIES } from './question.validator.js';

export const aiSuggestSchema = z.object({
  category: z.enum(QUESTION_CATEGORIES).optional(),
  profile_based: z.boolean().optional().default(false),
  locale: z.enum(['tr', 'en']).optional().default('tr'),
  count: z.number().int().min(1).max(10).optional().default(5),
});

export type AiSuggestInput = z.infer<typeof aiSuggestSchema>;
```

**Step 4: Controller oluştur**

```typescript
// ai-suggest.controller.ts
import { Request, Response, NextFunction } from 'express';
import { aiSuggestService } from '../services/ai-suggest.service.js';

export async function aiSuggestHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId;
    const { category, profile_based, locale, count } = req.body;

    let suggestions;
    if (profile_based) {
      suggestions = await aiSuggestService.getProfileBasedSuggestions(userId, locale, count);
    } else if (category) {
      suggestions = await aiSuggestService.getCachedSuggestions(category, locale, count);
    } else {
      return res.status(400).json({ error: 'category or profile_based required' });
    }

    res.json({ suggestions });
  } catch (err) {
    next(err);
  }
}
```

**Step 5: Route ekle**

```typescript
// question.routes.ts'e ekle:
import { aiSuggestHandler } from '../controllers/ai-suggest.controller.js';
import { validate } from '../middleware/validate.js';
import { aiSuggestSchema } from '../validators/ai-suggest.validator.js';

router.post('/ai-suggest', validate(aiSuggestSchema), aiSuggestHandler);
```

**Step 6: Commit**
```bash
git add server/src/services/ai-suggest.service.ts server/src/controllers/ai-suggest.controller.ts server/src/validators/ai-suggest.validator.ts server/src/routes/question.routes.ts server/src/config/env.ts
git commit -m "feat: add Gemini AI question suggestion service and endpoint"
```

---

## Phase 6: Backend — Weekly Report + Quiz Summary for Chat

### Task 10: Quiz summary endpoint (chat kartı için)

**Files:**
- Modify: `server/src/services/quiz.service.ts`
- Modify: `server/src/controllers/quiz.controller.ts`
- Modify: `server/src/routes/quiz.routes.ts`

**Step 1: Quiz service'e getMatchQuizSummary metodu ekle**

```typescript
async getMatchQuizSummary(matchId: string, userId: string) {
  // Match'i bul
  const { data: match } = await supabase
    .from('matches')
    .select('id, user1_id, user2_id')
    .eq('id', matchId)
    .single();

  if (!match) throw Errors.SESSION_NOT_FOUND();

  // Bu match'e ait COMPLETED quiz session'ı bul
  const solverId = match.user1_id === userId ? match.user1_id : match.user2_id;
  const targetId = match.user1_id === userId ? match.user2_id : match.user1_id;

  const { data: session } = await supabase
    .from('quiz_sessions')
    .select('id, status, total_time_spent, powers_used, started_at, completed_at, current_q')
    .or(`and(solver_id.eq.${match.user1_id},target_id.eq.${match.user2_id}),and(solver_id.eq.${match.user2_id},target_id.eq.${match.user1_id})`)
    .eq('status', 'COMPLETED')
    .order('completed_at', { ascending: false })
    .limit(1)
    .single();

  if (!session) return null;

  // Cevapları al
  const { data: answers } = await supabase
    .from('quiz_answers')
    .select('is_correct, power_used, time_spent')
    .eq('session_id', session.id);

  const totalCorrect = (answers ?? []).filter(a => a.is_correct).length;
  const totalQuestions = answers?.length ?? 0;
  const totalPowers = (answers ?? []).filter(a => a.power_used).length;

  // Performans rozeti
  let performanceBadge = 'none';
  if (totalCorrect === totalQuestions && totalPowers === 0) {
    performanceBadge = 'flawless';
  } else if (session.total_time_spent && session.total_time_spent < totalQuestions * 15) {
    performanceBadge = 'speed_solver';
  } else if (totalPowers >= 3) {
    performanceBadge = 'power_master';
  } else if (totalCorrect === totalQuestions) {
    performanceBadge = 'determined';
  }

  return {
    session_id: session.id,
    solver_id: session.solver_id ?? solverId,
    total_questions: totalQuestions,
    total_correct: totalCorrect,
    total_time_spent: session.total_time_spent,
    powers_used: session.powers_used,
    total_powers_used: totalPowers,
    performance_badge: performanceBadge,
    completed_at: session.completed_at,
  };
}
```

**Step 2: Controller + Route ekle**

```typescript
// Controller:
export async function getMatchQuizSummaryHandler(req, res, next) {
  try {
    const userId = req.user!.userId;
    const { match_id } = req.params;
    const data = await quizService.getMatchQuizSummary(match_id, userId);
    res.json(data);
  } catch (err) {
    next(err);
  }
}

// Route (quiz.routes.ts'e ekle):
router.get('/match/:match_id/summary', getMatchQuizSummaryHandler);
```

**Step 3: Commit**
```bash
git add server/src/services/quiz.service.ts server/src/controllers/quiz.controller.ts server/src/routes/quiz.routes.ts
git commit -m "feat: add quiz summary endpoint for chat card"
```

---

### Task 11: Haftalık rapor endpoint

**Files:**
- Modify: `server/src/services/question.service.ts`
- Modify: `server/src/controllers/question.controller.ts`
- Modify: `server/src/routes/question.routes.ts`

**Step 1: Question service'e getWeeklyReport ekle**

```typescript
async getWeeklyReport(userId: string) {
  const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

  // Bu hafta çözülen quiz session'lar (target = userId)
  const { data: sessions } = await supabase
    .from('quiz_sessions')
    .select('id')
    .eq('target_id', userId)
    .gte('started_at', weekAgo);

  const sessionIds = (sessions ?? []).map(s => s.id);

  // Bu hafta kazanılan yeşil elmas (diamond_transactions)
  const { data: greenTx } = await supabase
    .from('diamond_transactions')
    .select('amount')
    .eq('user_id', userId)
    .eq('type', 'GREEN')
    .eq('reason', 'POWER_REWARD')
    .gte('created_at', weekAgo);

  const weeklyGreenEarned = (greenTx ?? []).reduce((s, t) => s + t.amount, 0);

  // En zor soru (bu haftaki en düşük doğru oranı)
  const { data: questions } = await supabase
    .from('questions')
    .select('order_num, question_text, stats_correct, stats_wrong')
    .eq('user_id', userId);

  let hardestQuestion = null;
  let lowestRate = 101;
  for (const q of questions ?? []) {
    const total = q.stats_correct + q.stats_wrong;
    if (total >= 5) {
      const rate = (q.stats_correct / total) * 100;
      if (rate < lowestRate) {
        lowestRate = rate;
        hardestQuestion = { order_num: q.order_num, question_text: q.question_text, success_rate: Math.round(rate) };
      }
    }
  }

  return {
    week_start: weekAgo,
    total_solves: sessionIds.length,
    green_earned: weeklyGreenEarned,
    hardest_question: hardestQuestion,
  };
}
```

**Step 2: Controller + Route ekle**

```typescript
// Controller:
export async function getWeeklyReportHandler(req, res, next) {
  try {
    const userId = req.user!.userId;
    const data = await questionService.getWeeklyReport(userId);
    res.json(data);
  } catch (err) {
    next(err);
  }
}

// Route:
router.get('/me/weekly-report', getWeeklyReportHandler);
```

**Step 3: Commit**
```bash
git add server/src/services/question.service.ts server/src/controllers/question.controller.ts server/src/routes/question.routes.ts
git commit -m "feat: add weekly question report endpoint"
```

---

## Phase 7: Backend — Discover kart bilgisi güncelleme

### Task 12: Discover response'a soru bilgileri ekle

**Files:**
- Modify: `server/src/services/matching.service.ts`

**Step 1: Discover response'taki candidate'lara soru bilgisi ekle**

Mevcut matching.service.ts'de discover() metodunda, adaylar döndürülmeden önce her aday için soru bilgisi ekle:

```typescript
// Adayların soru bilgilerini batch olarak çek
const candidateIds = candidates.map(c => c.id);
const { data: questionStats } = await supabase
  .from('questions')
  .select('user_id, category, stats_correct, stats_wrong')
  .in('user_id', candidateIds);

// Kullanıcı bazlı grupla
const questionInfoMap = new Map<string, { count: number, categories: string[], avgDifficulty: string }>();
for (const userId of candidateIds) {
  const userQuestions = (questionStats ?? []).filter(q => q.user_id === userId);
  const totalAttempts = userQuestions.reduce((s, q) => s + q.stats_correct + q.stats_wrong, 0);
  const totalCorrect = userQuestions.reduce((s, q) => s + q.stats_correct, 0);
  const successRate = totalAttempts > 0 ? (totalCorrect / totalAttempts) * 100 : 50;

  let difficulty = 'unranked';
  if (totalAttempts >= 10) {
    if (successRate > 70) difficulty = 'easy';
    else if (successRate > 40) difficulty = 'medium';
    else if (successRate > 20) difficulty = 'hard';
    else difficulty = 'legendary';
  }

  const categories = [...new Set(userQuestions.map(q => q.category).filter(Boolean))];

  questionInfoMap.set(userId, {
    count: userQuestions.length,
    categories: categories as string[],
    avgDifficulty: difficulty,
  });
}

// Candidate response'a ekle
const enrichedCandidates = candidates.map(c => ({
  ...c,
  question_info: questionInfoMap.get(c.id) ?? { count: 0, categories: [], avgDifficulty: 'unranked' },
}));
```

**Step 2: Commit**
```bash
git add server/src/services/matching.service.ts
git commit -m "feat: add question info to discover candidate response"
```

---

## Phase 8: Flutter — Model + Service + Repository Güncellemeleri

### Task 13: QuestionModel güncelle — category, time_limit, yeni stats alanları

**Files:**
- Modify: `lib/data/models/question_model.dart`

**Step 1: Modele yeni alanlar ekle**

```dart
@JsonKey(name: 'category')
final String? category;

@JsonKey(name: 'time_limit', defaultValue: 30)
final int timeLimit;

@JsonKey(name: 'stats_solve_count', defaultValue: 0)
final int statsSolveCount;

@JsonKey(name: 'stats_total_time_spent', defaultValue: 0)
final int statsTotalTimeSpent;

@JsonKey(name: 'stats_green_earned', defaultValue: 0)
final int statsGreenEarned;

@JsonKey(name: 'stats_copy_used', defaultValue: 0)
final int statsCopyUsed;

@JsonKey(name: 'stats_half_used', defaultValue: 0)
final int statsHalfUsed;

@JsonKey(name: 'stats_hint_used', defaultValue: 0)
final int statsHintUsed;

@JsonKey(name: 'stats_time_extend_used', defaultValue: 0)
final int statsTimeExtendUsed;

@JsonKey(name: 'stats_skip_used', defaultValue: 0)
final int statsSkipUsed;

@JsonKey(name: 'stats_answer_1_count', defaultValue: 0)
final int statsAnswer1Count;

@JsonKey(name: 'stats_answer_2_count', defaultValue: 0)
final int statsAnswer2Count;

@JsonKey(name: 'stats_answer_3_count', defaultValue: 0)
final int statsAnswer3Count;

@JsonKey(name: 'stats_answer_4_count', defaultValue: 0)
final int statsAnswer4Count;
```

Constructor, props, fromJson/toJson hepsini güncelle. `build_runner` çalıştır.

**Step 2: Commit**
```bash
git add lib/data/models/question_model.dart lib/data/models/question_model.g.dart
git commit -m "feat: add category, time_limit, and analytics fields to QuestionModel"
```

---

### Task 14: Yeni modeller — QuestionAnalytics, AiSuggestion, PendingChange, QuizSummary

**Files:**
- Create: `lib/data/models/question_analytics_model.dart`
- Create: `lib/data/models/ai_suggestion_model.dart`
- Create: `lib/data/models/pending_change_model.dart`
- Create: `lib/data/models/quiz_summary_model.dart`

**Step 1: QuestionAnalyticsModel**

```dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'question_analytics_model.g.dart';

@JsonSerializable()
class QuestionStatsModel extends Equatable {
  final int correct;
  final int wrong;
  @JsonKey(name: 'total_attempts')
  final int totalAttempts;
  @JsonKey(name: 'success_rate')
  final int successRate;
  @JsonKey(name: 'solve_count')
  final int solveCount;
  @JsonKey(name: 'avg_time')
  final int avgTime;
  @JsonKey(name: 'green_earned')
  final int greenEarned;
  @JsonKey(name: 'answer_distribution')
  final Map<String, int> answerDistribution;
  final Map<String, int> powers;

  const QuestionStatsModel({...});

  factory QuestionStatsModel.fromJson(Map<String, dynamic> json) => _$QuestionStatsModelFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionStatsModelToJson(this);

  @override
  List<Object?> get props => [solveCount, successRate];
}

@JsonSerializable()
class QuestionAnalyticsItem extends Equatable {
  @JsonKey(name: 'order_num')
  final int orderNum;
  @JsonKey(name: 'question_text')
  final String questionText;
  final String? category;
  @JsonKey(name: 'time_limit')
  final int timeLimit;
  final QuestionStatsModel stats;
  @JsonKey(name: 'difficulty_badge')
  final String difficultyBadge;

  const QuestionAnalyticsItem({...});

  factory QuestionAnalyticsItem.fromJson(Map<String, dynamic> json) => _$QuestionAnalyticsItemFromJson(json);

  @override
  List<Object?> get props => [orderNum];
}

@JsonSerializable()
class QuestionAnalyticsTotals extends Equatable {
  @JsonKey(name: 'total_solve_count')
  final int totalSolveCount;
  @JsonKey(name: 'total_green_earned')
  final int totalGreenEarned;
  @JsonKey(name: 'overall_success_rate')
  final int overallSuccessRate;
  @JsonKey(name: 'best_question_order')
  final int? bestQuestionOrder;

  const QuestionAnalyticsTotals({...});

  factory QuestionAnalyticsTotals.fromJson(Map<String, dynamic> json) => _$QuestionAnalyticsTotalsFromJson(json);

  @override
  List<Object?> get props => [totalSolveCount];
}

@JsonSerializable()
class QuestionAnalyticsResponse extends Equatable {
  final List<QuestionAnalyticsItem> questions;
  final QuestionAnalyticsTotals totals;

  const QuestionAnalyticsResponse({...});

  factory QuestionAnalyticsResponse.fromJson(Map<String, dynamic> json) => _$QuestionAnalyticsResponseFromJson(json);

  @override
  List<Object?> get props => [questions];
}
```

**Step 2: AiSuggestionModel**

```dart
@JsonSerializable()
class AiSuggestionModel extends Equatable {
  @JsonKey(name: 'question_text')
  final String questionText;
  final List<String> answers;
  @JsonKey(name: 'correct_answer')
  final int correctAnswer;
  final String? hint;
  final String? category;

  // fromJson, toJson, props...
}
```

**Step 3: PendingChangeModel**

```dart
@JsonSerializable()
class PendingChangeModel extends Equatable {
  final String id;
  @JsonKey(name: 'question_id')
  final String questionId;
  @JsonKey(name: 'change_type')
  final String changeType;
  final Map<String, dynamic>? payload;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;

  // fromJson, toJson, props...
}
```

**Step 4: QuizSummaryModel**

```dart
@JsonSerializable()
class QuizSummaryModel extends Equatable {
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'solver_id')
  final String solverId;
  @JsonKey(name: 'total_questions')
  final int totalQuestions;
  @JsonKey(name: 'total_correct')
  final int totalCorrect;
  @JsonKey(name: 'total_time_spent')
  final int? totalTimeSpent;
  @JsonKey(name: 'powers_used')
  final Map<String, dynamic>? powersUsed;
  @JsonKey(name: 'total_powers_used')
  final int totalPowersUsed;
  @JsonKey(name: 'performance_badge')
  final String performanceBadge;
  @JsonKey(name: 'completed_at')
  final String? completedAt;

  // fromJson, toJson, props...
}
```

**Step 5: build_runner çalıştır**
```bash
cd lib && flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 6: Commit**
```bash
git add lib/data/models/
git commit -m "feat: add analytics, AI suggestion, pending change, and quiz summary models"
```

---

### Task 15: Retrofit service + repository güncellemeleri

**Files:**
- Modify: `lib/core/network/services/question_service.dart`
- Modify: `lib/core/network/services/quiz_service.dart`
- Modify: `lib/data/repositories/question_repository.dart`
- Modify: `lib/data/repositories/quiz_repository.dart`

**Step 1: QuestionService'e yeni endpoint'ler ekle**

```dart
@GET('/questions/me/analytics')
Future<QuestionAnalyticsResponse> getAnalytics();

@GET('/questions/me/weekly-report')
Future<Map<String, dynamic>> getWeeklyReport();

@POST('/questions/ai-suggest')
Future<Map<String, dynamic>> getAiSuggestions(@Body() Map<String, dynamic> data);

@GET('/questions/me/pending')
Future<List<PendingChangeModel>> getPendingChanges();

@DELETE('/questions/me/pending/{changeId}')
Future<void> cancelPendingChange(@Path('changeId') String changeId);
```

**Step 2: QuizService'e quiz summary endpoint'i ekle**

```dart
@GET('/quiz/match/{matchId}/summary')
Future<QuizSummaryModel?> getMatchQuizSummary(@Path('matchId') String matchId);
```

**Step 3: Repository'leri güncelle (her yeni service metodu için Result<T> wrapper)**

**Step 4: build_runner çalıştır + Commit**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
git add lib/core/network/services/ lib/data/repositories/
git commit -m "feat: add analytics, AI suggest, pending changes, quiz summary to services and repos"
```

---

### Task 16: api_provider.dart — yeni provider'lar

**Files:**
- Modify: `lib/providers/api_provider.dart`

**Step 1: Yeni provider tanımları (mevcut pattern'i takip et)**

Mevcut provider pattern'e göre yeni service/repository erişim provider'ları otomatik gelecek — Retrofit factory'den. Sadece yeni model import'larını kontrol et.

**Step 2: Commit**
```bash
git add lib/providers/api_provider.dart
git commit -m "feat: update api providers for new question system endpoints"
```

---

## Phase 9: Flutter — Question Provider + Analytics Provider

### Task 17: Question provider güncelle + analytics provider oluştur

**Files:**
- Modify: `lib/providers/question_provider.dart`
- Create: `lib/providers/question_analytics_provider.dart`

**Step 1: question_provider.dart — createQuestion/updateQuestion'a category + time_limit ekle**

Mevcut createQuestion ve updateQuestion data map'lerine `category` ve `time_limit` alanlarını ekle. Return type'ı `queued` flag'ini destekleyecek şekilde güncelle.

**Step 2: question_analytics_provider.dart oluştur**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/question_analytics_model.dart';
import 'api_provider.dart';

class QuestionAnalyticsNotifier extends AsyncNotifier<QuestionAnalyticsResponse?> {
  @override
  Future<QuestionAnalyticsResponse?> build() async => null;

  Future<void> fetchAnalytics() async {
    state = const AsyncLoading();
    final result = await ref.read(questionRepositoryProvider).getAnalytics();
    result.when(
      success: (data) => state = AsyncData(data),
      failure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }
}

final questionAnalyticsProvider =
    AsyncNotifierProvider<QuestionAnalyticsNotifier, QuestionAnalyticsResponse?>(
  QuestionAnalyticsNotifier.new,
);
```

**Step 3: AI suggestion provider**

```dart
class AiSuggestionNotifier extends AsyncNotifier<List<AiSuggestionModel>> {
  @override
  Future<List<AiSuggestionModel>> build() async => [];

  Future<void> fetchSuggestions({String? category, bool profileBased = false, String locale = 'tr'}) async {
    state = const AsyncLoading();
    final result = await ref.read(questionRepositoryProvider).getAiSuggestions({
      if (category != null) 'category': category,
      'profile_based': profileBased,
      'locale': locale,
      'count': 5,
    });
    result.when(
      success: (data) {
        final suggestions = (data['suggestions'] as List)
            .map((e) => AiSuggestionModel.fromJson(e))
            .toList();
        state = AsyncData(suggestions);
      },
      failure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }
}

final aiSuggestionProvider =
    AsyncNotifierProvider<AiSuggestionNotifier, List<AiSuggestionModel>>(
  AiSuggestionNotifier.new,
);
```

**Step 4: Pending changes provider**

```dart
class PendingChangesNotifier extends AsyncNotifier<List<PendingChangeModel>> {
  @override
  Future<List<PendingChangeModel>> build() async => [];

  Future<void> fetchPending() async {
    state = const AsyncLoading();
    final result = await ref.read(questionRepositoryProvider).getPendingChanges();
    result.when(
      success: (data) => state = AsyncData(data),
      failure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }

  Future<void> cancelChange(String changeId) async {
    await ref.read(questionRepositoryProvider).cancelPendingChange(changeId);
    await fetchPending();
  }
}

final pendingChangesProvider =
    AsyncNotifierProvider<PendingChangesNotifier, List<PendingChangeModel>>(
  PendingChangesNotifier.new,
);
```

**Step 5: Commit**
```bash
git add lib/providers/question_provider.dart lib/providers/question_analytics_provider.dart
git commit -m "feat: add question analytics, AI suggestion, and pending changes providers"
```

---

## Phase 10: Flutter — i18n Keys

### Task 18: Tüm yeni i18n key'leri ekle

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: TR ve EN map'lerine yeni key'ler ekle**

```dart
// Question Creation
'question_create_title': 'Soru Oluştur',
'question_create_easy_mode': 'Kolay Mod',
'question_create_advanced_mode': 'Gelişmiş Mod',
'question_create_step_question': 'Soruyu Yaz',
'question_create_step_answers': 'Şıkları Gir',
'question_create_step_settings': 'Ayarlar',
'question_create_step_preview': 'Önizleme',
'question_create_motto': 'Seni anlatan sorular sor — cevabı Google\'da bulunmasın',
'question_create_motto_tip': 'İpucu: "En sevdiğim mevsim?" gibi kişisel sorular daha çok çözülür',
'question_category_personality': 'Kişilik',
'question_category_music': 'Müzik',
'question_category_film': 'Film',
'question_category_sports': 'Spor',
'question_category_travel': 'Seyahat',
'question_category_food': 'Yemek',
'question_category_technology': 'Teknoloji',
'question_category_general': 'Genel',
'question_category_other': 'Diğer',
'question_time_fast': 'Hızlı',
'question_time_fast_desc': 'Düşünme, hisset!',
'question_time_normal': 'Normal',
'question_time_normal_desc': 'Standart tempo',
'question_time_relaxed': 'Rahat',
'question_time_relaxed_desc': 'Düşünmeye zaman var',
'question_time_thoughtful': 'Düşündürücü',
'question_time_thoughtful_desc': 'Zor soru hak eder',

// AI Suggestions
'ai_suggest_title': 'AI Soru Önerileri',
'ai_suggest_category': 'Kategoriye göre öner',
'ai_suggest_profile': 'Profilime göre öner',
'ai_suggest_loading': 'Sorular hazırlanıyor...',
'ai_suggest_select': 'Bu soruyu seç',
'ai_suggest_edit': 'Düzenle ve kaydet',

// Analytics
'analytics_title': 'Soru İstatistikleri',
'analytics_total_solves': 'Toplam Çözülme',
'analytics_success_rate': 'Başarı Oranı',
'analytics_green_earned': 'Kazanılan Yeşil Elmas',
'analytics_best_question': 'En İyi Sorun',
'analytics_difficulty_easy': 'Kolay',
'analytics_difficulty_medium': 'Orta',
'analytics_difficulty_hard': 'Zor',
'analytics_difficulty_legendary': 'Efsanevi',
'analytics_difficulty_unranked': 'Sıralanmadı',
'analytics_avg_time': 'Ort. Süre',
'analytics_power_usage': 'Güç Kullanımı',
'analytics_answer_distribution': 'Cevap Dağılımı',
'analytics_min_solves': 'Rozet için en az 10 çözülme gerekli',

// Pending Changes
'pending_changes_title': 'Bekleyen İşlemler',
'pending_change_update': 'Düzenleme bekliyor',
'pending_change_delete': 'Silme bekliyor',
'pending_change_cancel': 'İptal Et',
'pending_change_applied': 'Değişiklik uygulandı',
'pending_change_info': 'Aktif quiz olduğu için değişiklik kuyruğa alındı',

// Quiz Result
'quiz_result_flawless': 'Kusursuz',
'quiz_result_speed_solver': 'Hızlı Çözücü',
'quiz_result_power_master': 'Güç Ustası',
'quiz_result_determined': 'Azimli',
'quiz_result_time_spent': 'Harcanan Süre',
'quiz_result_powers_used': 'Kullanılan Güçler',

// Chat Quiz Summary
'chat_quiz_summary': 'Quiz Özeti',
'chat_quiz_summary_solved': '{count} soruyu {time}sn\'de çözdü',

// Discover Card
'discover_questions_count': '{count} soru',

// Weekly Report
'weekly_report_title': 'Haftalık Rapor',
'weekly_report_solves': 'Bu hafta soruların {count} kez çözüldü',
'weekly_report_green': '{count} yeşil elmas kazandın',

// Onboarding
'onboarding_questions_slide1_title': 'Soru Hazırla, Eşleş!',
'onboarding_questions_slide1_desc': 'Qulo\'da eşleşmek için sorularını hazırla. Birisi tüm sorularını doğru cevaplarsa eşleşirsiniz!',
'onboarding_questions_slide2_title': 'Seni Anlatan Sorular',
'onboarding_questions_slide2_desc': 'Google\'da bulunamayacak, sana özel sorular sor. "Favori yemeğim nedir?" gibi kişisel sorular daha eğlenceli!',
'onboarding_questions_slide3_title': 'Yeşil Elmas Kazan!',
'onboarding_questions_slide3_desc': 'Birisi sorularını çözerken güç kullanırsa, harcadığı mor elmasın %30\'u sana yeşil elmas olarak gelir!',
'onboarding_questions_start': 'Hemen Başla',
'onboarding_questions_later': 'Sonra',

// Profile Vitrin
'profile_vitrin_solves': 'kez çözüldü',
'profile_vitrin_success': 'başarı oranı',
'profile_vitrin_green': 'kazanıldı',
```

**Step 2: EN karşılıklarını da ekle**

**Step 3: Commit**
```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat: add i18n keys for question system overhaul"
```

---

## Phase 11: Flutter — Soru Oluşturma Ekranları

### Task 19: AppConstants + QIcons güncelle

**Files:**
- Modify: `lib/core/constants/app_constants.dart`
- Modify: `lib/core/constants/q_icons.dart`

**Step 1: AppConstants'a yeni sabitler ekle**

```dart
static const List<int> timePresets = [15, 30, 60, 90];
static const List<String> questionCategories = [
  'personality', 'music', 'film', 'sports', 'travel',
  'food', 'technology', 'general', 'other',
];
```

**Step 2: QIcons'a yeni ikonlar ekle**

```dart
static const String icWand = 'assets/icons/ic_wand.svg';       // AI/Easy mode
static const String icSteps = 'assets/icons/ic_steps.svg';     // Wizard/Advanced
static const String icChart = 'assets/icons/ic_chart.svg';     // Analytics
static const String icCrown = 'assets/icons/ic_crown.svg';     // Best question
static const String icFire = 'assets/icons/ic_fire.svg';       // Difficulty
static const String icTarget = 'assets/icons/ic_target.svg';   // Quiz accuracy
static const String icQueue = 'assets/icons/ic_queue.svg';     // Pending changes
```

**Step 3: SVG ikonlarını assets/icons/'a ekle (placeholder olarak basit SVG'ler oluştur)**

**Step 4: Commit**
```bash
git add lib/core/constants/ assets/icons/
git commit -m "feat: add new constants and icons for question system"
```

---

### Task 20: Question Creation Wizard (Advanced Mode) — tam ekran

**Files:**
- Create: `lib/features/questions/screens/question_create_screen.dart`
- Create: `lib/features/questions/widgets/question_step_text.dart`
- Create: `lib/features/questions/widgets/question_step_answers.dart`
- Create: `lib/features/questions/widgets/question_step_settings.dart`
- Create: `lib/features/questions/widgets/question_preview_card.dart`

**Step 1: Ana wizard ekranı (PageView ile 3 adım + preview card)**

`question_create_screen.dart`:
- PageController ile 3 sayfa (question text, answers, settings)
- Her sayfanın sağ/alt kısmında QuestionPreviewCard (canlı önizleme)
- Progress indicator (3 dot veya linear)
- İleri/Geri butonları
- Son adımda "Kaydet" butonu
- İki mod toggle: Easy Mode / Advanced Mode (AppBar'da)
- Soru metni altında motto: "Seni anlatan sorular sor..."

**Step 2: question_step_text.dart — Soru metni + kategori seçimi**
- TextFormField: soru metni
- Wrap ile kategori chip'leri (opsiyonel seçim)
- Sağda/altta canlı preview

**Step 3: question_step_answers.dart — 4 şık + doğru cevap**
- 4 TextFormField
- Radio/toggle ile doğru cevap seçimi
- İpucu TextField (opsiyonel, collapsible)

**Step 4: question_step_settings.dart — Süre preset seçimi**
- 4 preset kartı (15/30/60/90sn) — her biri emoji + açıklama
- Seçili preset'e border/highlight

**Step 5: question_preview_card.dart — Canlı quiz preview**
- Soru metni
- 4 şık butonu (dummy)
- Timer göstergesi (seçili preset'e göre)
- İpucu ikonu (varsa)
- Kategori badge'i (varsa)

**Step 6: Düzenleme modu desteği — mevcut soruyu yükle**
- Constructor'a opsiyonel `QuestionModel? editQuestion` parametresi
- Varsa form'u doldur, yoksa boş başlat
- Düzenleme modunda "Güncelle" butonu, yeni modda "Kaydet"

**Step 7: Commit**
```bash
git add lib/features/questions/
git commit -m "feat: add full-screen question creation wizard with live preview"
```

---

### Task 21: Easy Mode — AI soru önerileri ekranı

**Files:**
- Create: `lib/features/questions/screens/question_easy_mode_screen.dart`
- Create: `lib/features/questions/widgets/ai_suggestion_card.dart`

**Step 1: question_easy_mode_screen.dart**
- Kategori seçim grid'i (chip'ler veya kartlar)
- "Profilime göre öner" butonu
- Seçim sonrası → aiSuggestionProvider.fetchSuggestions()
- Loading: AppLoadingWidget
- Sonuç: 3-5 AiSuggestionCard listesi
- Her kart tıklanınca → question_create_screen'e pre-filled olarak git (düzenleme modu)

**Step 2: ai_suggestion_card.dart**
- Soru metni
- 4 şık (readonly gösterim)
- "Bu Soruyu Seç" butonu
- Kategori badge'i

**Step 3: Commit**
```bash
git add lib/features/questions/
git commit -m "feat: add AI-powered easy mode question creation screen"
```

---

### Task 22: Questions listesi ekranını yeniden yaz

**Files:**
- Modify: `lib/features/profile/screens/questions_screen.dart` → Taşı: `lib/features/questions/screens/questions_list_screen.dart`

**Step 1: Mevcut dialog tabanlı yaklaşımı kaldır, tam ekran wizard'a yönlendir**

- FAB tıklandığında → question_create_screen'e navigate et (mode seçim bottom sheet: Easy / Advanced)
- Soru kartına tıklandığında → question_create_screen'e editQuestion ile navigate et
- Silme: swipe-to-delete veya trailing icon
- Her soru kartında:
  - Soru metni + kategori badge + süre preset etiketi
  - Stats özeti (çözülme sayısı + zorluk badge'i)
  - Bekleyen değişiklik varsa badge
- "Bekleyen İşlemler" section'ı (pendingChangesProvider)
- Analytics dashboard'a geçiş butonu (AppBar action)

**Step 2: Commit**
```bash
git add lib/features/questions/ lib/features/profile/screens/
git commit -m "feat: redesign questions list screen with full-screen creation flow"
```

---

## Phase 12: Flutter — Analytics Dashboard

### Task 23: Soru analytics dashboard ekranı

**Files:**
- Create: `lib/features/questions/screens/question_analytics_screen.dart`
- Create: `lib/features/questions/widgets/difficulty_badge.dart`
- Create: `lib/features/questions/widgets/analytics_stat_card.dart`
- Create: `lib/features/questions/widgets/power_usage_chart.dart`

**Step 1: question_analytics_screen.dart**
- AppScaffold, isLoading: state is AsyncLoading
- Üstte toplam istatistik kartları (3'lü grid): Toplam Çözülme, Başarı Oranı, Toplam Yeşil Elmas
- "En İyi Sorun" highlight kartı (taç ikonu + yeşil elmas kazancı)
- Soru bazlı kartlar (ListView):
  - Soru metni + zorluk rozeti (DifficultyBadge widget)
  - Doğru/yanlış oranı (mini progress bar)
  - Ortalama süre
  - Güç kullanım dağılımı (küçük ikonlu sayaçlar)
  - Cevap dağılımı (4 bar)
  - "Bu soru sana X yeşil elmas kazandırdı" text

**Step 2: difficulty_badge.dart**
- easy: yeşil chip "Kolay"
- medium: sarı chip "Orta"
- hard: turuncu chip "Zor"
- legendary: mor glow'lu chip "Efsanevi"
- unranked: gri chip "10+ çözülme gerekli"

**Step 3: analytics_stat_card.dart**
- İkon + sayı + label (reusable)

**Step 4: power_usage_chart.dart**
- 5 güç ikonu + yanında sayı (basit row layout)

**Step 5: Commit**
```bash
git add lib/features/questions/
git commit -m "feat: add gamified question analytics dashboard"
```

---

## Phase 13: Flutter — Quiz Ekranı Güncellemeleri

### Task 24: Quiz ekranı — soru bazlı timer + time_spent gönderme

**Files:**
- Modify: `lib/features/quiz/screens/quiz_screen.dart`
- Modify: `lib/providers/quiz_provider.dart`

**Step 1: Timer'ı soru bazlı time_limit'e göre ayarla**

Mevcut sabit 30sn yerine `currentQuestion.timeLimitSeconds` kullan.

**Step 2: Her cevap gönderiminde time_spent hesapla ve gönder**

```dart
// Soru başladığında stopwatch başlat
final _stopwatch = Stopwatch();

void _onQuestionLoaded() {
  _stopwatch.reset();
  _stopwatch.start();
}

void _answer(int index, {String? powerUsed}) {
  _stopwatch.stop();
  final timeSpent = _stopwatch.elapsedMilliseconds ~/ 1000;
  ref.read(quizProvider.notifier).answer(index, powerUsed: powerUsed, timeSpent: timeSpent);
}
```

**Step 3: Quiz provider — answer metoduna timeSpent parametresi ekle**

```dart
Future<void> answer(int selectedAnswer, {String? powerUsed, int? timeSpent}) async {
  // ... mevcut kod
  final result = await repo.answerQuestion(
    state.sessionId!, selectedAnswer,
    powerUsed: powerUsed, timeSpent: timeSpent,
  );
  // ...
}
```

**Step 4: Commit**
```bash
git add lib/features/quiz/ lib/providers/quiz_provider.dart
git commit -m "feat: add per-question timer and time_spent tracking to quiz"
```

---

### Task 25: Quiz sonuç ekranı — gamified result

**Files:**
- Create: `lib/features/quiz/widgets/quiz_result_dialog.dart`

**Step 1: Mevcut basit InfoDialog yerine gamified sonuç dialog'u**

```dart
class QuizResultDialog extends ConsumerWidget {
  final bool matched;
  final int totalCorrect;
  final int totalQuestions;
  final int totalTimeSpent;
  final int powersUsed;
  final String performanceBadge;

  // Performans rozeti gösterimi (ikon + renk + metin)
  // Doğru/yanlış sayısı
  // Harcanan süre
  // Kullanılan güç sayısı
  // Matched ise: "Eşleştin! Sohbete Başla" butonu
  // Failed ise: "Tekrar Dene" veya "Geri Dön" butonları
}
```

**Step 2: quiz_screen.dart'ta _showResult'u güncelle**

**Step 3: Commit**
```bash
git add lib/features/quiz/
git commit -m "feat: add gamified quiz result dialog with performance badges"
```

---

## Phase 14: Flutter — Onboarding

### Task 26: Soru onboarding slide'ları

**Files:**
- Create: `lib/features/questions/screens/question_onboarding_screen.dart`
- Create: `lib/features/questions/widgets/onboarding_slide.dart`

**Step 1: question_onboarding_screen.dart**
- 3 slide (PageView + PageController)
- Slide 1: "Soru Hazırla, Eşleş!" — quiz akışı illüstrasyonu
- Slide 2: "Seni Anlatan Sorular" — kişisel soru örneği
- Slide 3: "Yeşil Elmas Kazan!" — elmas motivasyonu
- Dot indicator
- "Hemen Başla" butonu (son slide'da) → questions_list_screen'e git
- "Sonra" butonu (her slide'da) → pop
- SharedPreferences: `onboarding_questions_seen = true`

**Step 2: onboarding_slide.dart — reusable slide widget**
- İkon/illüstrasyon (SVG veya Lottie)
- Başlık
- Açıklama
- Gradient arka plan

**Step 3: Onboarding tetikleme mantığı**
Login sonrası `onboarding_questions_seen` kontrolü. False ise → onboarding_screen göster.

**Step 4: Commit**
```bash
git add lib/features/questions/
git commit -m "feat: add question system onboarding slides"
```

---

### Task 27: Kademeli nudge sistemi (mevcut sistemi genişlet)

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`

**Step 1: Discover kilit ekranına Easy Mode CTA'sı ekle**

Mevcut lock overlay'e:
- 2. giriş (SharedPreferences counter): "Easy mode ile 30 saniyede soru hazırla!" text'i + buton
- 3. giriş: Easy mode bottom sheet otomatik açılır

**Step 2: SharedPreferences counter mantığı**
```dart
final prefs = await SharedPreferences.getInstance();
final nudgeCount = prefs.getInt('question_nudge_count') ?? 0;
await prefs.setInt('question_nudge_count', nudgeCount + 1);
```

**Step 3: Commit**
```bash
git add lib/features/discover/
git commit -m "feat: add progressive nudge system with easy mode integration"
```

---

## Phase 15: Flutter — App Geneli Entegrasyon

### Task 28: Discover kartında soru bilgisi göster

**Files:**
- Modify: `lib/features/discover/widgets/profile_card.dart` (veya ilgili kart widget'ı)

**Step 1: Discover response'taki question_info'yu kullan**

Candidate model'e `questionInfo` alanını ekle, kart üzerinde:
- Soru sayısı badge: "5 soru"
- Zorluk badge: DifficultyBadge widget'ı
- Kategori tag'leri (varsa): küçük chip'ler

**Step 2: Commit**
```bash
git add lib/features/discover/
git commit -m "feat: show question count, difficulty, and categories on discover cards"
```

---

### Task 29: Profil ekranına vitrin bölümü ekle

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`
- Create: `lib/features/profile/widgets/question_vitrin_card.dart`

**Step 1: question_vitrin_card.dart**
- 3'lü row: Çözülme sayısı | Başarı oranı | Yeşil elmas kazancı
- Her biri ikon + sayı + label
- Tıklanınca analytics dashboard'a git
- Analytics verisi yoksa gösterme

**Step 2: profile_screen.dart'a vitrin kartını ekle**
- QuestionGateBanner'ın altına (veya soruları varsa onun yerine)

**Step 3: Commit**
```bash
git add lib/features/profile/
git commit -m "feat: add question stats vitrin section to profile screen"
```

---

### Task 30: Chat ekranında quiz özeti kartı

**Files:**
- Modify: `lib/features/chat/screens/chat_screen.dart`
- Create: `lib/features/chat/widgets/quiz_summary_card.dart`
- Create: `lib/providers/quiz_summary_provider.dart`

**Step 1: quiz_summary_provider.dart**

```dart
final quizSummaryProvider = FutureProvider.family<QuizSummaryModel?, String>((ref, matchId) async {
  final result = await ref.read(quizRepositoryProvider).getMatchQuizSummary(matchId);
  return result.when(success: (data) => data, failure: (_) => null);
});
```

**Step 2: quiz_summary_card.dart**
- Pinlenmiş kart (mesaj listesinin üstünde)
- "{totalCorrect}/{totalQuestions} soruyu {totalTimeSpent}sn'de çözdü"
- Kullanılan güçler (ikonlarla)
- Performans rozeti
- Tıklanınca expand (detaylı breakdown)

**Step 3: chat_screen.dart — mesaj listesinin üstüne quiz summary kartı ekle**

```dart
final quizSummary = ref.watch(quizSummaryProvider(matchId));
// ListView'ın üstüne QuizSummaryCard ekle
```

**Step 4: Commit**
```bash
git add lib/features/chat/ lib/providers/quiz_summary_provider.dart
git commit -m "feat: add quiz summary card to chat screen as ice breaker"
```

---

### Task 31: Routing güncellemeleri — yeni ekranlar

**Files:**
- Modify: `lib/routing/app_routes.dart`
- Modify: `lib/routing/route_names.dart` (veya eşdeğeri)

**Step 1: Yeni route'ları ekle**

```dart
// Mevcut pattern'i takip et
GoRoute(
  path: 'questions/create',
  name: RouteNames.questionCreate,
  builder: (context, state) {
    final editQuestion = state.extra as QuestionModel?;
    return QuestionCreateScreen(editQuestion: editQuestion);
  },
),
GoRoute(
  path: 'questions/easy-mode',
  name: RouteNames.questionEasyMode,
  builder: (context, state) => const QuestionEasyModeScreen(),
),
GoRoute(
  path: 'questions/analytics',
  name: RouteNames.questionAnalytics,
  builder: (context, state) => const QuestionAnalyticsScreen(),
),
GoRoute(
  path: 'questions/onboarding',
  name: RouteNames.questionOnboarding,
  parentNavigatorKey: rootNavigatorKey, // Full screen
  builder: (context, state) => const QuestionOnboardingScreen(),
),
```

**Step 2: RouteNames'e yeni sabitler ekle**

```dart
static const questionCreate = 'questionCreate';
static const questionEasyMode = 'questionEasyMode';
static const questionAnalytics = 'questionAnalytics';
static const questionOnboarding = 'questionOnboarding';
```

**Step 3: Commit**
```bash
git add lib/routing/
git commit -m "feat: add routes for question creation, easy mode, analytics, and onboarding"
```

---

## Phase 16: Haftalık Bildirim Entegrasyonu

### Task 32: Haftalık bildirim — backend cron veya manuel trigger

**Files:**
- Create: `server/src/services/weekly-report.service.ts`
- Modify: `server/src/routes/question.routes.ts`

**Step 1: weekly-report.service.ts**

```typescript
import { supabase } from '../config/supabase.js';
import { NotificationService } from './notification.service.js';
import { questionService } from './question.service.js';

class WeeklyReportService {
  async sendWeeklyReports() {
    // Sorusu olan tüm kullanıcıları bul
    const { data: users } = await supabase
      .from('users')
      .select('id, locale')
      .not('is_deleted', 'eq', true);

    let sent = 0;
    for (const user of users ?? []) {
      try {
        const report = await questionService.getWeeklyReport(user.id);
        if (report.total_solves === 0) continue; // Bu hafta aktivite yoksa gönderme

        await NotificationService.sendPush(user.id, 'campaign', {
          body: `Bu hafta soruların ${report.total_solves} kez çözüldü, ${report.green_earned} yeşil elmas kazandın!`,
        }, undefined, {
          title: 'Haftalık Raporun',
          actionUrl: '/profile/questions/analytics',
        });
        sent++;
      } catch {
        // Skip failed users
      }
    }
    return { sent };
  }
}

export const weeklyReportService = new WeeklyReportService();
```

**Step 2: Admin/debug endpoint (cron olmadığı için manuel tetikleme)**

```typescript
// question.routes.ts'e ekle (sadece admin middleware ile)
router.post('/admin/weekly-reports', adminAuthMiddleware, async (req, res) => {
  const result = await weeklyReportService.sendWeeklyReports();
  res.json(result);
});
```

**Step 3: Commit**
```bash
git add server/src/services/weekly-report.service.ts server/src/routes/question.routes.ts
git commit -m "feat: add weekly question report notification service"
```

---

## Özet — 32 Task, 16 Phase

| Phase | Task | Açıklama |
|-------|------|----------|
| 1 | 1 | DB Migration 010 |
| 2 | 2-4 | Backend: question validator + service + analytics endpoint |
| 3 | 5-7 | Backend: quiz time_limit + time_spent + güç stats |
| 4 | 8 | Backend: pending changes queue system |
| 5 | 9 | Backend: Gemini AI suggest service |
| 6 | 10-11 | Backend: quiz summary + weekly report |
| 7 | 12 | Backend: discover'a soru bilgisi ekleme |
| 8 | 13-16 | Flutter: model + service + repository + provider güncellemeleri |
| 9 | 17 | Flutter: analytics + AI + pending providers |
| 10 | 18 | Flutter: i18n keys |
| 11 | 19-22 | Flutter: soru oluşturma wizard + easy mode + liste redesign |
| 12 | 23 | Flutter: analytics dashboard |
| 13 | 24-25 | Flutter: quiz timer + gamified result |
| 14 | 26-27 | Flutter: onboarding + kademeli nudge |
| 15 | 28-31 | Flutter: discover + profil + chat + routing entegrasyonu |
| 16 | 32 | Backend: haftalık bildirim servisi |

**Bağımlılık sırası:** Phase 1 → 2-7 (paralel) → 8-9 → 10 → 11-16 (paralel)
