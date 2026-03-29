# Economy Config Single Source of Truth — Tasarim Spec

## Ozet

Sunucu power cost'lari DB `powers` tablosu yerine economy config'den okuyacak. POWER_UNBLOCK response'u duzeltilecek. Base answer reward konfigurasyon'a tasinacak.

## 1. POWER_UNBLOCK Response Fix

### Sorun
`chat-question.service.ts:578` — `return { unblocked: true }` donuyor. Cost ve green_reward eksik. Sonuc ekraninda POWER_UNBLOCK'un harcadigi 15 mor ve kazandirdigi yesil elmas gorunmuyor.

### Cozum
```typescript
// ONCE:
return { unblocked: true };

// SONRA:
return { unblocked: true, cost, green_reward: specialReward };
```

### Etkilenen Dosya
- `qulo-server/src/services/chat-question.service.ts` (satir 578)

## 2. Sunucu Power Cost Kaynagini Economy Config'e Tasima

### Sorun
Sunucu `this.fetchPower(powerName)` ile DB `powers` tablosundan `purple_cost` okuyor. Economy config'deki `powerCosts` tanimli ama sunucu tarafindan kullanilmiyor. Drift olusmus:

| Guc | Config purpleCost | DB purple_cost |
|-----|-------------------|----------------|
| ORACLE | 3 | 20 |
| HALF | 10 | 15 |
| HINT | 8 | 10 |
| SKIP | 20 | 25 |
| SKIP_ALL | 60 | 100 |
| TIME_EXTEND | 5 | 10 |
| POWER_BLOCK | 15 | 40 |
| POWER_UNBLOCK | 15 | 50 |

### Cozum
Sunucu power cost'lari economy config'den okuyacak. DB `powers` tablosu sadece meta data icin (accuracy_rate, special_green_reward).

Degisecek metodlar:
1. `usePower()` — satir 589-591: `power.purple_cost` yerine config'den `powerCosts[powerName].purpleCost`
2. `answerQuestion()` SKIP blogu — satir 312: ayni degisiklik
3. `rescueQuestion()` — satir 460: ayni degisiklik (SKIP cost)
4. `createQuestion()` — POWER_BLOCK cost icin (eger burada da DB'den okunuyorsa)

Her yerde pattern:
```typescript
// ONCE:
const power = await this.fetchPower(powerName);
const cost = calculatePowerCost(power.purple_cost ?? power.base_cost ?? 0, 1, ecConfig.core.questionCountMultipliers);

// SONRA:
const ecConfig = await economyConfigService.getConfig();
const powerCostConfig = ecConfig.powerCosts[powerName];
const cost = calculatePowerCost(powerCostConfig.purpleCost, 1, ecConfig.core.questionCountMultipliers);
// fetchPower sadece meta data icin (accuracy_rate, special_green_reward)
const power = await this.fetchPower(powerName); // sadece meta icin
```

### Gecerli Fiyatlar (Economy Config)
| Guc | purpleCost | greenCost |
|-----|-----------|-----------|
| ORACLE | 3 | 15 |
| HALF | 10 | 30 |
| HINT | 8 | 24 |
| SKIP | 20 | 60 |
| SKIP_ALL | 60 | 180 |
| TIME_EXTEND | 5 | 15 |
| POWER_BLOCK | 15 | 45 |
| POWER_UNBLOCK | 15 | 45 |

### fetchPower Kullanimi (Meta Data)
`fetchPower` hala cagrilacak ama sadece su alanlar icin:
- `accuracy_rate` (ORACLE: 0.70)
- `special_green_reward` (POWER_UNBLOCK: 140)

### Etkilenen Dosya
- `qulo-server/src/services/chat-question.service.ts`

## 3. Base Answer Reward Config'e Tasima

### Sorun
`answerQuestion` satir 387: `calculateGreenReward(10, ...)` — base=10 hardcoded.

### Cozum
Economy config'e `core.baseAnswerReward: 10` ekle.

**Server:**
```typescript
// ONCE:
greenReward = calculateGreenReward(10, ecRewardConfig.core.greenDiamondRewardRatio);

// SONRA:
greenReward = calculateGreenReward(ecRewardConfig.core.baseAnswerReward ?? 10, ecRewardConfig.core.greenDiamondRewardRatio);
```

**DB migration:**
```sql
UPDATE economy_config
SET config = jsonb_set(config, '{core,baseAnswerReward}', '10'::jsonb)
WHERE id = (SELECT id FROM economy_config ORDER BY created_at DESC LIMIT 1);
```

**Flutter fallback:**
`economy_config_model.dart`'taki `EconomyConfig.fallback`'e `baseAnswerReward: 10` ekle.

### Etkilenen Dosyalar
- `qulo-server/src/services/chat-question.service.ts` (satir 387)
- `qulo-server/src/types/economy-config.schema.ts` (zod schema'ya baseAnswerReward ekle)
- DB migration (economy_config tablosu)
- `qulov2/lib/data/models/economy_config_model.dart` (fallback)

## 4. Kapsam

### Dahil
- POWER_UNBLOCK response fix
- usePower/answerQuestion/rescueQuestion cost kaynagi degisikligi
- createQuestion POWER_BLOCK cost kaynagi degisikligi
- baseAnswerReward config'e tasima
- Flutter fallback guncelleme

### Haric
- powers tablosu silme/degistirme (meta data icin hala gerekli)
- greenCost kullanimi (su an sadece inventory/exchange icin — ayri konu)
- Client-side guc fiyat gosterim degisikligi (zaten economy config'den okuyor)
