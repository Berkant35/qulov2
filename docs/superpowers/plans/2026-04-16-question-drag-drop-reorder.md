# Question Drag & Drop Reorder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** My Questions ekranında drag & drop ile soru sıralaması değiştirme

**Architecture:** Server'a batch reorder endpoint eklenir (`PATCH /questions/me/reorder`). Flutter'da `ListView` → `ReorderableListView` dönüşümü + optimistic update + rollback. Retrofit service → repository → provider zinciri.

**Tech Stack:** Flutter ReorderableListView, Riverpod, Retrofit, Express, Zod, Supabase

---

### Task 1: Server — Validator + Service + Controller + Route

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/validators/question.validator.ts`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/services/question.service.ts`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/controllers/question.controller.ts`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulo-server/src/routes/question.routes.ts`

- [ ] **Step 1: Add reorder validator schema**

`question.validator.ts` — dosyanın sonuna ekle:

```typescript
export const reorderQuestionsSchema = z.object({
  order: z.array(z.string().uuid()).min(1).max(10),
});

export type ReorderQuestionsInput = z.infer<typeof reorderQuestionsSchema>;
```

- [ ] **Step 2: Add reorderByIds method to service**

`question.service.ts` — `reorderQuestions` private metodunun altına ekle:

```typescript
  async reorderByIds(userId: string, orderedIds: string[]) {
    // Verify all IDs belong to this user
    const { data: existing, error } = await supabase
      .from("questions")
      .select("id")
      .eq("user_id", userId);

    if (error) throw Errors.SERVER_ERROR();

    const existingIds = new Set(existing.map((q) => q.id));
    const inputIds = new Set(orderedIds);

    // Every existing question must be in the input, and vice versa
    if (existingIds.size !== inputIds.size || !orderedIds.every((id) => existingIds.has(id))) {
      throw new AppError("INVALID_REORDER", 400, "Order must contain exactly all question IDs");
    }

    // Update each question's order_num based on position in array
    for (let i = 0; i < orderedIds.length; i++) {
      const { error: updateError } = await supabase
        .from("questions")
        .update({ order_num: i + 1 })
        .eq("id", orderedIds[i]);

      if (updateError) throw Errors.SERVER_ERROR();
    }

    // Return updated list
    return this.getMyQuestions(userId);
  }
```

Not: `AppError` import'u zaten dosyanın başında var (`import { AppError, Errors } from "../utils/errors.js";`).

- [ ] **Step 3: Add controller handler**

`question.controller.ts` — dosyanın sonuna ekle. Ayrıca import'a `ReorderQuestionsInput` ekle:

Import satırını güncelle:
```typescript
import type { CreateQuestionInput, UpdateQuestionInput, ReorderQuestionsInput } from "../validators/question.validator.js";
```

Handler:
```typescript
export async function reorderQuestionsHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId;
    const { order } = req.body as ReorderQuestionsInput;
    const data = await questionService.reorderByIds(userId, order);
    res.json(data);
  } catch (err) {
    next(err);
  }
}
```

- [ ] **Step 4: Add route**

`question.routes.ts` — import'lara `reorderQuestionsHandler` ve `reorderQuestionsSchema` ekle, route'u `/me/:order` satırından ÖNCE ekle (parametre çakışmasını önlemek için):

Import güncellemeleri:
```typescript
import { createQuestionSchema, updateQuestionSchema, reorderQuestionsSchema } from "../validators/question.validator.js";
import {
  getMyQuestionsHandler,
  createQuestionHandler,
  updateQuestionHandler,
  deleteQuestionHandler,
  getQuestionCountHandler,
  getQuestionAnalyticsHandler,
  getWeeklyReportHandler,
  reorderQuestionsHandler,
} from "../controllers/question.controller.js";
```

Route (satır 28, `router.patch("/me/:order"...)` satırından ÖNCE):
```typescript
router.patch("/me/reorder", validate(reorderQuestionsSchema), reorderQuestionsHandler);
```

- [ ] **Step 5: TypeScript build kontrolü**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npx tsc --noEmit`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git add src/validators/question.validator.ts src/services/question.service.ts src/controllers/question.controller.ts src/routes/question.routes.ts
git commit -m "feat(server): add batch reorder endpoint for questions"
```

---

### Task 2: Server — Push to GitHub (Railway auto-deploy)

- [ ] **Step 1: Push**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git push origin main
```

---

### Task 3: Flutter — Retrofit Service + Repository + Interface

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/core/network/services/question_service.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/data/repositories/interfaces.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/data/repositories/question_repository.dart`

- [ ] **Step 1: Add retrofit method to service**

`question_service.dart` — `deleteQuestion` metodunun altına ekle:

```dart
  @PATCH('/questions/me/reorder')
  Future<List<QuestionModel>> reorderQuestions(@Body() Map<String, dynamic> data);
```

- [ ] **Step 2: Run build_runner to regenerate .g.dart**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart run build_runner build --delete-conflicting-outputs`
Expected: `question_service.g.dart` regenerated without errors

- [ ] **Step 3: Add interface method**

`interfaces.dart` — `IQuestionRepository` içinde `getQuestionCount()` satırının altına ekle:

```dart
  Future<Result<List<QuestionModel>>> reorderQuestions(List<String> orderedIds);
