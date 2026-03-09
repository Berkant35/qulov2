# Referral System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Kullanıcıların arkadaşlarını davet edip, arkadaş %60 profil tamamladığında her iki tarafa 25 mor elmas kazandıran referral sistemi.

**Architecture:** Yeni `referrals` tablosu + `users.referral_code` kolonu. Backend'de `referral.service.ts` ödül mantığını yönetir. Kayıt sırasında opsiyonel referral kodu kabul edilir, profil güncellemede %60 eşiği kontrol edilerek otomatik ödül tetiklenir. Flutter'da model/repo/provider/UI katmanları eklenir.

**Tech Stack:** Supabase PostgreSQL, Node.js/Express/Zod, Flutter/Riverpod/Retrofit, share_plus

**Design Doc:** `docs/plans/2026-03-09-referral-system-design.md`

---

## Task 1: Database Migration

**Files:**
- Create: `supabase/migrations/013_referral_system.sql`

**Step 1: Write migration SQL**

```sql
-- Migration 013: Referral System
-- Arkadaşını getir, mor elmas kap

-- Referral code kolonu (users tablosuna)
ALTER TABLE users ADD COLUMN referral_code VARCHAR(8) UNIQUE;

-- Mevcut kullanıcılara referral code generate et
UPDATE users
SET referral_code = upper(substr(md5(random()::text || id::text), 1, 8))
WHERE referral_code IS NULL;

-- NOT NULL constraint ekle (mevcut kullanıcılar güncellendikten sonra)
ALTER TABLE users ALTER COLUMN referral_code SET NOT NULL;

-- Referrals tablosu
CREATE TABLE referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  referee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(10) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed')),
  referrer_rewarded BOOLEAN NOT NULL DEFAULT false,
  referee_rewarded BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  CONSTRAINT uq_referee UNIQUE (referee_id),
  CONSTRAINT chk_no_self_referral CHECK (referrer_id != referee_id)
);

-- Indexler
CREATE INDEX idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX idx_referrals_status ON referrals(status);
CREATE INDEX idx_users_referral_code ON users(referral_code);
```

**Step 2: Supabase SQL Editor'da migration'ı çalıştır**

Manuel olarak Supabase Dashboard → SQL Editor'a yapıştır ve çalıştır.

**Step 3: Commit**

```bash
git add supabase/migrations/013_referral_system.sql
git commit -m "feat: add migration 013 — referral system table and users.referral_code"
```

---

## Task 2: Backend Error Tanımları

**Files:**
- Modify: `server/src/utils/errors.ts`

**Step 1: Referral error'larını ekle**

`Errors` objesine şu alanları ekle:

```typescript
INVALID_REFERRAL_CODE: () => new AppError("INVALID_REFERRAL_CODE", 404, "Referral code not found"),
REFERRAL_LIMIT_REACHED: () => new AppError("REFERRAL_LIMIT_REACHED", 409, "Referral limit reached (max 10)"),
SELF_REFERRAL: () => new AppError("SELF_REFERRAL", 400, "Cannot refer yourself"),
ALREADY_REFERRED: () => new AppError("ALREADY_REFERRED", 409, "User already has a referrer"),
```

**Step 2: Commit**

```bash
git add server/src/utils/errors.ts
git commit -m "feat: add referral error types"
```

---

## Task 3: Backend Referral Service

**Files:**
- Create: `server/src/services/referral.service.ts`

**Step 1: Test dosyasını oluştur**

Create: `server/src/__tests__/referral.service.test.ts`

```typescript
import { describe, it, expect, vi, beforeEach } from "vitest";

// Test: generateCode 8 karakter, uppercase alphanumeric üretmeli
// Test: applyReferralCode geçerli kod ile pending referral oluşturmalı
// Test: applyReferralCode geçersiz kod ile hata fırlatmalı
// Test: applyReferralCode kendi kodunu kullanınca hata fırlatmalı
// Test: checkAndReward profil %60 altında ise bir şey yapmamalı
// Test: checkAndReward profil %60+ ve pending referral varsa ödül vermeli
// Test: checkAndReward referrer 10 limite ulaşmışsa sadece referee'ye ödül vermeli
// Test: getStats doğru istatistikleri dönmeli
```

