# Exchange Center (Dönüşüm Merkezi) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Yeşil→mor elmas dönüşümü (3:1), power envanter sistemi, COPY→ORACLE dönüşümü (%70 accuracy) ve Dönüşüm Merkezi ekranı.

**Architecture:** Backend'de yeni exchange service + controller + routes. Quiz service'e envanter kontrolü eklenir. COPY power'ı ORACLE olarak yeniden adlandırılır ve %70 doğruluk mekanizması eklenir. Flutter'da yeni exchange feature modülü + merkezi PowerIcon widget'ı.

**Tech Stack:** Node.js/Express/TypeScript (backend), Flutter/Riverpod (mobile), Supabase PostgreSQL (DB), Zod (validation), Retrofit (API client), json_serializable (models)

---

## Task 1: Database Migration (013)

**Files:**
- Create: `supabase/migrations/013_exchange_center.sql`

**Step 1: Write migration SQL**

```sql
-- 013_exchange_center.sql
-- Exchange Center: power inventory, COPY→ORACLE, green→purple conversion

-- 1. user_power_inventory tablosu
CREATE TABLE user_power_inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  power_name TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0 CHECK (count >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, power_name)
);

CREATE INDEX idx_user_power_inventory_user ON user_power_inventory(user_id);

-- 2. power_purchase_transactions tablosu
CREATE TABLE power_purchase_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  power_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  diamond_type diamond_type NOT NULL,
  total_cost INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_power_purchase_tx_user ON power_purchase_transactions(user_id);

-- 3. powers tablosuna yeni kolonlar
ALTER TABLE powers ADD COLUMN green_cost INTEGER NOT NULL DEFAULT 0;
ALTER TABLE powers ADD COLUMN purple_cost INTEGER NOT NULL DEFAULT 0;
ALTER TABLE powers ADD COLUMN accuracy_rate DECIMAL DEFAULT NULL;

-- 4. COPY → ORACLE dönüşümü
UPDATE powers SET name = 'ORACLE', base_cost = 5, accuracy_rate = 0.70,
  description = 'Oracle suggests an answer with 70% accuracy'
  WHERE name = 'COPY';

-- 5. green_cost ve purple_cost varsayılan değerleri (base_cost ile aynı, yeşil 3x)
UPDATE powers SET purple_cost = base_cost, green_cost = base_cost * 3;
```

**Step 2: Commit**

```bash
git add supabase/migrations/013_exchange_center.sql
git commit -m "feat(db): add exchange center migration — power inventory, ORACLE, conversion"
```

---

## Task 2: Backend Types — PowerName Update

**Files:**
- Modify: `server/src/types/index.ts`

**Step 1: Update PowerName type — replace COPY with ORACLE**

In `server/src/types/index.ts`, change the PowerName type:

```typescript
export type PowerName =
  | "ORACLE"
  | "HALF"
  | "SKIP"
  | "SKIP_ALL"
  | "TIME_EXTEND"
  | "HINT";
```

**Step 2: Add exchange-related constants**

In `server/src/types/index.ts`, add after existing constants:

```typescript
export const GREEN_TO_PURPLE_RATIO = 3;
```

**Step 3: Commit**

```bash
git add server/src/types/index.ts
git commit -m "feat(types): rename COPY to ORACLE, add conversion ratio constant"
```

---

## Task 3: Backend — Exchange Validator

**Files:**
- Create: `server/src/validators/exchange.validator.ts`

**Step 1: Write validator**

```typescript
import { z } from "zod";

export const convertSchema = z.object({
  green_amount: z.number().int().min(3).refine((v) => v % 3 === 0, {
    message: "green_amount must be a multiple of 3",
  }),
});

export const buyPowerSchema = z.object({
  power_name: z.enum(["ORACLE", "HALF", "SKIP", "SKIP_ALL", "TIME_EXTEND", "HINT"]),
  diamond_type: z.enum(["GREEN", "PURPLE"]),
  quantity: z.number().int().min(1).max(50),
});

export type ConvertInput = z.infer<typeof convertSchema>;
export type BuyPowerInput = z.infer<typeof buyPowerSchema>;
```

**Step 2: Commit**

```bash
git add server/src/validators/exchange.validator.ts
git commit -m "feat(validator): add exchange center validation schemas"
```

---

## Task 4: Backend — Exchange Service

**Files:**
- Create: `server/src/services/exchange.service.ts`

**Step 1: Write exchange service**

