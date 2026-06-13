# Economy Config Single Source of Truth — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sunucu power cost'larini DB `powers` tablosu yerine economy config'den okuyacak. POWER_UNBLOCK response'u duzeltilecek. Base answer reward konfigurasyon'a tasinacak.

**Architecture:** `chat-question.service.ts` ve `quiz.service.ts`'deki `fetchPower().purple_cost` okumalarini `economyConfigService.getConfig().powerCosts[name].purpleCost` ile degistir. `fetchPower` sadece meta data (accuracy_rate, special_green_reward) icin kalssin.

**Tech Stack:** Node.js/TypeScript (Express), Supabase PostgreSQL, Flutter/Dart

---

## Dosya Haritasi

| Dosya | Aksiyon | Sorumluluk |
|-------|---------|------------|
| `qulo-server/src/services/chat-question.service.ts` | Modify (5 nokta) | Cost kaynagini config'e cevir + POWER_UNBLOCK fix |
| `qulo-server/src/services/quiz.service.ts` | Modify (1 nokta) | Quiz power cost kaynagini config'e cevir |
| `qulo-server/src/types/economy-config.schema.ts` | Modify | baseAnswerReward ekle |
| `qulov2/lib/data/models/economy_config_model.dart` | Modify | Fallback'e baseAnswerReward ekle |

---

### Task 1: POWER_UNBLOCK Response Fix

**Files:**
- Modify: `qulo-server/src/services/chat-question.service.ts:578`

- [ ] **Step 1: POWER_UNBLOCK return'e cost ve green_reward ekle**

Satir 578'i degistir:

```typescript
// ONCE:
      return { unblocked: true };

// SONRA:
      return { unblocked: true, cost, green_reward: specialReward };
```

`cost` ve `specialReward` degiskenleri zaten scope'da mevcut (satir 546 ve 550).

- [ ] **Step 2: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git add src/services/chat-question.service.ts
git commit -m "fix: return cost and green_reward in POWER_UNBLOCK response"
```

---

### Task 2: chat-question.service.ts — Cost kaynagini config'e cevir

**Files:**
- Modify: `qulo-server/src/services/chat-question.service.ts` (5 nokta)

Bu task'ta 5 farkli yerdeki `power.purple_cost ?? power.base_cost ?? 0` pattern'ini economy config'den okumaya ceviriyoruz.

- [ ] **Step 1: createQuestion POWER_BLOCK cost'u (satir 218-219)**

```typescript
// ONCE:
      const power = await this.fetchPower("POWER_BLOCK");
      const cost = power.purple_cost ?? power.base_cost ?? 0;

// SONRA:
      const ecConfigPB = await economyConfigService.getConfig();
      const cost = ecConfigPB.powerCosts.POWER_BLOCK.purpleCost;
```

NOT: POWER_BLOCK icin `fetchPower` artik gerekmiyor — meta data (accuracy_rate, special_green_reward) kullanilmiyor.

- [ ] **Step 2: answerQuestion SKIP cost'u (satir 310-312)**

```typescript
// ONCE:
      const power = await this.fetchPower("SKIP");
      const ecConfig = await economyConfigService.getConfig();
      const cost = calculatePowerCost(power.purple_cost ?? power.base_cost ?? 0, 1, ecConfig.core.questionCountMultipliers);

// SONRA:
      const ecConfig = await economyConfigService.getConfig();
      const cost = calculatePowerCost(ecConfig.powerCosts.SKIP.purpleCost, 1, ecConfig.core.questionCountMultipliers);
```

`fetchPower("SKIP")` kaldiriliyor — SKIP'in meta data'si yok.

- [ ] **Step 3: rescueQuestion SKIP cost'u (satir 458-460)**

```typescript
// ONCE:
      const power = await this.fetchPower("SKIP");
      const ecConfig2 = await economyConfigService.getConfig();
      const cost = calculatePowerCost(power.purple_cost ?? power.base_cost ?? 0, 1, ecConfig2.core.questionCountMultipliers);

// SONRA:
      const ecConfig2 = await economyConfigService.getConfig();
      const cost = calculatePowerCost(ecConfig2.powerCosts.SKIP.purpleCost, 1, ecConfig2.core.questionCountMultipliers);
```

`fetchPower("SKIP")` kaldiriliyor.

- [ ] **Step 4: usePower POWER_UNBLOCK cost'u (satir 545-546)**

```typescript
// ONCE:
      const power = await this.fetchPower("POWER_UNBLOCK");
      const cost = power.purple_cost ?? power.base_cost ?? 0;

// SONRA:
      const ecConfigUB = await economyConfigService.getConfig();
      const cost = ecConfigUB.powerCosts.POWER_UNBLOCK.purpleCost;
      const power = await this.fetchPower("POWER_UNBLOCK"); // sadece special_green_reward icin
```

`fetchPower` HALA gerekli — `power.special_green_reward` (satir 550) icin.

- [ ] **Step 5: usePower normal powers cost'u (satir 589-591)**

```typescript
// ONCE:
    const power = await this.fetchPower(powerName);
    const ecConfig3 = await economyConfigService.getConfig();
    const cost = calculatePowerCost(power.purple_cost ?? power.base_cost ?? 0, 1, ecConfig3.core.questionCountMultipliers);