Detaylı testler:

```typescript
import { describe, it, expect, vi, beforeEach } from "vitest";

// Mock supabase
const mockSupabase = {
  from: vi.fn().mockReturnThis(),
  select: vi.fn().mockReturnThis(),
  insert: vi.fn().mockReturnThis(),
  update: vi.fn().mockReturnThis(),
  eq: vi.fn().mockReturnThis(),
  single: vi.fn(),
  maybeSingle: vi.fn(),
};

vi.mock("../lib/supabase.js", () => ({
  supabase: mockSupabase,
}));

// Mock diamond service
const mockDiamondService = {
  addPurple: vi.fn().mockResolvedValue({ purple: 25 }),
};

vi.mock("./diamond.service.js", () => ({
  diamondService: mockDiamondService,
}));

import { referralService } from "./referral.service.js";

describe("ReferralService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("generateCode", () => {
    it("should generate 8 char uppercase alphanumeric code", () => {
      const code = referralService.generateCode();
      expect(code).toMatch(/^[A-HJ-NP-Z2-9]{8}$/);
      expect(code.length).toBe(8);
    });

    it("should not contain ambiguous characters (I, O, 0, 1)", () => {
      // Generate many codes to increase confidence
      for (let i = 0; i < 100; i++) {
        const code = referralService.generateCode();
        expect(code).not.toMatch(/[IO01]/);
      }
    });
  });

  describe("getStats", () => {
    it("should return correct referral stats", async () => {
      mockSupabase.select.mockReturnValueOnce({
        eq: vi.fn().mockResolvedValue({
          data: [
            { status: "pending" },
            { status: "completed" },
            { status: "completed" },
          ],
          error: null,
        }),
      });

      const stats = await referralService.getStats("user-1");
      expect(stats).toEqual({
        total: 3,
        pending: 1,
        completed: 2,
        remaining: 8, // 10 - 2 completed
      });
    });
  });
});
```

**Step 2: Testi çalıştır, fail ettiğini doğrula**

```bash
cd server && npm test -- --run referral.service.test
```

Expected: FAIL — `referral.service.js` bulunamaz.

**Step 3: Service'i implement et**