```typescript
import { supabase } from "../config/supabase.js";
import { diamondService } from "./diamond.service.js";
import { Errors } from "../utils/errors.js";
import { GREEN_TO_PURPLE_RATIO } from "../types/index.js";

class ExchangeService {
  /**
   * Yeşil elmasları mor elmaslara dönüştür (3:1 oran)
   */
  async convertGreenToPurple(userId: string, greenAmount: number) {
    if (greenAmount % GREEN_TO_PURPLE_RATIO !== 0) {
      throw Errors.VALIDATION_ERROR({ green_amount: ["Must be a multiple of 3"] });
    }

    const purpleAmount = greenAmount / GREEN_TO_PURPLE_RATIO;

    // Yeşil elmas harca
    await diamondService.spendGreen(
      userId,
      greenAmount,
      "GREEN_TO_PURPLE_CONVERT",
    );

    // Mor elmas ekle
    const result = await diamondService.addPurple(
      userId,
      purpleAmount,
      "GREEN_TO_PURPLE_CONVERT",
    );

    // Güncel bakiyeyi getir
    const balance = await diamondService.getBalance(userId);

    return {
      purple_received: purpleAmount,
      new_balance: balance,
    };
  }

  /**
   * Power hakkı satın al (mor veya yeşil elmasla)
   */
  async buyPower(
    userId: string,
    powerName: string,
    diamondType: "GREEN" | "PURPLE",
    quantity: number,
  ) {
    // Power bilgisini getir
    const { data: power, error: powerError } = await supabase
      .from("powers")
      .select("*")
      .eq("name", powerName)
      .eq("is_active", true)
      .single();

    if (powerError || !power) {
      throw Errors.NOT_FOUND("Power");
    }

    const costPerUnit = diamondType === "GREEN" ? power.green_cost : power.purple_cost;
    if (costPerUnit <= 0) {
      throw Errors.VALIDATION_ERROR({ diamond_type: ["This diamond type is not available for this power"] });
    }

    const totalCost = costPerUnit * quantity;

    // Elmas harca
    if (diamondType === "GREEN") {
      await diamondService.spendGreen(userId, totalCost, "POWER_PURCHASE", powerName);
    } else {
      await diamondService.spendPurple(userId, totalCost, "POWER_PURCHASE", powerName);
    }

    // Envantere ekle (upsert)
    const { data: existing } = await supabase
      .from("user_power_inventory")
      .select("count")
      .eq("user_id", userId)
      .eq("power_name", powerName)
      .single();

    if (existing) {
      const { error: updateError } = await supabase
        .from("user_power_inventory")
        .update({
          count: existing.count + quantity,
          updated_at: new Date().toISOString(),
        })
        .eq("user_id", userId)
        .eq("power_name", powerName);

      if (updateError) throw Errors.SERVER_ERROR();
    } else {
      const { error: insertError } = await supabase
        .from("user_power_inventory")
        .insert({
          user_id: userId,
          power_name: powerName,
          count: quantity,
        });

      if (insertError) throw Errors.SERVER_ERROR();
    }

    // İşlem kaydı
    const { error: txError } = await supabase
      .from("power_purchase_transactions")
      .insert({
        user_id: userId,
        power_name: powerName,
        quantity,
        diamond_type: diamondType,
        total_cost: totalCost,
      });

    if (txError) throw Errors.SERVER_ERROR();

    // Güncel envanter ve bakiye
    const { data: inventory } = await supabase
      .from("user_power_inventory")
      .select("power_name, count")
      .eq("user_id", userId)
      .eq("power_name", powerName)
      .single();

    const balance = await diamondService.getBalance(userId);

    return {
      new_count: inventory?.count ?? quantity,
      new_balance: balance,
    };
  }

  /**
   * Kullanıcının power envanterini getir
   */
  async getInventory(userId: string) {
    const { data, error } = await supabase
      .from("user_power_inventory")
      .select("power_name, count")
      .eq("user_id", userId);

    if (error) throw Errors.SERVER_ERROR();

    return { inventory: data ?? [] };
  }

  /**
   * Dönüşüm oranı + power fiyatları
   */
  async getRates() {
    const { data: powers, error } = await supabase
      .from("powers")
      .select("name, base_cost, green_cost, purple_cost, accuracy_rate")
      .eq("is_active", true);

    if (error) throw Errors.SERVER_ERROR();

    return {
      convert_ratio: GREEN_TO_PURPLE_RATIO,
      powers: powers ?? [],
    };
  }

  /**
   * Quiz sırasında envanter kontrolü — hak varsa düş, yoksa false dön
   */
  async tryUseInventory(userId: string, powerName: string): Promise<boolean> {
    const { data: inv } = await supabase
      .from("user_power_inventory")
      .select("count")
      .eq("user_id", userId)
      .eq("power_name", powerName)
      .single();

    if (!inv || inv.count <= 0) return false;

    // Atomik azaltma
    const { error } = await supabase
      .from("user_power_inventory")
      .update({
        count: inv.count - 1,
        updated_at: new Date().toISOString(),
      })
      .eq("user_id", userId)
      .eq("power_name", powerName)
      .gte("count", 1);

    if (error) return false;

    return true;
  }
}

export const exchangeService = new ExchangeService();
```

