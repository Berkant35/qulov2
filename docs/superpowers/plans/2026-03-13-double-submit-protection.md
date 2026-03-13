# Double-Submit Protection & Idempotency — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate duplicate API calls from rapid button taps across the entire app, with client-side SafeTapButton widget + Dio idempotency interceptor + backend idempotency middleware.

**Architecture:** Three-layer defense: (1) SafeTapButton widget prevents UI-level double taps with debounce + loading state, (2) Dio interceptor adds Idempotency-Key header to every mutation request, (3) Express middleware caches 2xx responses by key and returns cached response for duplicates.

**Tech Stack:** Flutter/Dart (widget + interceptor), Node.js/Express/TypeScript (middleware), uuid package (both sides)

**Spec:** `docs/superpowers/specs/2026-03-13-double-submit-protection-design.md`

---

## Chunk 1: Infrastructure — SafeTapButton Widget + Interceptor

### Task 1: Create SafeTapButton Widget

**Files:**
- Create: `lib/core/widgets/safe_tap_button.dart`

- [ ] **Step 1: Create SafeTapButton widget**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';

typedef SafeTapWidgetBuilder = Widget Function(
  BuildContext context,
  bool isLoading,
  VoidCallback? onTap,
);

class SafeTapButton extends StatefulWidget {
  final Future<void> Function()? onTap;
  final Duration debounceDuration;
  final SafeTapWidgetBuilder builder;

  const SafeTapButton({
    super.key,
    required this.onTap,
    required this.builder,
    this.debounceDuration = AppDurations.debounce,
  });

  @override
  State<SafeTapButton> createState() => _SafeTapButtonState();
}

class _SafeTapButtonState extends State<SafeTapButton> {
  bool _isRunning = false;
  Timer? _cooldownTimer;