```typescript
import { supabase } from "../lib/supabase.js";
import { diamondService } from "./diamond.service.js";
import { Errors } from "../utils/errors.js";

const REFERRAL_REWARD = 25;
const MAX_COMPLETED_REFERRALS = 10;
const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // I,O,0,1 hariç

class ReferralService {
  generateCode(): string {
    let code = "";
    for (let i = 0; i < 8; i++) {
      code += CODE_CHARS.charAt(Math.floor(Math.random() * CODE_CHARS.length));
    }
    return code;
  }

  async generateUniqueCode(): Promise<string> {
    let attempts = 0;
    while (attempts < 10) {
      const code = this.generateCode();
      const { data } = await supabase
        .from("users")
        .select("id")
        .eq("referral_code", code)
        .maybeSingle();
      if (!data) return code;
      attempts++;
    }
    // Fallback: daha uzun kod
    return this.generateCode() + this.generateCode().slice(0, 2);
  }

  async applyReferralCode(refereeId: string, code: string): Promise<void> {
    // Kodu bul
    const { data: referrer } = await supabase
      .from("users")
      .select("id")
      .eq("referral_code", code.toUpperCase())
      .maybeSingle();

    if (!referrer) throw Errors.INVALID_REFERRAL_CODE();
    if (referrer.id === refereeId) throw Errors.SELF_REFERRAL();

    // Zaten davet edilmiş mi?
    const { data: existing } = await supabase
      .from("referrals")
      .select("id")
      .eq("referee_id", refereeId)
      .maybeSingle();

    if (existing) throw Errors.ALREADY_REFERRED();

    // Pending referral oluştur
    const { error } = await supabase.from("referrals").insert({
      referrer_id: referrer.id,
      referee_id: refereeId,
      status: "pending",
    });

    if (error) throw error;
  }

  async checkAndReward(userId: string, profileCompletion: number): Promise<void> {
    if (profileCompletion < 60) return;

    // Bu kullanıcının pending referral'ı var mı?
    const { data: referral } = await supabase
      .from("referrals")
      .select("*")
      .eq("referee_id", userId)
      .eq("status", "pending")
      .maybeSingle();

    if (!referral) return;

    // Status → completed
    await supabase
      .from("referrals")
      .update({
        status: "completed",
        completed_at: new Date().toISOString(),
      })
      .eq("id", referral.id);

    // Referee'ye ödül (her zaman)
    await diamondService.addPurple(userId, REFERRAL_REWARD, "referral_reward", referral.id);
    await supabase
      .from("referrals")
      .update({ referee_rewarded: true })
      .eq("id", referral.id);

    // Referrer limit kontrolü
    const { data: completedReferrals } = await supabase
      .from("referrals")
      .select("id")
      .eq("referrer_id", referral.referrer_id)
      .eq("status", "completed");

    const completedCount = completedReferrals?.length ?? 0;

    if (completedCount <= MAX_COMPLETED_REFERRALS) {
      await diamondService.addPurple(
        referral.referrer_id,
        REFERRAL_REWARD,
        "referral_reward",
        referral.id
      );
      await supabase
        .from("referrals")
        .update({ referrer_rewarded: true })
        .eq("id", referral.id);
    }
  }

  async getStats(userId: string): Promise<{
    total: number;
    pending: number;
    completed: number;
    remaining: number;
  }> {
    const { data } = await supabase
      .from("referrals")
      .select("status")
      .eq("referrer_id", userId);

    const referrals = data ?? [];
    const completed = referrals.filter((r) => r.status === "completed").length;
    const pending = referrals.filter((r) => r.status === "pending").length;

    return {
      total: referrals.length,
      pending,
      completed,
      remaining: Math.max(0, MAX_COMPLETED_REFERRALS - completed),
    };
  }

  async getHistory(userId: string): Promise<
    Array<{
      id: string;
      refereeName: string;
      status: string;
      createdAt: string;
      completedAt: string | null;
    }>
  > {
    const { data } = await supabase
      .from("referrals")
      .select("id, status, created_at, completed_at, referee:referee_id(name, surname)")
      .eq("referrer_id", userId)
      .order("created_at", { ascending: false });

    return (data ?? []).map((r: any) => ({
      id: r.id,
      refereeName: `${r.referee?.name ?? ""} ${r.referee?.surname ?? ""}`.trim(),
      status: r.status,
      createdAt: r.created_at,
      completedAt: r.completed_at,
    }));
  }

  async validateCode(code: string): Promise<{ valid: boolean; referrerName?: string }> {
    const { data } = await supabase
      .from("users")
      .select("name")
      .eq("referral_code", code.toUpperCase())
      .maybeSingle();

    if (!data) return { valid: false };
    return { valid: true, referrerName: data.name };
  }
}

export const referralService = new ReferralService();
```

**Step 4: Testleri çalıştır, geçtiğini doğrula**

```bash
cd server && npm test -- --run referral.service.test
```

Expected: PASS

**Step 5: Commit**

```bash
git add server/src/services/referral.service.ts server/src/__tests__/referral.service.test.ts
git commit -m "feat: add referral service with reward logic"
```

---

## Task 4: Backend Referral Validator

**Files:**
- Create: `server/src/validators/referral.validator.ts`

**Step 1: Validator'ları oluştur**

```typescript
import { z } from "zod";

export const validateCodeSchema = z.object({
  code: z.string().min(1).max(10).transform((v) => v.toUpperCase()),
});

export type ValidateCodeInput = z.infer<typeof validateCodeSchema>;
```

**Step 2: Commit**