**Step 2: Commit**

```bash
git add server/src/services/exchange.service.ts
git commit -m "feat(service): add exchange service — conversion, power inventory, rates"
```

---

## Task 5: Backend — Exchange Controller

**Files:**
- Create: `server/src/controllers/exchange.controller.ts`

**Step 1: Write controller**

```typescript
import type { Request, Response, NextFunction } from "express";
import { exchangeService } from "../services/exchange.service.js";
import type { ConvertInput, BuyPowerInput } from "../validators/exchange.validator.js";

export async function convertHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId;
    const { green_amount } = req.body as ConvertInput;
    const result = await exchangeService.convertGreenToPurple(userId, green_amount);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

export async function buyPowerHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId;
    const { power_name, diamond_type, quantity } = req.body as BuyPowerInput;
    const result = await exchangeService.buyPower(userId, power_name, diamond_type, quantity);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

export async function getInventoryHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId;
    const result = await exchangeService.getInventory(userId);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

export async function getRatesHandler(_req: Request, res: Response, next: NextFunction) {
  try {
    const result = await exchangeService.getRates();
    res.json(result);
  } catch (err) {
    next(err);
  }
}
```

**Step 2: Commit**

```bash
git add server/src/controllers/exchange.controller.ts
git commit -m "feat(controller): add exchange controller handlers"
```

---

## Task 6: Backend — Exchange Routes

**Files:**
- Create: `server/src/routes/exchange.routes.ts`
- Modify: `server/src/index.ts`

**Step 1: Write exchange routes**

```typescript
import { Router } from "express";
import { authMiddleware } from "../middleware/auth.js";
import { generalLimiter } from "../middleware/rateLimit.js";
import { validate } from "../middleware/validate.js";
import { convertSchema, buyPowerSchema } from "../validators/exchange.validator.js";
import {
  convertHandler,
  buyPowerHandler,
  getInventoryHandler,
  getRatesHandler,
} from "../controllers/exchange.controller.js";

const router = Router();

router.use(authMiddleware);
router.use(generalLimiter);

router.post("/convert", validate(convertSchema), convertHandler);
router.post("/buy-power", validate(buyPowerSchema), buyPowerHandler);
router.get("/inventory", getInventoryHandler);
router.get("/rates", getRatesHandler);

export default router;
```

**Step 2: Register route in index.ts**

In `server/src/index.ts`, add import and mount:

```typescript
import exchangeRoutes from "./routes/exchange.routes.js";
```

Add route mount after existing routes:

```typescript
app.use("/api/v1/exchange", exchangeRoutes);
```

**Step 3: Commit**

```bash
git add server/src/routes/exchange.routes.ts server/src/index.ts
git commit -m "feat(routes): add exchange routes and register in app"
```

---

## Task 7: Backend — Quiz Service ORACLE + Envanter Entegrasyonu

**Files:**
- Modify: `server/src/services/quiz.service.ts`
- Modify: `server/src/validators/quiz.validator.ts`

**Step 1: Update quiz validator — COPY → ORACLE**

In `server/src/validators/quiz.validator.ts`, change the power_used enum:

```typescript
power_used: z
  .enum(["ORACLE", "HALF", "SKIP", "SKIP_ALL", "TIME_EXTEND", "HINT"])
  .optional(),
```

**Step 2: Update quiz.service.ts — envanter kontrolü + ORACLE mekanizması**

In `server/src/services/quiz.service.ts`:

1. Add import at top:
```typescript
import { exchangeService } from "./exchange.service.js";
```

2. In the `answerQuestion` method, **replace the power handling block** (around lines 202-220) where diamonds are spent. Before `diamondService.spendPurple()`, add inventory check:

```typescript
// Envanter kontrolü — hak varsa envanterden düş, yoksa anlık ödeme
const usedFromInventory = await exchangeService.tryUseInventory(solverId, powerUsed);

if (!usedFromInventory) {
  // Mevcut akış: mor elmas harca
  const cost = calculatePowerCost(power.base_cost, totalQuestions);
  const greenReward = calculateGreenReward(cost);
  await diamondService.spendPurple(solverId, cost, "POWER_USED", session.id);
  await diamondService.earnGreen(targetId, greenReward, "POWER_REWARD", session.id);
  // ... question stats güncelleme
}
```

3. **Replace the COPY case with ORACLE:**