```

- [ ] **Step 4: Implement in repository**

`question_repository.dart` — `deleteQuestion` metodunun altına ekle:

```dart
  @override
  Future<Result<List<QuestionModel>>> reorderQuestions(List<String> orderedIds) async {
    try {
      final response = await _service.reorderQuestions({'order': orderedIds});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
```

- [ ] **Step 5: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/core/network/services/question_service.dart lib/core/network/services/question_service.g.dart lib/data/repositories/interfaces.dart lib/data/repositories/question_repository.dart
git commit -m "feat: add reorder questions API layer"
```

---

### Task 4: Flutter — Provider (Optimistic Reorder)

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/providers/question_provider.dart`

- [ ] **Step 1: Add reorderQuestions method**

`question_provider.dart` — `deleteQuestion` metodunun altına ekle:

```dart
  Future<void> reorderQuestions(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Adjust index for ReorderableListView behavior
    if (newIndex > oldIndex) newIndex--;

    final reordered = List<QuestionModel>.from(current);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Optimistic update
    state = AsyncData(reordered);

    final orderedIds = reordered.map((q) => q.id).toList();
    final result = await ref.read(questionRepositoryProvider).reorderQuestions(orderedIds);
    result.when(
      success: (data) => state = AsyncData(data),
      failure: (f) {
        // Rollback
        state = AsyncData(current);
        dev.log('reorderQuestions failed: $f', name: 'QuestionNotifier');
      },
    );
  }
```

- [ ] **Step 2: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/providers/question_provider.dart
git commit -m "feat: add optimistic reorder with rollback to question provider"
```

---

### Task 5: Flutter — UI (ReorderableListView + Drag Handle)

**Files:**
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/features/profile/screens/questions_screen.dart`
- Modify: `/Users/berkantcalikusu/IdeaProjects/qulo/qulov2/lib/features/profile/widgets/questions_list_card.dart`

- [ ] **Step 1: Add HapticFeedback import to questions_screen.dart**

`questions_screen.dart` — import'ların arasına ekle:

```dart
import 'package:flutter/services.dart';
```

- [ ] **Step 2: Replace ListView with ReorderableListView**

`questions_screen.dart` — `data:` callback'teki mevcut `ListView` bloğunu (satır 58-71) şununla değiştir:

```dart
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: questions.length,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.mediumImpact();
              ref.read(questionProvider.notifier).reorderQuestions(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  color: Colors.transparent,
                  child: child,
                ),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final q = questions[index];
              return Padding(
                key: ValueKey(q.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: QuestionsListCard(
                  question: q,
                  difficultyLabel: difficultyLabel(q),
                  difficultyColor: difficultyColor(q),
                  onTap: () => editQuestion(q),
                  onDelete: () => deleteQuestion(q),
                ),
              );
            },
          );
```

**Önemli:** `proxyDecorator`'da `AnimatedBuilder` yerine `AnimatedBuilder` kullan — bu Flutter'ın standart widget'ı. Eğer linting hata verirse `Material` wrapper yeterli.

- [ ] **Step 3: Add drag handle to QuestionsListCard**

`questions_list_card.dart` — `Row` içindeki mevcut `IconButton(icon: Icon(Icons.delete_outline...))` (satır 149-156) ile `const Spacer()` (satır 148) arasına drag handle ekle. `const Spacer()` ve delete butonunu şununla değiştir:

```dart
                    const Spacer(),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        color: context.appColors.textHint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: context.appColors.error, size: 18),
                      onPressed: onDelete,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
```

Bunun için `QuestionsListCard`'a `index` parametresi eklenmeli:

Constructor'a ekle:
```dart
  final int index;
```

Constructor body'ye ekle:
```dart
    required this.index,
```

- [ ] **Step 4: Update QuestionsListCard Dismissible — key'den Padding'e taşındı**

`QuestionsListCard`'daki `Dismissible` widget'ını kaldır çünkü `ReorderableListView` + `Dismissible` long-press çakışmasına neden olabilir. Silme işlemi zaten delete butonu ve `onDelete` callback ile yapılıyor. `Dismissible` wrapper'ını (satır 32-47) kaldırıp, doğrudan `GestureDetector`'ı döndür:

```dart
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.appColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          // ... mevcut Column children aynen kalır
```

`Padding` wrapper'ı kaldırıldı çünkü `questions_screen.dart`'taki `ReorderableListView.builder`'da `Padding` zaten `key: ValueKey(q.id)` ile sarılıyor.

- [ ] **Step 5: Update questions_screen.dart — pass index to QuestionsListCard**

`questions_screen.dart`'taki `QuestionsListCard` çağrısına `index` parametresini ekle:

```dart
                child: QuestionsListCard(
                  index: index,
                  question: q,
                  difficultyLabel: difficultyLabel(q),
                  difficultyColor: difficultyColor(q),
                  onTap: () => editQuestion(q),
                  onDelete: () => deleteQuestion(q),
                ),
```

- [ ] **Step 6: Dart analyze**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && dart analyze lib/features/profile/screens/questions_screen.dart lib/features/profile/widgets/questions_list_card.dart`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/features/profile/screens/questions_screen.dart lib/features/profile/widgets/questions_list_card.dart
git commit -m "feat: add drag & drop reorder to My Questions screen"
```

---

### Task 6: Manual Test

- [ ] **Step 1: Hot restart the app**
- [ ] **Step 2: Go to My Questions screen**
- [ ] **Step 3: Long-press a question card's drag handle and drag it to a new position**
- [ ] **Step 4: Verify the order updates immediately (optimistic)**
- [ ] **Step 5: Verify the order persists after leaving and returning to the screen**
- [ ] **Step 6: Delete a question and verify order_nums are sequential**