```bash
git add server/src/validators/referral.validator.ts
git commit -m "feat: add referral validators"
```

---

## Task 5: Backend Referral Routes

**Files:**
- Create: `server/src/routes/referral.routes.ts`
- Modify: `server/src/index.ts` (route registration)

**Step 1: Route dosyasını oluştur**

```typescript
import { Router, Request, Response } from "express";
import { authMiddleware } from "../middleware/auth.js";
import { generalLimiter } from "../middleware/rateLimit.js";
import { validate } from "../middleware/validate.js";
import { validateCodeSchema } from "../validators/referral.validator.js";
import { referralService } from "../services/referral.service.js";

const router = Router();

router.use(authMiddleware);
router.use(generalLimiter);

// GET /referrals/my-code
router.get("/my-code", async (req: Request, res: Response) => {
  const { data } = await supabase
    .from("users")
    .select("referral_code")
    .eq("id", req.user!.userId)
    .single();

  res.json({ code: data?.referral_code });
});

// GET /referrals/stats
router.get("/stats", async (req: Request, res: Response) => {
  const stats = await referralService.getStats(req.user!.userId);
  res.json(stats);
});

// GET /referrals/history
router.get("/history", async (req: Request, res: Response) => {
  const history = await referralService.getHistory(req.user!.userId);
  res.json(history);
});

// POST /referrals/validate-code
router.post(
  "/validate-code",
  validate(validateCodeSchema),
  async (req: Request, res: Response) => {
    const { code } = req.body;
    const result = await referralService.validateCode(code);
    res.json(result);
  }
);

export default router;
```

**Step 2: `server/src/index.ts`'e route'u kaydet**

Mevcut route import'larının altına ekle:

```typescript
import referralRoutes from "./routes/referral.routes.js";
```

Mevcut `app.use` satırlarının arasına ekle:

```typescript
app.use("/api/v1/referrals", referralRoutes);
```

**Step 3: Route dosyasına supabase import'u ekle**

```typescript
import { supabase } from "../lib/supabase.js";
```

**Step 4: Commit**

```bash
git add server/src/routes/referral.routes.ts server/src/index.ts
git commit -m "feat: add referral API routes"
```

---

## Task 6: Backend — Auth Register'a Referral Entegrasyonu

**Files:**
- Modify: `server/src/validators/auth.validator.ts`
- Modify: `server/src/services/auth.service.ts`

**Step 1: Register schema'ya referral_code ekle**

`server/src/validators/auth.validator.ts` dosyasında `registerSchema`'ya ekle:

```typescript
referral_code: z.string().min(1).max(10).optional(),
```

**Step 2: Auth service register()'a referral mantığı ekle**

`server/src/services/auth.service.ts` dosyasında:

1. Import ekle:
```typescript
import { referralService } from "./referral.service.js";
```

2. `register()` method'unda kullanıcı insert'inden sonra (userId mevcut olduğunda):

```typescript
// Referral code generate et
const referralCode = await referralService.generateUniqueCode();
await supabase
  .from("users")
  .update({ referral_code: referralCode })
  .eq("id", userId);

// Eğer referral code gönderilmişse, pending referral oluştur
if (data.referral_code) {
  try {
    await referralService.applyReferralCode(userId, data.referral_code);
  } catch {
    // Geçersiz kod kayıt akışını engellemez
  }
}
```

**Step 3: Commit**

```bash
git add server/src/validators/auth.validator.ts server/src/services/auth.service.ts
git commit -m "feat: integrate referral code into registration flow"
```

---

## Task 7: Backend — Profil Update'e Reward Tetikleme

**Files:**
- Modify: `server/src/services/user.service.ts` veya profil güncelleme endpoint'i

**Step 1: Profil güncelleme handler'ında referral check ekle**

Mevcut `PUT /users/me` handler'ında profil tamamlama oranı hesaplandıktan sonra:

```typescript
import { referralService } from "./referral.service.js";

// Profil güncelleme sonrası (profileCompletion hesaplandıktan sonra)
await referralService.checkAndReward(userId, profileCompletion);
```