```typescript
case "ORACLE": {
  const accuracyRate = power.accuracy_rate ?? 0.7;
  const isAccurate = Math.random() < accuracyRate;

  let suggestedIndex: number;
  if (isAccurate) {
    suggestedIndex = currentQuestion.correct_answer;
  } else {
    // Rastgele yanlış cevap seç
    const wrongIndices = [1, 2, 3, 4].filter(
      (i) => i !== currentQuestion.correct_answer,
    );
    suggestedIndex = wrongIndices[Math.floor(Math.random() * wrongIndices.length)];
  }

  return {
    power_result: { suggested_answer_index: suggestedIndex, is_guaranteed: false },
    awaiting_answer: true,
  };
}
```

**Step 3: Commit**

```bash
git add server/src/services/quiz.service.ts server/src/validators/quiz.validator.ts
git commit -m "feat(quiz): add ORACLE power mechanic + inventory-first power usage"
```

---

## Task 8: Backend — Power Seed Data Update

**Files:**
- Modify: `server/src/routes/power.routes.ts`

**Step 1: Update power routes to include new fields**

In `server/src/routes/power.routes.ts`, update the select to include new columns:

```typescript
const { data, error } = await supabase
  .from("powers")
  .select("id, name, base_cost, green_cost, purple_cost, accuracy_rate, is_active, description")
  .eq("is_active", true);
```

**Step 2: Commit**

```bash
git add server/src/routes/power.routes.ts
git commit -m "feat(powers): include green_cost, purple_cost, accuracy_rate in power response"
```

---

## Task 9: Backend Tests — Exchange Service

**Files:**
- Create: `server/src/__tests__/exchange.test.ts`

**Step 1: Write tests**

```typescript
import { describe, it, expect, vi, beforeEach } from "vitest";

// Test: convertGreenToPurple
describe("ExchangeService", () => {
  describe("convertGreenToPurple", () => {
    it("should convert green to purple at 3:1 ratio", () => {
      // green_amount: 30 → purple_received: 10
      expect(30 / 3).toBe(10);
    });

    it("should reject non-multiple-of-3 amounts", () => {
      expect(7 % 3).not.toBe(0);
    });
  });

  describe("buyPower", () => {
    it("should calculate total cost correctly", () => {
      const costPerUnit = 15;
      const quantity = 3;
      expect(costPerUnit * quantity).toBe(45);
    });
  });

  describe("ORACLE accuracy", () => {
    it("should return correct or wrong answer based on accuracy rate", () => {
      const correctAnswer = 2;
      const wrongIndices = [1, 2, 3, 4].filter((i) => i !== correctAnswer);
      expect(wrongIndices).toEqual([1, 3, 4]);
      expect(wrongIndices.length).toBe(3);
    });
  });
});
```

**Step 2: Run tests**

```bash
cd server && npm test
```

**Step 3: Commit**

```bash
git add server/src/__tests__/exchange.test.ts
git commit -m "test(exchange): add exchange service unit tests"
```

---

## Task 10: Flutter — Exchange Models

**Files:**
- Create: `lib/data/models/exchange_model.dart`

**Step 1: Write models**

```dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';

part 'exchange_model.g.dart';

@JsonSerializable()
class ConvertResponse extends Equatable {
  @JsonKey(name: 'purple_received')
  final int purpleReceived;
  @JsonKey(name: 'new_balance')
  final DiamondBalance newBalance;

  const ConvertResponse({
    required this.purpleReceived,
    required this.newBalance,
  });

  factory ConvertResponse.fromJson(Map<String, dynamic> json) =>
      _$ConvertResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ConvertResponseToJson(this);

  @override
  List<Object?> get props => [purpleReceived, newBalance];
}

@JsonSerializable()
class BuyPowerResponse extends Equatable {
  @JsonKey(name: 'new_count')
  final int newCount;
  @JsonKey(name: 'new_balance')
  final DiamondBalance newBalance;

  const BuyPowerResponse({
    required this.newCount,
    required this.newBalance,
  });

  factory BuyPowerResponse.fromJson(Map<String, dynamic> json) =>
      _$BuyPowerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BuyPowerResponseToJson(this);

  @override
  List<Object?> get props => [newCount, newBalance];
}

@JsonSerializable()
class PowerInventoryItem extends Equatable {
  @JsonKey(name: 'power_name')
  final String powerName;
  final int count;

  const PowerInventoryItem({
    required this.powerName,
    required this.count,
  });

  factory PowerInventoryItem.fromJson(Map<String, dynamic> json) =>
      _$PowerInventoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$PowerInventoryItemToJson(this);

  @override
  List<Object?> get props => [powerName, count];
}

@JsonSerializable()
class InventoryResponse extends Equatable {
  final List<PowerInventoryItem> inventory;

  const InventoryResponse({required this.inventory});

  factory InventoryResponse.fromJson(Map<String, dynamic> json) =>
      _$InventoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryResponseToJson(this);

  @override
  List<Object?> get props => [inventory];
}

@JsonSerializable()
class ExchangeRatePower extends Equatable {
  final String name;
  @JsonKey(name: 'base_cost')
  final int baseCost;
  @JsonKey(name: 'green_cost')
  final int greenCost;
  @JsonKey(name: 'purple_cost')
  final int purpleCost;
  @JsonKey(name: 'accuracy_rate')
  final double? accuracyRate;

  const ExchangeRatePower({
    required this.name,
    required this.baseCost,
    required this.greenCost,
    required this.purpleCost,
    this.accuracyRate,
  });

  factory ExchangeRatePower.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRatePowerFromJson(json);
  Map<String, dynamic> toJson() => _$ExchangeRatePowerToJson(this);

  @override
  List<Object?> get props => [name];
}

@JsonSerializable()
class RatesResponse extends Equatable {
  @JsonKey(name: 'convert_ratio')
  final int convertRatio;
  final List<ExchangeRatePower> powers;

  const RatesResponse({
    required this.convertRatio,
    required this.powers,
  });

  factory RatesResponse.fromJson(Map<String, dynamic> json) =>
      _$RatesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RatesResponseToJson(this);

  @override
  List<Object?> get props => [convertRatio, powers];
}
```