// SONRA:
    const ecConfig3 = await economyConfigService.getConfig();
    const powerCostEntry = ecConfig3.powerCosts[powerName as keyof typeof ecConfig3.powerCosts];
    const cost = calculatePowerCost(powerCostEntry.purpleCost, 1, ecConfig3.core.questionCountMultipliers);
    const power = await this.fetchPower(powerName); // sadece ORACLE accuracy_rate icin
```

`fetchPower` HALA gerekli — ORACLE'in `accuracy_rate`'i (satir 615) icin kullaniliyor.

- [ ] **Step 6: Sunucuyu yeniden baslat ve dogrula**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
pkill -f "tsx.*src/index.ts" || true
npx tsx src/index.ts &
```

Beklenen: Sunucu hatasiz baslar.

- [ ] **Step 7: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git add src/services/chat-question.service.ts
git commit -m "refactor: read power costs from economy config instead of powers DB table"
```

---

### Task 3: quiz.service.ts — Cost kaynagini config'e cevir

**Files:**
- Modify: `qulo-server/src/services/quiz.service.ts:263`

- [ ] **Step 1: Quiz power cost'unu config'den oku**

Satir 263 civarini degistir:

```typescript
// ONCE:
const cost = calculatePowerCost(powerData.base_cost, session.total_questions, config.core.questionCountMultipliers);

// SONRA:
const powerCostEntry = config.powerCosts[powerName as keyof typeof config.powerCosts];
const cost = calculatePowerCost(powerCostEntry.purpleCost, session.total_questions, config.core.questionCountMultipliers);
```

NOT: `config` degiskeni bu noktada zaten `economyConfigService.getConfig()` ile alinmis olmali — dogrulayin.

- [ ] **Step 2: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git add src/services/quiz.service.ts
git commit -m "refactor: read quiz power costs from economy config"
```

---

### Task 4: baseAnswerReward config'e tasima

**Files:**
- Modify: `qulo-server/src/types/economy-config.schema.ts:36-45`
- Modify: `qulo-server/src/services/chat-question.service.ts:387`
- DB: economy_config_versions guncelle

- [ ] **Step 1: Zod schema'ya baseAnswerReward ekle**

`economy-config.schema.ts` satir 36-45, coreSchema'ya ekle:

```typescript
const coreSchema = z.object({
  boostCostGreen: z.number().int().min(B.boostCostGreen.min).max(B.boostCostGreen.max),
  boostDurationMinutes: z.number().int().min(B.boostDurationMinutes.min).max(B.boostDurationMinutes.max),
  greenDiamondRewardRatio: z.number().min(B.greenDiamondRewardRatio.min).max(B.greenDiamondRewardRatio.max),
  greenToPurpleRatio: z.number().int().min(B.greenToPurpleRatio.min).max(B.greenToPurpleRatio.max),
  baseAnswerReward: z.number().int().min(1).max(100).default(10),
  questionCountMultipliers: z.record(
    z.string(),
    z.number().min(B.questionCountMultiplier.min).max(B.questionCountMultiplier.max),
  ),
});
```

- [ ] **Step 2: Server'da hardcoded 10'u config'den oku**

`chat-question.service.ts` satir 387'yi degistir:

```typescript
// ONCE:
      greenReward = calculateGreenReward(10, ecRewardConfig.core.greenDiamondRewardRatio);

// SONRA:
      greenReward = calculateGreenReward(ecRewardConfig.core.baseAnswerReward ?? 10, ecRewardConfig.core.greenDiamondRewardRatio);
```

- [ ] **Step 3: DB'ye baseAnswerReward ekle**

Supabase MCP ile calistir:

```sql
UPDATE economy_config_versions
SET config = jsonb_set(config, '{core,baseAnswerReward}', '10'::jsonb)
WHERE is_active = true;
```

- [ ] **Step 4: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulo-server
git add src/types/economy-config.schema.ts src/services/chat-question.service.ts
git commit -m "feat: make base answer reward configurable via economy config"
```

---

### Task 5: Flutter Fallback Guncelleme

**Files:**
- Modify: `qulov2/lib/data/models/economy_config_model.dart`

- [ ] **Step 1: EconomyConfig model'ine baseAnswerReward ekle**

Model'deki `EconomyCore` class'ina `baseAnswerReward` field'i ekle ve fallback degerini 10 yap.

NOT: Bu alanin model'de nerede tanimlandigini oncelikle oku, mevcut pattern'i takip et.

- [ ] **Step 2: flutter analyze**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
dart analyze lib/data/models/economy_config_model.dart
```

- [ ] **Step 3: Commit**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
git add lib/data/models/economy_config_model.dart
git commit -m "feat: add baseAnswerReward to economy config fallback"
```

---

### Task 6: Son Dogrulama

- [ ] **Step 1: Sunucu dogrulama**

```bash
curl -s http://localhost:3001/ping | head -1
```

- [ ] **Step 2: Economy config dogrulama**

```bash
curl -s http://localhost:3001/api/v1/app/economy | python3 -m json.tool | grep -A2 baseAnswerReward
```

- [ ] **Step 3: flutter analyze**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
dart analyze lib/data/models/
```
