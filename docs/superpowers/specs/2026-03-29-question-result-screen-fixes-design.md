# Soru Sonucu Ekrani Iyilestirmesi — Tasarim Spec

## Ozet

Soru cozme sonuc ekranindaki 3 bug fix + 2 yeni ozellik:
1. **Sure hesaplama bug fix** — TIME_EXTEND kullanildiginda sure 0s gosteriyor
2. **Yesil elmas hesaplama bug fix** — Power kullanımlarından kazanilan yesil elmaslar gosterilmiyor
3. **Mor elmas harcama gosterimi** — Toplam harcanan mor elmas bilgisi yok
4. **Server fix** — usePower response'a cost/green_reward eklenmesi
5. **businessCaseSkills** — Skill klasoru olusturma (ayri oturum)

## 1. Sure Hesaplama Bug Fix

### Kok Neden
`solve_chat_question_screen_mixin.dart:70`:
```dart
final timeSpent = (startTime - remaining).clamp(0, startTime * 2);
```

`startTime` = `timeLimitSeconds` (orn. 30s). TIME_EXTEND kullanildiginda timer'a +15s ekleniyor ama `startTime` guncellenmedigindan, `remaining > startTime` olabiliyor. Bu durumda `startTime - remaining` negatif → `.clamp(0, ...)` → **0s**.

### Cozum
Mixin'e `int _extraTimeAdded = 0` sayaci eklenir. TIME_EXTEND basarilı oldugunda `_extraTimeAdded += data.extraSeconds ?? 15` arttirilir.

`submitAnswer()` formulü:
```dart
final totalTime = startTime + _extraTimeAdded;
final timeSpent = (totalTime - remaining).clamp(0, totalTime);
```

### Etkilenen Dosya
- `lib/features/chat/mixins/solve_chat_question_screen_mixin.dart`

## 2. Client-Side Power Kullanim Biriktirme

### Problem
Her `usePower` cagrisi ayri ayri `cost` ve `green_reward` donuyor ama client bunlari biriktirmiyor. Sonuc ekraninda sadece `answerQuestion` response'undaki `green_reward` gosteriliyor (base reward: 3).

### Cozum

#### 2.1 Yeni Model: PowerUsageRecord
`chat_question_model.dart`'a eklenir:
```dart
class PowerUsageRecord {
  final String powerName;
  final int purpleSpent;
  final int greenEarned;
  const PowerUsageRecord({
    required this.powerName,
    required this.purpleSpent,
    required this.greenEarned,
  });
}
```

#### 2.2 Mixin Degisiklikleri
`solve_chat_question_screen_mixin.dart`:
- `List<PowerUsageRecord> _powerUsages = []` listesi eklenir
- `usePower` success callback'inde:
  ```dart
  if (data.cost != null && data.cost! > 0) {
    _powerUsages.add(PowerUsageRecord(
      powerName: powerName,
      purpleSpent: data.cost!,
      greenEarned: data.greenReward ?? 0,
    ));
  }
  ```
- `submitAnswer` success callback'inde answer reward'i da eklenir:
  ```dart
  if (response.greenReward > 0) {
    _powerUsages.add(PowerUsageRecord(
      powerName: 'ANSWER',
      purpleSpent: 0,
      greenEarned: response.greenReward,
    ));
  }
  ```

#### 2.3 Result Screen'e Aktarim
`ChatQuestionResultScreen`'e yeni parametre:
```dart
final List<PowerUsageRecord> powerUsages;
```

### Etkilenen Dosyalar
- `lib/data/models/chat_question_model.dart`
- `lib/features/chat/mixins/solve_chat_question_screen_mixin.dart`
- `lib/features/chat/screens/solve_chat_question_screen.dart`

## 3. Server Fix: usePower Response

### Problem
`chat-question.service.ts:686` — Normal power'larin (ORACLE, HALF, HINT, TIME_EXTEND) return objesi sadece `power_name` ve effect donuyor. `cost` ve `green_reward` donmuyor.

### Cozum
Satir 686 civarindaki return'u degistir:
```typescript
// Once:
return { power_name: powerName, ...powerResult };

// Sonra:
return { power_name: powerName, cost, green_reward: greenReward, ...powerResult };
```

### Etkilenen Dosya
- `qulo-server/src/services/chat-question.service.ts`

## 4. Sonuc Ekrani Yeni Tasarim

### 4.1 Yesil Elmas Karti (Hibrit)
Mevcut `_GreenRewardCard` yerine yeni widget:

**Ust kisim:** Toplam yesil elmas (tum power + answer)
```
+18 Yesil Elmas
Soru sahibine kazandirdin
```

**Alt kisim:** Acilabilir detay (ExpansionTile benzeri)
```
  Dogru cevap: +3
  ORACLE: +3
  HALF x2: +6
  TIME_EXTEND x2: +4
  HINT: +2
```

### 4.2 Mor Elmas Karti (Hibrit)
Yeni `_PurpleSpentCard` widget'i:

**Ust kisim:** Toplam mor harcama
```
-45 Mor Elmas harcandi
```

**Power listesinde:** Her power'in yaninda maliyet
```
  ORACLE (-15) | HALF x2 (-20) | TIME_EXTEND x2 (-10)
```

### 4.3 Widget Sirasi (Sonuc Ekraninda)
1. Result Icon (check/cross animasyon)
2. Baslik (Tebrikler / Yanlis Cevap)
3. Unmatch uyarisi (varsa)
4. Kurtarma butonu (yanlis cevapsa)
5. **Yesil Elmas Karti** (hibrit — toplam + detay)
6. **Mor Elmas Karti** (hibrit — toplam + power basina maliyet)
7. Kullanilan Gucler listesi (mevcut chip'ler)
8. Cevap Detaylari (cevap, dogru, sure)
9. Odul medyasi
10. Geri Don butonu

### Etkilenen Dosya
- `lib/features/chat/widgets/chat_question_result.dart`

## 5. businessCaseSkills

**Konum:** `/Users/berkantcalikusu/IdeaProjects/qulo/.claude/skills/businessCaseSkills/`

Ilk skill: `statistics-tracker` — bu spec'in implementasyonundan sonra ayri oturumda yazilacak. Projedeki tum istatistiksel verilerin (elmas, sure, power kullanim, match, soru cozme oranlari) nerede hesaplandigini, nerede gosterildigini ve birbirini nasil etkiledigini bilecek.

## Kapsam Disi
- Server-side toplam hesaplama (client-side biriktirme tercih edildi)
- statistics-tracker skill yazimi (ayri oturum)
- i18n (mevcut Turkce hardcoded, sonra lokalize edilir)