**Step 2: Run code generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/data/models/exchange_model.dart lib/data/models/exchange_model.g.dart
git commit -m "feat(model): add exchange center data models"
```

---

## Task 11: Flutter — Exchange Retrofit Service

**Files:**
- Create: `lib/core/network/services/exchange_service.dart`

**Step 1: Write service**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';

part 'exchange_service.g.dart';

@RestApi()
abstract class ExchangeService {
  factory ExchangeService(Dio dio) = _ExchangeService;

  @POST('/exchange/convert')
  Future<ConvertResponse> convert(@Body() Map<String, dynamic> data);

  @POST('/exchange/buy-power')
  Future<BuyPowerResponse> buyPower(@Body() Map<String, dynamic> data);

  @GET('/exchange/inventory')
  Future<InventoryResponse> getInventory();

  @GET('/exchange/rates')
  Future<RatesResponse> getRates();
}
```

**Step 2: Run code generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/core/network/services/exchange_service.dart lib/core/network/services/exchange_service.g.dart
git commit -m "feat(network): add exchange retrofit service"
```

---

## Task 12: Flutter — Exchange Repository

**Files:**
- Create: `lib/data/repositories/exchange_repository.dart`
- Modify: `lib/data/repositories/interfaces.dart`

**Step 1: Add interface**

In `lib/data/repositories/interfaces.dart`, add:

```dart
abstract class IExchangeRepository {
  Future<Result<ConvertResponse>> convert(int greenAmount);
  Future<Result<BuyPowerResponse>> buyPower(String powerName, String diamondType, int quantity);
  Future<Result<InventoryResponse>> getInventory();
  Future<Result<RatesResponse>> getRates();
}
```

**Step 2: Write repository**

```dart
import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/exchange_service.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class ExchangeRepository implements IExchangeRepository {
  final ExchangeService _service;

  ExchangeRepository(this._service);

  @override
  Future<Result<ConvertResponse>> convert(int greenAmount) async {
    try {
      final response = await _service.convert({'green_amount': greenAmount});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<BuyPowerResponse>> buyPower(
    String powerName,
    String diamondType,
    int quantity,
  ) async {
    try {
      final response = await _service.buyPower({
        'power_name': powerName,
        'diamond_type': diamondType,
        'quantity': quantity,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<InventoryResponse>> getInventory() async {
    try {
      final response = await _service.getInventory();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<RatesResponse>> getRates() async {
    try {
      final response = await _service.getRates();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 3: Commit**

```bash
git add lib/data/repositories/exchange_repository.dart lib/data/repositories/interfaces.dart
git commit -m "feat(repository): add exchange repository with interface"
```

---

## Task 13: Flutter — Exchange Provider + API Registration

**Files:**
- Create: `lib/providers/exchange_provider.dart`
- Modify: `lib/providers/api_provider.dart`

**Step 1: Register service and repository in api_provider.dart**

Add to `lib/providers/api_provider.dart`:

```dart
final exchangeServiceProvider = Provider<ExchangeService>(
  (ref) => ExchangeService(ref.read(networkManagerProvider).dio),
);

final exchangeRepositoryProvider = Provider<ExchangeRepository>(
  (ref) => ExchangeRepository(ref.read(exchangeServiceProvider)),
);
```

**Step 2: Write exchange provider**

```dart
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';

class ExchangeState {
  final List<PowerInventoryItem> inventory;
  final RatesResponse? rates;
  final bool isLoading;

  const ExchangeState({
    this.inventory = const [],
    this.rates,
    this.isLoading = false,
  });

  ExchangeState copyWith({
    List<PowerInventoryItem>? inventory,
    RatesResponse? rates,
    bool? isLoading,
  }) {
    return ExchangeState(
      inventory: inventory ?? this.inventory,
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int getCount(String powerName) {
    return inventory
        .where((i) => i.powerName == powerName)
        .fold(0, (sum, i) => sum + i.count);
  }
}

class ExchangeNotifier extends Notifier<ExchangeState> {
  @override
  ExchangeState build() => const ExchangeState();

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true);
    final results = await Future.wait([
      ref.read(exchangeRepositoryProvider).getInventory(),
      ref.read(exchangeRepositoryProvider).getRates(),
    ]);

    final invResult = results[0] as Result<InventoryResponse>;
    final ratesResult = results[1] as Result<RatesResponse>;

    state = state.copyWith(
      inventory: invResult is Success<InventoryResponse>
          ? invResult.data.inventory
          : state.inventory,
      rates: ratesResult is Success<RatesResponse>
          ? ratesResult.data
          : state.rates,
      isLoading: false,
    );
  }

  Future<bool> convert(int greenAmount) async {
    final result = await ref.read(exchangeRepositoryProvider).convert(greenAmount);
    if (result is Success<ConvertResponse>) {
      await ref.read(diamondProvider.notifier).fetchBalance();
      return true;
    }
    return false;
  }

  Future<bool> buyPower(String powerName, String diamondType, int quantity) async {
    final result = await ref.read(exchangeRepositoryProvider).buyPower(
      powerName,
      diamondType,
      quantity,
    );
    if (result is Success<BuyPowerResponse>) {
      await fetchAll();
      await ref.read(diamondProvider.notifier).fetchBalance();
      return true;
    }
    return false;
  }
}

final exchangeProvider = NotifierProvider<ExchangeNotifier, ExchangeState>(
  ExchangeNotifier.new,
);
```

**Step 3: Commit**

```bash
git add lib/providers/exchange_provider.dart lib/providers/api_provider.dart
git commit -m "feat(provider): add exchange provider with inventory + conversion state"
```

---

## Task 14: Flutter — PowerIcon Widget

**Files:**
- Create: `lib/core/widgets/power_icon.dart`

**Step 1: Write PowerIcon widget**

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

enum PowerType {
  oracle(QIcons.icOracle, 'ORACLE'),
  half(QIcons.icSplit, 'HALF'),
  skip(QIcons.icSkipForward, 'SKIP'),
  skipAll(QIcons.icFastForward, 'SKIP_ALL'),
  timeExtend(QIcons.icClock, 'TIME_EXTEND'),
  hint(QIcons.icLightbulb, 'HINT');

  final String iconPath;
  final String apiName;
  const PowerType(this.iconPath, this.apiName);

  Color get color => switch (this) {
    PowerType.oracle => AppColors.purple,
    PowerType.half => AppColors.error,
    PowerType.skip => AppColors.info,
    PowerType.skipAll => AppColors.primary,
    PowerType.timeExtend => AppColors.success,
    PowerType.hint => AppColors.warning,
  };

  static PowerType fromApiName(String name) {
    return PowerType.values.firstWhere((p) => p.apiName == name);
  }
}

class PowerIcon extends StatelessWidget {
  final PowerType type;
  final double size;
  final bool showCount;
  final int? count;

  const PowerIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.showCount = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final icon = QIcon(type.iconPath, size: size, color: type.color);

    if (!showCount || count == null || count! <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: type.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '×$count',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

**Step 2: Add ic_oracle to QIcons**

In `lib/core/constants/q_icons.dart`, replace `icCopy` line:

```dart
static const icOracle = 'assets/icons/ic_oracle.svg';
```

**Step 3: Create oracle SVG asset**

Create a simple oracle/eye SVG at `assets/icons/ic_oracle.svg`. (Placeholder — designer tarafından güncellenir.)

**Step 4: Commit**

```bash
git add lib/core/widgets/power_icon.dart lib/core/constants/q_icons.dart assets/icons/ic_oracle.svg
git commit -m "feat(widget): add centralized PowerIcon widget with PowerType enum"
```

---

## Task 15: Flutter — Power Bar Migration

**Files:**
- Modify: `lib/features/quiz/widgets/power_bar.dart`

**Step 1: Refactor PowerBar to use PowerIcon + envanter badge**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

class PowerBar extends ConsumerWidget {
  final String sessionId;
  final bool hasHint;
  final void Function(String power)? onPowerUsed;

  const PowerBar({
    super.key,
    required this.sessionId,
    this.hasHint = false,
    this.onPowerUsed,
  });

  static const _powers = [
    (PowerType.oracle, 'power_oracle'),
    (PowerType.half, 'power_half'),
    (PowerType.skip, 'power_skip'),
    (PowerType.hint, 'power_hint'),
    (PowerType.timeExtend, 'power_time'),
    (PowerType.skipAll, 'power_skip_all'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeState = ref.watch(exchangeProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _powers.map((p) {
          final isHint = p.$1 == PowerType.hint;
          final count = exchangeState.getCount(p.$1.apiName);

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ActionChip(
              avatar: PowerIcon(
                type: p.$1,
                size: 18,
                showCount: count > 0,
                count: count,
              ),
              label: Text(context.tr(p.$2)),
              onPressed: (isHint && !hasHint)
                  ? null
                  : () => onPowerUsed?.call(p.$1.apiName),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/quiz/widgets/power_bar.dart
git commit -m "refactor(quiz): migrate PowerBar to PowerIcon, add inventory badges"
```

---

## Task 16: Flutter — Exchange Screen

**Files:**
- Create: `lib/features/exchange/screens/exchange_screen.dart`
- Create: `lib/features/exchange/widgets/convert_section.dart`
- Create: `lib/features/exchange/widgets/power_shop_card.dart`

**Step 1: Write ConvertSection widget**

```dart
// lib/features/exchange/widgets/convert_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

class ConvertSection extends ConsumerStatefulWidget {
  const ConvertSection({super.key});

  @override
  ConsumerState<ConvertSection> createState() => _ConvertSectionState();
}

class _ConvertSectionState extends ConsumerState<ConvertSection> {
  int _greenAmount = 3;
  bool _isConverting = false;

  int get _purpleResult => _greenAmount ~/ 3;

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(diamondProvider).valueOrNull;
    final maxGreen = balance?.green ?? 0;
    final maxConvertible = (maxGreen ~/ 3) * 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('exchange_convert_title'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        // Slider
        Row(
          children: [
            const DiamondIcon.green(size: 24),
            Expanded(
              child: Slider(
                value: _greenAmount.toDouble(),
                min: 3,
                max: maxConvertible > 3 ? maxConvertible.toDouble() : 6,
                divisions: maxConvertible > 3 ? (maxConvertible ~/ 3) - 1 : 1,
                onChanged: maxConvertible >= 3
                    ? (v) => setState(() => _greenAmount = (v ~/ 3) * 3)
                    : null,
              ),
            ),
            Text('$_greenAmount', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        // Sonuç gösterimi
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_downward, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              const DiamondIcon.purple(size: 24),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$_purpleResult',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Dönüştür butonu
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: maxConvertible >= 3 && !_isConverting
                ? () async {
                    setState(() => _isConverting = true);
                    await ref.read(exchangeProvider.notifier).convert(_greenAmount);
                    if (mounted) setState(() => _isConverting = false);
                  }
                : null,
            child: _isConverting
                ? const AppLoadingWidget.small()
                : Text(context.tr('exchange_convert_button')),
          ),
        ),
      ],
    );
  }
}
```

**Step 2: Write PowerShopCard widget**

```dart
// lib/features/exchange/widgets/power_shop_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

class PowerShopCard extends ConsumerWidget {
  final PowerType powerType;
  final ExchangeRatePower rate;
  final int inventoryCount;

  const PowerShopCard({
    super.key,
    required this.powerType,
    required this.rate,
    required this.inventoryCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10nKey = 'power_${powerType.apiName.toLowerCase()}_desc';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Header: ikon + isim + envanter badge
            Row(
              children: [
                PowerIcon(type: powerType, size: 32),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('power_${powerType.apiName.toLowerCase()}'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        context.tr(l10nKey),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (inventoryCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: powerType.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '×$inventoryCount',
                      style: TextStyle(
                        color: powerType.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Satın al butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const DiamondIcon.purple(size: 16, showGlow: false),
                    label: Text('${rate.purpleCost}'),
                    onPressed: () => ref
                        .read(exchangeProvider.notifier)
                        .buyPower(powerType.apiName, 'PURPLE', 1),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const DiamondIcon.green(size: 16, showGlow: false),
                    label: Text('${rate.greenCost}'),
                    onPressed: () => ref
                        .read(exchangeProvider.notifier)
                        .buyPower(powerType.apiName, 'GREEN', 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 3: Write ExchangeScreen**

```dart
// lib/features/exchange/screens/exchange_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/diamond_balance_card.dart';
import 'package:qulo_v2/features/exchange/widgets/convert_section.dart';
import 'package:qulo_v2/features/exchange/widgets/power_shop_card.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

class ExchangeScreen extends ConsumerStatefulWidget {
  const ExchangeScreen({super.key});

  @override
  ConsumerState<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends ConsumerState<ExchangeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(exchangeProvider.notifier).fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final diamondState = ref.watch(diamondProvider);
    final exchangeState = ref.watch(exchangeProvider);

    return AppScaffold(
      title: context.tr('exchange_title'),
      isLoading: exchangeState.isLoading,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            DiamondBalanceCard(
              greenCount: diamondState.valueOrNull?.green ?? 0,
              purpleCount: diamondState.valueOrNull?.purple ?? 0,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Dönüşüm Bölümü
            const ConvertSection(),
            const SizedBox(height: AppSpacing.xl),

            // Power Hakları Bölümü
            Text(
              context.tr('exchange_powers_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            if (exchangeState.rates != null)
              ...exchangeState.rates!.powers.map((rate) {
                final powerType = PowerType.fromApiName(rate.name);
                final count = exchangeState.getCount(rate.name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PowerShopCard(
                    powerType: powerType,
                    rate: rate,
                    inventoryCount: count,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Commit**

```bash
git add lib/features/exchange/
git commit -m "feat(exchange): add Exchange Center screen with convert section and power shop"
```

---

## Task 17: Flutter — Routing + Diamonds Ekranı Bağlantısı

**Files:**
- Modify: `lib/routing/route_names.dart`
- Modify: `lib/routing/app_routes.dart`
- Modify: `lib/features/diamonds/screens/diamonds_screen.dart`

**Step 1: Add route name**

In `lib/routing/route_names.dart`:

```dart
static const exchange = 'exchange';
```

**Step 2: Add GoRoute**

In `lib/routing/app_routes.dart`, add the exchange route (follow existing pattern):

```dart
GoRoute(
  path: '/exchange',
  name: RouteNames.exchange,
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const ExchangeScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 500),
  ),
),
```

**Step 3: Add navigation button in diamonds screen**

In `lib/features/diamonds/screens/diamonds_screen.dart`, add a "Dönüşüm Merkezi" button after the DiamondBalanceCard. Use NavigationService:

```dart
ref.read(navigationServiceProvider).goNamed(RouteNames.exchange);
```

**Step 4: Commit**

```bash
git add lib/routing/route_names.dart lib/routing/app_routes.dart lib/features/diamonds/screens/diamonds_screen.dart
git commit -m "feat(routing): add exchange route and link from diamonds screen"
```

---

## Task 18: Flutter — Localization Keys

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: Add Turkish and English strings**

In the `_tr` map:

```dart
'exchange_title': 'Dönüşüm Merkezi',
'exchange_convert_title': 'Elmas Dönüşümü',
'exchange_convert_button': 'Dönüştür',
'exchange_powers_title': 'Power Hakları',
'power_oracle': 'Kahin',
'power_oracle_desc': 'Bir şık önerir — garanti değil!',
'power_half_desc': '2 yanlış şıkkı eler',
'power_skip_desc': 'Soruyu doğru say ve geç',
'power_skip_all_desc': 'Tüm kalan soruları geç',
'power_time_desc': 'Süreye 15 saniye ekle',
'power_hint_desc': 'İpucu göster',
```

In the `_en` map:

```dart
'exchange_title': 'Exchange Center',
'exchange_convert_title': 'Diamond Conversion',
'exchange_convert_button': 'Convert',
'exchange_powers_title': 'Power Rights',
'power_oracle': 'Oracle',
'power_oracle_desc': 'Suggests an answer — not guaranteed!',
'power_half_desc': 'Eliminates 2 wrong options',
'power_skip_desc': 'Marks question correct and skips',
'power_skip_all_desc': 'Skips all remaining questions',
'power_time_desc': 'Adds 15 seconds to timer',
'power_hint_desc': 'Shows a hint',
```

**Step 2: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat(l10n): add exchange center localization strings"
```

---

## Task 19: Flutter — Quiz Screen ORACLE UX

**Files:**
- Modify: `lib/features/quiz/screens/quiz_screen.dart`

**Step 1: Update ORACLE response handling**

In quiz_screen.dart, find where `power_result` is handled (COPY case). Replace with ORACLE logic:

- When `power_result.suggested_answer_index` comes back, highlight that answer button with a **pulsing purple aura** animation
- Show a small banner: "Kahin önerisi — garanti değil!"
- User still selects any answer (awaiting_answer: true behavior unchanged)

The animation: wrap the suggested answer button with a `AnimatedContainer` that has a pulsing purple `BoxShadow`.

**Step 2: Commit**

```bash
git add lib/features/quiz/screens/quiz_screen.dart
git commit -m "feat(quiz): add ORACLE power UX with mystic purple pulse animation"
```

---

## Task 20: Verification & Final Cleanup

**Step 1: Run backend tests**

```bash
cd server && npm test
```

**Step 2: Run Flutter analyze**

```bash
flutter analyze
```

**Step 3: Run build_runner to ensure all generated files are up to date**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 4: Verify backend compiles**

```bash
cd server && npm run build
```

**Step 5: Final commit if any remaining changes**

```bash
git add -A
git commit -m "chore: final cleanup and generated files for exchange center"
```