  Future<void> _handleTap() async {
    if (_isRunning || widget.onTap == null) return;

    setState(() => _isRunning = true);

    try {
      await widget.onTap!();
    } finally {
      if (!mounted) return;
      // Cooldown period after completion
      _cooldownTimer = Timer(widget.debounceDuration, () {
        if (mounted) setState(() => _isRunning = false);
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;
    return widget.builder(
      context,
      _isRunning,
      isDisabled ? null : (_isRunning ? null : _handleTap),
    );
  }
}
```

- [ ] **Step 2: Verify widget compiles**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/core/widgets/safe_tap_button.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/safe_tap_button.dart
git commit -m "feat: add SafeTapButton widget for double-submit protection"
```

---

### Task 2: Create Idempotency Interceptor

**Files:**
- Create: `lib/core/network/interceptors/idempotency_interceptor.dart`
- Modify: `lib/core/network/network_manager.dart:36-40`

- [ ] **Step 1: Create IdempotencyInterceptor**

```dart
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class IdempotencyInterceptor extends Interceptor {
  static const _mutationMethods = ['POST', 'PUT', 'PATCH', 'DELETE'];
  static const _headerKey = 'Idempotency-Key';
  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_mutationMethods.contains(options.method.toUpperCase())) {
      options.headers[_headerKey] ??= _uuid.v4();
    }
    handler.next(options);
  }
}
```

- [ ] **Step 2: Register interceptor in NetworkManager**

In `lib/core/network/network_manager.dart`, add `IdempotencyInterceptor()` to the interceptors list at line 36-40:

```dart
_dio.interceptors.addAll([
  IdempotencyInterceptor(),
  AuthInterceptor(_dio, onForceLogout: onForceLogout),
  AppLogInterceptor(),
  ErrorInterceptor(),
]);
```

Note: `IdempotencyInterceptor` goes FIRST so the key is set before auth/logging interceptors run.

- [ ] **Step 3: Add import to network_manager.dart**

Add at top of file:
```dart
import 'package:qulo_v2/core/network/interceptors/idempotency_interceptor.dart';
```

- [ ] **Step 4: Verify compilation**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/core/network/`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/core/network/interceptors/idempotency_interceptor.dart lib/core/network/network_manager.dart
git commit -m "feat: add Dio IdempotencyInterceptor for mutation requests"
```

---

### Task 3: Create Backend Idempotency Middleware

**Files:**
- Create: `src/middleware/idempotency.ts`
- Modify: `src/index.ts:49-50` (after cors, before routes)

- [ ] **Step 1: Create idempotency middleware**

```typescript
import { Request, Response, NextFunction } from "express";

interface CachedResponse {
  status: number;
  body: any;
  timestamp: number;
}

const MUTATION_METHODS = new Set(["POST", "PUT", "PATCH", "DELETE"]);
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes
const CLEANUP_INTERVAL_MS = 60 * 1000; // 1 minute
const HEADER_KEY = "idempotency-key";

const cache = new Map<string, CachedResponse | "processing">();

// Periodic cleanup of expired entries
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of cache.entries()) {
    if (value === "processing") continue;
    if (now - value.timestamp > CACHE_TTL_MS) {
      cache.delete(key);
    }
  }
}, CLEANUP_INTERVAL_MS);

export function idempotencyMiddleware(req: Request, res: Response, next: NextFunction) {
  // Only apply to mutation methods
  if (!MUTATION_METHODS.has(req.method)) {
    return next();
  }

  const idempotencyKey = req.headers[HEADER_KEY] as string | undefined;
  if (!idempotencyKey) {
    return next(); // Backward compatible — no key, no caching
  }

  const userId = (req as any).user?.userId ?? "anonymous";
  const cacheKey = `${userId}:${idempotencyKey}`;

  const cached = cache.get(cacheKey);

  // Cache hit — return cached response
  if (cached && cached !== "processing") {
    return res.status(cached.status).json(cached.body);
  }

  // Currently processing — return 409 Conflict
  if (cached === "processing") {
    return res.status(409).json({ error: { code: "DUPLICATE_REQUEST", message: "Request is already being processed" } });
  }

  // Mark as processing
  cache.set(cacheKey, "processing");

  // Override res.json to cache the response
  const originalJson = res.json.bind(res);
  res.json = function (body: any) {
    const statusCode = res.statusCode;

    // Only cache 2xx responses
    if (statusCode >= 200 && statusCode < 300) {
      cache.set(cacheKey, {
        status: statusCode,
        body,
        timestamp: Date.now(),
      });
    } else {
      // Error response — remove processing flag so key can be retried
      cache.delete(cacheKey);
    }

    return originalJson(body);
  };

  next();
}
```

- [ ] **Step 2: Register middleware in index.ts**

In `src/index.ts`, after `app.use(express.json(...))` (line 50), add:

```typescript
import { idempotencyMiddleware } from "./middleware/idempotency.js";
```

And after `app.use(express.json({ limit: "10mb" }));`:

```typescript
app.use(idempotencyMiddleware);
```

Note: Must go AFTER `express.json()` (needs parsed body) and AFTER auth middleware is available on routes. Since auth is per-route, the middleware reads `req.user` which may be undefined for public routes — that's handled with the `"anonymous"` fallback.

- [ ] **Step 3: Verify server starts**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npx tsx src/index.ts`
Expected: `[server] Running on port 3001 in development mode`

- [ ] **Step 4: Commit**

```bash
git add src/middleware/idempotency.ts src/index.ts
git commit -m "feat: add idempotency middleware for mutation requests"
```

---

## Chunk 2: Critical Path Migration — Quiz Flow

### Task 4: Migrate Quiz Answer Confirm Button to SafeTapButton

**Files:**
- Modify: `lib/features/quiz/screens/quiz_screen.dart:521-545`

- [ ] **Step 1: Add SafeTapButton import**

Add at top of `quiz_screen.dart`:
```dart
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
```

- [ ] **Step 2: Replace confirm button with SafeTapButton**

Replace the confirm button section (lines 521-545) with:

```dart
if (_selectedAnswerIndex != null)
  Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: SafeTapButton(
      onTap: _isSubmitting ? null : () => _submitAnswer(),
      builder: (context, isLoading, onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          backgroundColor: AppColors.primary,
        ),
        child: (isLoading || _isSubmitting)
            ? AppLoadingWidget.small()
            : Text(
                context.tr('quiz_confirm_answer'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ),
  ),
```

Note: `_isSubmitting` is kept because the quiz screen uses it for other orchestration (timer pause, etc.). SafeTapButton adds debounce cooldown on top.

- [ ] **Step 3: Verify compilation**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/quiz/screens/quiz_screen.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/quiz/screens/quiz_screen.dart
git commit -m "feat: wrap quiz confirm button with SafeTapButton"
```

---

### Task 5: Migrate PowerBar Buttons to SafeTapButton

**Files:**
- Modify: `lib/features/quiz/widgets/power_bar.dart:77-163`

- [ ] **Step 1: Add imports**

Add at top of `power_bar.dart`:
```dart
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
```

- [ ] **Step 2: Replace _PowerButton GestureDetector with SafeTapButton**

Change the `_PowerButton` widget's `onTap` type from `VoidCallback` to `Future<void> Function()` and wrap with SafeTapButton:

Replace `_PowerButton` class (lines 77-163):

```dart
class _PowerButton extends StatelessWidget {
  final PowerType type;
  final int count;
  final bool hasInventory;
  final Future<void> Function() onTap;

  const _PowerButton({
    required this.type,
    required this.count,
    required this.hasInventory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;

    return SafeTapButton(
      onTap: onTap,
      builder: (context, isLoading, safeTap) => GestureDetector(
        onTap: safeTap,
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasInventory
                          ? color.withValues(alpha: 0.15)
                          : AppColors.surfaceElevated,
                      border: Border.all(
                        color: hasInventory
                            ? color.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isLoading
                          ? AppLoadingWidget.small()
                          : QIcon(
                              type.iconPath,
                              size: 22,
                              color: hasInventory ? color : Colors.grey,
                            ),
                    ),
                  ),
                  if (hasInventory && !isLoading)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Update PowerBar callback type**

In the `PowerBar` class, change `onPowerUsed` from `void Function(String)` to `Future<void> Function(String)`:

```dart
final Future<void> Function(String power)? onPowerUsed;
```

And update the `_PowerButton` creation in `build()` to pass async callback:

```dart
return _PowerButton(
  type: type,
  count: count,
  hasInventory: hasInventory && !isHintDisabled,
  onTap: isDisabled
      ? () async => _onEmptyPowerTap(context)
      : () async => onPowerUsed?.call(type.apiName),
);
```

- [ ] **Step 4: Update quiz_screen.dart callback to be async**

In `quiz_screen.dart`, ensure `_usePower` returns `Future<void>` (it likely already does). Update the PowerBar call if needed:

```dart
PowerBar(
  sessionId: sessionId,
  hasHint: question.hasHint,
  onPowerUsed: (power) async => _usePower(power),
  onSheetOpening: _onSheetOpening,
  onSheetClosed: _onSheetClosed,
),
```

- [ ] **Step 5: Add missing import for AppLoadingWidget**

Add at top of `power_bar.dart`:
```dart
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
```

- [ ] **Step 6: Verify compilation**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/quiz/`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/features/quiz/widgets/power_bar.dart lib/features/quiz/screens/quiz_screen.dart
git commit -m "feat: wrap PowerBar buttons with SafeTapButton"
```

---

### Task 6: Migrate Rescue Popup Buttons to SafeTapButton

**Files:**
- Modify: `lib/features/quiz/widgets/answer_feedback_overlay.dart:174-195,202-254`

- [ ] **Step 1: Add imports**

Add at top of `answer_feedback_overlay.dart`:
```dart
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
```

- [ ] **Step 2: Change onRescue type to async**

In `AnswerFeedbackOverlay`, change:
```dart
final Future<void> Function(String power)? onRescue;
```

- [ ] **Step 3: Update _RescueOptionTile to use SafeTapButton**

Change `onTap` type and wrap InkWell:

```dart
class _RescueOptionTile extends StatelessWidget {
  final RescuePowerOption option;
  final String label;
  final Future<void> Function() onTap;

  const _RescueOptionTile({
    required this.option,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = option.type.color;

    return SafeTapButton(
      onTap: onTap,
      builder: (context, isLoading, safeTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: safeTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
              color: color.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                QIcon(option.type.iconPath, size: 22, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                isLoading
                    ? AppLoadingWidget.small()
                    : _CostBadge(option: option),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Update _RescueOptionTile call sites to async**

In `_buildRescueCards` method, update:
```dart
if (widget.skipOption != null)
  _RescueOptionTile(
    option: widget.skipOption!,
    label: context.tr('quiz_rescue_skip'),
    onTap: () async => widget.onRescue?.call('SKIP'),
  ),
const SizedBox(height: AppSpacing.sm),
if (widget.skipAllOption != null)
  _RescueOptionTile(
    option: widget.skipAllOption!,
    label: context.tr('quiz_rescue_skip_all'),
    onTap: () async => widget.onRescue?.call('SKIP_ALL'),
  ),
```

- [ ] **Step 5: Also wrap the decline TextButton with SafeTapButton**

Replace the decline TextButton:
```dart
SafeTapButton(
  onTap: widget.onDeclineRescue != null
      ? () async => widget.onDeclineRescue!()
      : null,
  builder: (context, isLoading, safeTap) => TextButton(
    onPressed: safeTap,
    child: isLoading
        ? AppLoadingWidget.small()
        : Text(
            context.tr('quiz_rescue_decline'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
  ),
),
```

- [ ] **Step 6: Verify compilation**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/quiz/widgets/answer_feedback_overlay.dart`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/features/quiz/widgets/answer_feedback_overlay.dart
git commit -m "feat: wrap rescue popup buttons with SafeTapButton"
```

---

## Chunk 3: Critical Path Migration — Discover Flow

### Task 7: Migrate Discover Solve Button to SafeTapButton

**Files:**
- Modify: `lib/features/discover/widgets/discover_card_view.dart:40-43,70-89`

- [ ] **Step 1: Add imports**

Add at top of `discover_card_view.dart`:
```dart
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
```

- [ ] **Step 2: Wrap solve button with SafeTapButton**

Replace the `DiscoverSolveButton` section (around lines 40-43). The solve button trigger and `_navigateToQuiz` need to be connected through SafeTapButton:

```dart
SafeTapButton(
  onTap: () => _navigateToQuiz(ref),
  builder: (context, isLoading, onTap) => DiscoverSolveButton(
    label: context.tr('solve_questions'),
    onTap: onTap,
    isLoading: isLoading,
  ),
),
```

Note: `DiscoverSolveButton` may need an `isLoading` parameter added. Check the widget — if it's a simple wrapper, add the param. If it's complex, wrap at the InkWell/GestureDetector level inside it.

- [ ] **Step 3: Make _navigateToQuiz return Future<void>**

Ensure `_navigateToQuiz` signature is `Future<void>`:
```dart
Future<void> _navigateToQuiz(WidgetRef ref) async {
  // existing code...
}
```

- [ ] **Step 4: Verify compilation**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/discover/`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/features/discover/
git commit -m "feat: wrap discover solve button with SafeTapButton"
```

---

### Task 8: Migrate Discover Undo Button to SafeTapButton

**Files:**
- Modify: `lib/features/discover/widgets/discover_card_view.dart` (undo button section)

- [ ] **Step 1: Find and wrap undo button**

Locate the undo button (around line 91-104 per research) and wrap with SafeTapButton:

```dart
SafeTapButton(
  onTap: () => _handleUndo(ref),
  builder: (context, isLoading, onTap) => IconButton(
    onPressed: onTap,
    icon: isLoading
        ? AppLoadingWidget.small()
        : Icon(Icons.undo_rounded, color: theme.colorScheme.onSurfaceVariant),
  ),
),
```

- [ ] **Step 2: Verify compilation**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/discover/`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/discover/
git commit -m "feat: wrap discover undo button with SafeTapButton"
```

---

## Chunk 4: Cleanup & Debug Log Removal

### Task 9: Remove Debug Logs from Rescue Endpoint

**Files:**
- Modify: `src/services/quiz.service.ts:596-615` (in qulo-server repo)

- [ ] **Step 1: Remove debug console.logs from rescueWithSkip**

Remove the debug logging that was added during troubleshooting:

```typescript
// Remove these lines:
console.log(`[rescue] called: sessionId=...`);
console.log(`[rescue] session found: ...`);
console.log(`[rescue] lastAnswer:`, ...);
console.log(`[rescue] ALL answers for session:`, ...);
```

Also remove the debug block that queries all answers:
```typescript
// Remove:
const { data: allAnswers } = await supabase
  .from("quiz_answers")
  .select("id, question_id, is_correct, power_used")
  .eq("session_id", sessionId);
console.log(`[rescue] ALL answers for session:`, JSON.stringify(allAnswers));
```

Keep the actual error throw: `throw Errors.VALIDATION_ERROR({ rescue: "No wrong answer to rescue" });`

- [ ] **Step 2: Verify server starts**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npx tsx src/index.ts`
Expected: `[server] Running on port 3001 in development mode`

- [ ] **Step 3: Commit**

```bash
git add src/services/quiz.service.ts
git commit -m "chore: remove rescue debug logs"
```

---

### Task 10: Full Integration Smoke Test

**No files to modify — manual testing**

- [ ] **Step 1: Start backend server**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server && npx tsx src/index.ts`

- [ ] **Step 2: Hot restart Flutter app**

In Flutter terminal: press `R` for hot restart

- [ ] **Step 3: Test quiz answer flow**

1. Go to Discover → tap "Solve" button rapidly 3 times
2. Verify only 1 swipe API call is sent (check server logs)
3. Answer a question → tap confirm button rapidly
4. Verify only 1 answer API call sent
5. Verify loading spinner shows in button during submission

- [ ] **Step 4: Test power usage**

1. Tap a power button rapidly 3 times
2. Verify only 1 power request sent
3. Verify loading spinner shows in power circle during request

- [ ] **Step 5: Test rescue flow**

1. Answer wrong intentionally
2. In rescue popup, tap "Skip" rapidly
3. Verify only 1 rescue API call sent
4. Verify loading spinner shows in rescue tile

- [ ] **Step 6: Test idempotency middleware**

1. Check server logs for `Idempotency-Key` header in requests
2. Verify duplicate requests return cached response (if testable)

- [ ] **Step 7: Commit all remaining changes if any**

```bash
git add -A
git commit -m "feat: double-submit protection complete — SafeTapButton + idempotency"
```
