# Double-Submit Protection & Idempotency — Design Spec

**Date:** 2026-03-13
**Status:** Approved
**Scope:** Project-wide (Flutter + Backend)

## Problem

Users can tap buttons multiple times during async operations, causing duplicate API calls, race conditions, and broken state. Critical in quiz flow where a duplicate swipe or answer can corrupt session data.

### Current Vulnerabilities

| Location | Issue |
|----------|-------|
| PowerBar buttons | No tap guard — double-tap sends 2 power requests |
| Discover swipe/solve buttons | No loading state — double-tap sends 2 swipes |
| Discover undo button | No guard — double-undo possible |
| Backend rescue endpoint | No duplicate prevention — double-rescue both succeed |
| Backend swipe | DB constraint catches it but returns error to second request |
| Dialog confirm buttons | No protection against rapid taps |

### What Already Works

- Quiz answer: `_isSubmitting` flag + button disable
- Power purchase sheet: per-power `_buyingKey` loading state
- Match creation: DB unique constraint with error suppression
- `LoadingMixin`: used in 4 screens (passport, login, forgot password) for screen-level loading
- `AppDurations.debounce = 300ms`: defined but unused
- `PopScope(canPop: false)`: blocks back button during quiz

---

## Design

### 1. Flutter — SafeTapButton Widget

**File:** `lib/core/widgets/safe_tap_button.dart`

A universal widget that wraps any async button action with automatic debounce, loading state, and disable behavior.

```dart
SafeTapButton(
  onTap: () async => await api.call(),
  debounceDuration: AppDurations.debounce,  // default 300ms from constants
  builder: (context, isLoading, onTap) =>
    ElevatedButton(
      onPressed: onTap,  // null when loading or debouncing
      child: isLoading ? AppLoadingWidget.small() : Text('Save'),
    ),
)
```

**Behavior:**
1. User taps → `_isRunning = true` → builder receives `onTap: null` + `isLoading: true`
2. Future completes → cooldown of `debounceDuration` starts (default `AppDurations.debounce`)
3. Cooldown ends → `_isRunning = false` → builder receives active `onTap` again
4. If widget disposes during async op → callback result ignored (`mounted` check)
5. If `onTap` is null (passed from parent) → builder receives `onTap: null` always (disabled state)

**Convenience constructors:**
- `SafeTapButton.icon(...)` — for IconButton use cases
- `SafeTapButton.text(...)` — for TextButton use cases

**Loading display:** In-button spinner via builder pattern. Button text replaced with `AppLoadingWidget.small()`. Screen remains interactive.

### 2. Flutter — Dio Idempotency Interceptor

**File:** `lib/core/network/interceptors/idempotency_interceptor.dart`

Automatically adds `Idempotency-Key` header to every mutation request.

```dart
class IdempotencyInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method)) {
      options.headers['Idempotency-Key'] ??= const Uuid().v4();
    }
    handler.next(options);
  }
}
```

**Rules:**
- `POST`, `PUT`, `PATCH`, `DELETE` — `GET` is naturally idempotent. `PUT` included because this app's PUT endpoints have side effects (not pure replacements)
- Uses `??=` so if a key is already set (e.g., retry scenario), it's preserved
- UUID v4 for uniqueness
- Registered in Dio instance setup alongside existing interceptors (auth, logging)

### 3. Backend — Idempotency Middleware

**File:** `src/middleware/idempotency.ts`

Server-side middleware that caches responses keyed by `Idempotency-Key` + `userId`.

**Flow:**
```
Request arrives with Idempotency-Key header
  → Key + userId lookup in cache
    → HIT: return cached { status, body } immediately (skip handler)
    → MISS: proceed to handler, cache response on completion
  → No header: proceed normally (backward compatible)
```

**Cache implementation:**
- In-memory `Map<string, { status: number, body: any, timestamp: number }>`
- Composite key: `${userId}:${idempotencyKey}`
- TTL: 5 minutes
- Cleanup: `setInterval` every 60s removes expired entries
- Future migration path: Redis (when needed for multi-instance)

**Applied to:** All `POST`, `PUT`, `PATCH`, `DELETE` routes via `app.use()` (before route handlers).

**Caching policy:** Only 2xx responses are cached. Error responses (4xx, 5xx) are NOT cached — the same idempotency key can be retried after an error. This follows the Stripe standard.

**Edge cases:**
- Concurrent identical requests: First request sets a "processing" flag in cache, second request returns 409 Conflict. `SafeTapButton` debounce makes this practically unreachable — 409 is a safety net.
- No auth (public routes): Key alone without userId (rare in this app)

### 4. Backend — Rescue Duplicate Safety

The rescue endpoint already has implicit protection: after successful rescue, the wrong answer is updated to `is_correct: true`. A second rescue call finds no wrong answer → returns 400.

With idempotency middleware, the second call returns the cached success response instead of 400. This is the desired behavior.

### 5. Migration Strategy

**Phase 1 — Infrastructure (no UI changes):**
- Create `SafeTapButton` widget
- Create `IdempotencyInterceptor`
- Create idempotency middleware on backend
- Register interceptor in Dio setup
- Apply middleware to Express app

**Phase 2 — Critical path migration:**
- Quiz answer confirm button → `SafeTapButton`
- Discover solve button → `SafeTapButton` (swipe gesture itself is protected by card removal animation — once card animates away, gesture target is gone. The "Solve" button that triggers quiz navigation is the actual vulnerability)
- PowerBar power buttons → `SafeTapButton`
- Rescue popup SKIP/SKIP_ALL buttons → `SafeTapButton`
- Quiz exit confirm dialog buttons → `SafeTapButton`
- Discover undo button → `SafeTapButton`

**Phase 3 — Remaining screens (gradual):**
- Profile save buttons
- Chat send button
- Settings save actions
- Diamond purchase buttons (already has `_buyingKey`, migrate for consistency)
- Any other async action buttons

**`LoadingMixin` stays** — used for screen-level orchestration (full-page loading via `AppScaffold(isLoading:)`). `SafeTapButton` handles button-level protection. They complement each other.

---

## Success Criteria

1. No duplicate API calls from rapid button taps anywhere in the app
2. User sees loading feedback on every async button action
3. Backend returns cached response for duplicate idempotency keys
4. Zero breaking changes to existing behavior
5. New buttons default to safe behavior (developer can't forget protection)

## Out of Scope

- Navigation guards beyond existing `PopScope` (YAGNI)
- Full-screen overlay blocking (too aggressive for UX)
- Redis cache (in-memory sufficient for single-instance Railway deployment)
- Retry logic with idempotency key preservation (future enhancement)