**Step 2: Commit**

```bash
git add server/src/services/user.service.ts
git commit -m "feat: trigger referral reward on profile completion >= 60%"
```

---

## Task 8: Flutter — Referral Model

**Files:**
- Create: `lib/data/models/referral_model.dart`

**Step 1: Model'leri oluştur**

```dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral_model.g.dart';

@JsonSerializable()
class ReferralStats extends Equatable {
  final int total;
  final int pending;
  final int completed;
  final int remaining;

  const ReferralStats({
    required this.total,
    required this.pending,
    required this.completed,
    required this.remaining,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) =>
      _$ReferralStatsFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralStatsToJson(this);

  @override
  List<Object?> get props => [total, pending, completed, remaining];
}

@JsonSerializable()
class ReferralItem extends Equatable {
  final String id;
  @JsonKey(name: 'refereeName')
  final String refereeName;
  final String status;
  @JsonKey(name: 'createdAt')
  final String createdAt;
  @JsonKey(name: 'completedAt')
  final String? completedAt;

  const ReferralItem({
    required this.id,
    required this.refereeName,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory ReferralItem.fromJson(Map<String, dynamic> json) =>
      _$ReferralItemFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralItemToJson(this);

  @override
  List<Object?> get props => [id, refereeName, status, createdAt, completedAt];
}

@JsonSerializable()
class ValidateCodeResponse extends Equatable {
  final bool valid;
  @JsonKey(name: 'referrerName')
  final String? referrerName;

  const ValidateCodeResponse({
    required this.valid,
    this.referrerName,
  });

  factory ValidateCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidateCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ValidateCodeResponseToJson(this);

  @override
  List<Object?> get props => [valid, referrerName];
}
```

**Step 2: build_runner çalıştır**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/data/models/referral_model.dart lib/data/models/referral_model.g.dart
git commit -m "feat: add referral models"
```

---

## Task 9: Flutter — Referral Network Service

**Files:**
- Create: `lib/core/network/services/referral_service.dart`

**Step 1: Retrofit service oluştur**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/referral_model.dart';

part 'referral_service.g.dart';

@RestApi()
abstract class ReferralService {
  factory ReferralService(Dio dio) = _ReferralService;

  @GET('/referrals/my-code')
  Future<Map<String, dynamic>> getMyCode();

  @GET('/referrals/stats')
  Future<ReferralStats> getStats();

  @GET('/referrals/history')
  Future<List<ReferralItem>> getHistory();

  @POST('/referrals/validate-code')
  Future<ValidateCodeResponse> validateCode(@Body() Map<String, dynamic> body);
}
```

**Step 2: build_runner çalıştır**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/core/network/services/referral_service.dart lib/core/network/services/referral_service.g.dart
git commit -m "feat: add referral network service"
```

---

## Task 10: Flutter — Referral Repository

**Files:**
- Create: `lib/data/repositories/referral_repository.dart`

**Step 1: Repository oluştur**

```dart
import 'package:dio/dio.dart';
import '../../core/network/services/referral_service.dart';
import '../../core/utils/result.dart';
import '../models/referral_model.dart';

abstract class IReferralRepository {
  Future<Result<String>> getMyCode();
  Future<Result<ReferralStats>> getStats();
  Future<Result<List<ReferralItem>>> getHistory();
  Future<Result<ValidateCodeResponse>> validateCode(String code);
}

class ReferralRepository implements IReferralRepository {
  final ReferralService _service;

  ReferralRepository(this._service);

  @override
  Future<Result<String>> getMyCode() async {
    try {
      final response = await _service.getMyCode();
      return Success(response['code'] as String);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<ReferralStats>> getStats() async {
    try {
      final response = await _service.getStats();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<List<ReferralItem>>> getHistory() async {
    try {
      final response = await _service.getHistory();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<ValidateCodeResponse>> validateCode(String code) async {
    try {
      final response = await _service.validateCode({'code': code});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 2: Commit**

```bash
git add lib/data/repositories/referral_repository.dart
git commit -m "feat: add referral repository"
```

---

## Task 11: Flutter — Referral Provider

**Files:**
- Create: `lib/providers/referral_provider.dart`
- Modify: `lib/providers/api_provider.dart` (service + repo provider ekle)

**Step 1: api_provider.dart'a referral provider'ları ekle**

```dart
import '../core/network/services/referral_service.dart';
import '../data/repositories/referral_repository.dart';

final referralServiceProvider = Provider<ReferralService>((ref) {
  final dio = ref.read(dioProvider);
  return ReferralService(dio);
});

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final service = ref.read(referralServiceProvider);
  return ReferralRepository(service);
});
```

**Step 2: Referral state ve notifier oluştur**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/referral_model.dart';
import '../data/repositories/referral_repository.dart';
import 'api_provider.dart';

class ReferralState {
  final String? code;
  final ReferralStats? stats;
  final List<ReferralItem> history;

  const ReferralState({this.code, this.stats, this.history = const []});

  ReferralState copyWith({
    String? code,
    ReferralStats? stats,
    List<ReferralItem>? history,
  }) {
    return ReferralState(
      code: code ?? this.code,
      stats: stats ?? this.stats,
      history: history ?? this.history,
    );
  }
}

class ReferralNotifier extends AsyncNotifier<ReferralState> {
  @override
  Future<ReferralState> build() async {
    return const ReferralState();
  }

  Future<void> fetchAll() async {
    state = const AsyncLoading();
    final repo = ref.read(referralRepositoryProvider);

    final codeResult = await repo.getMyCode();
    final statsResult = await repo.getStats();
    final historyResult = await repo.getHistory();

    state = AsyncData(ReferralState(
      code: codeResult.when(success: (c) => c, failure: (_) => null),
      stats: statsResult.when(success: (s) => s, failure: (_) => null),
      history: historyResult.when(success: (h) => h, failure: (_) => []),
    ));
  }

  Future<ValidateCodeResponse?> validateCode(String code) async {
    final repo = ref.read(referralRepositoryProvider);
    final result = await repo.validateCode(code);
    return result.when(
      success: (r) => r,
      failure: (_) => null,
    );
  }
}

final referralProvider =
    AsyncNotifierProvider<ReferralNotifier, ReferralState>(ReferralNotifier.new);
```

**Step 3: Commit**

```bash
git add lib/providers/referral_provider.dart lib/providers/api_provider.dart
git commit -m "feat: add referral provider and state management"
```

---

## Task 12: Flutter — Referral Invite Card Widget

**Files:**
- Create: `lib/core/widgets/referral_invite_card.dart`

**Step 1: Ortak widget oluştur**

Elmas ekranında ve profil ekranında kullanılacak paylaşım kartı. Referral kodu gösterimi, kopyala butonu, paylaş butonu ve ilerleme göstergesi içerir.

- Kart tema renklerinden mor gradient arka plan
- Referral kodu büyük fontla ortada
- "Kopyala" ve "Paylaş" butonları yan yana
- Alt kısımda "3/10 davet kullanıldı" progress bar
- `compact` parametresi ile profil ekranı için küçük versiyon

**Step 2: Commit**

```bash
git add lib/core/widgets/referral_invite_card.dart
git commit -m "feat: add referral invite card widget"
```

---

## Task 13: Flutter — Elmas Ekranına Referral Bölümü

**Files:**
- Modify: `lib/features/diamonds/screens/diamonds_screen.dart`

**Step 1: Referral kartını elmas ekranına ekle**

Purchase grid'in üstüne `ReferralInviteCard` widget'ını tam boyutlu ekle. `referralProvider`'ı watch et.

**Step 2: Commit**

```bash
git add lib/features/diamonds/screens/diamonds_screen.dart
git commit -m "feat: add referral section to diamonds screen"
```

---

## Task 14: Flutter — Profil Ekranına Referral Banner

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`

**Step 1: Küçük referral banner ekle**

Subscription badge'den sonra `ReferralInviteCard(compact: true)` ekle. Tıklandığında elmas ekranına yönlendir (`ref.read(navigationServiceProvider).go('/diamonds')`).

**Step 2: Commit**

```bash
git add lib/features/profile/screens/profile_screen.dart
git commit -m "feat: add referral banner to profile screen"
```

---

## Task 15: Flutter — Kayıt Akışına Referral Code Input

**Files:**
- Modify: `lib/features/auth/screens/register_screen.dart`

**Step 1: Referral code input ekle**

Son adımda (terms/email adımında) opsiyonel "Davet kodun var mı?" text field'ı ekle. Değer varsa register payload'ına `referral_code` olarak gönder.

**Step 2: Deep link'ten gelen referral code'u otomatik doldur**

Eğer uygulama `qulo.app/invite/{code}` deep link'i ile açılmışsa, kod otomatik olarak bu alana yazılır.

**Step 3: Commit**

```bash
git add lib/features/auth/screens/register_screen.dart
git commit -m "feat: add optional referral code input to registration"
```

---

## Task 16: Flutter — User Model'e referral_code Eklenmesi

**Files:**
- Modify: `lib/data/models/user_model.dart`

**Step 1: User model'e referral_code alanı ekle**

```dart
@JsonKey(name: 'referral_code')
final String? referralCode;
```

Constructor'a, copyWith'e, props'a ve fromJson/toJson'a ekle.

**Step 2: build_runner çalıştır**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/data/models/user_model.dart lib/data/models/user_model.g.dart
git commit -m "feat: add referral_code to user model"
```

---

## Task 17: Deep Link Desteği

**Files:**
- Modify: Mevcut deep link handler (GoRouter redirect veya initial link handler)

**Step 1: `qulo.app/invite/{code}` route'unu tanımla**

GoRouter'da `/invite/:code` path'ini ekle. Bu path register ekranına yönlendirsin ve `code` query parametresi olarak geçsin.

**Step 2: Firebase Dynamic Links veya Universal Links konfigürasyonu**

iOS: `apple-app-site-association` dosyası
Android: `assetlinks.json` dosyası

**Step 3: Commit**

```bash
git add lib/routing/
git commit -m "feat: add deep link support for referral invites"
```

---

## Task 18: Paylaşım Entegrasyonu

**Files:**
- Modify: `lib/core/widgets/referral_invite_card.dart` (share_plus entegrasyonu)

**Step 1: share_plus paketini kontrol et / ekle**

```bash
flutter pub add share_plus
```

**Step 2: Paylaşım mesajı oluştur**

```dart
import 'package:share_plus/share_plus.dart';

Future<void> _shareReferralCode(String code) async {
  final message = "Qulo'ya katıl! Davet kodumu kullan, ikimize de 25 mor elmas hediye: $code\nhttps://qulo.app/invite/$code";
  await Share.share(message);
}
```

**Step 3: Commit**

```bash
git add lib/core/widgets/referral_invite_card.dart pubspec.yaml pubspec.lock
git commit -m "feat: add share functionality for referral code"
```

---

## Task 19: End-to-End Test

**Step 1: Backend API'yi test et**

```bash
cd server && npm test -- --run referral
```

**Step 2: Flutter analyze**

```bash
flutter analyze
```

**Step 3: Manuel test senaryoları**

1. Yeni kullanıcı kayıt ol → referral_code otomatik oluşturuldu mu?
2. Başka kullanıcı bu kodu ile kayıt ol → referrals tablosunda pending kayıt var mı?
3. İkinci kullanıcı profilini %60 tamamla → iki tarafa da 25 mor elmas verildi mi?
4. Referral kodu kopyala/paylaş çalışıyor mu?
5. Geçersiz kod girince hata mesajı gösteriliyor mu?
6. 10 limit'e ulaşınca referrer ödül almıyor mu?

**Step 4: Commit**

```bash
git add .
git commit -m "test: verify referral system end-to-end"
```
