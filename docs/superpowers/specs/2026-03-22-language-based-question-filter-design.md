# Dil Bazli Soru Filtreleme

**Tarih:** 2026-03-22
**Durum:** Onaylandi

## Ozet

Quiz'de cozucunun tercih etmedigi dillerdeki sorularin tamamen filtrelenmesi ve discover'da dil bazli 2+ soru esiginin uygulanmasi.

## Problem

Su an quiz'de tum sorular sunuluyor (sadece siralama dil bazli). Cozucu, tercih etmedigi dillerdeki sorulari da goruyor. Ornek: Turkce tercih eden biri, karsisindakinin Ispanyolca sorularini da cozuyor.

## Cozum — 3 Degisiklik

### 1. Quiz: Sadece Eslesen Dillerdeki Sorular

**Dosya:** `qulo-server/src/services/quiz.service.ts`

Mevcut `orderByLanguagePreference` metodu siralama yapiyor. Bu metod `filterByLanguagePreference` olarak degistirilir:

- Cozucunun tercih ettigi dillere uymayan sorular **tamamen cikarilir** (siralama degil, filtreleme)
- `totalQuestions` filtrelenmis soru sayisina gore hesaplanir
- Filtreleme sonrasi 2'den az soru kalirsa `NO_QUESTIONS` hatasi firlatilir
- Cozucunun dil tercihi bossa → tum sorular sunulur (mevcut davranis korunur)

**Etkilenen metodlar:**
- `startSession()` — soru listesi filtrelenir, filtrelenmis soru ID'leri session satırına kaydedilir (`question_ids` JSON array)
- `getCurrentQuestion()` — kaydedilmis `question_ids`'den soru cekilir (re-filter YAPILMAZ)
- `answerQuestion()` — kaydedilmis `question_ids`'den dogru soru referans alinir

**Kritik: Session'a soru ID'leri kaydetme**
Race condition onlemek icin filtrelenmis soru ID listesi session olusturulurken DB'ye yazilir. Sonraki `getCurrentQuestion` ve `answerQuestion` cagrilari bu kaydedilmis listeyi kullanir, her seferinde yeniden filtreleme YAPMAZ. Boylece target quiz sirasinda soru eklese/silse bile session tutarli kalir.

`quiz_sessions` tablosuna yeni kolon: `question_ids TEXT[]` (veya JSONB array)

**Dil kaynagi tutarliligi:**
Quiz ve discover ayni dil kaynagini kullanmali. Cozum sirasi:
1. `user.preferred_languages` (kullanici acikca sectiyse)
2. `userLanguageService.getUserLanguages()` (user_languages tablosundan)
3. Bos → filtreleme yapilmaz (tum sorular)

### 2. Discover: Dil Bazli 2+ Soru Esigi

**Dosya:** `qulo-server/src/services/matching.service.ts`

Mevcut language filter logic'i guclendirilir:

- Cozucunun tercih ettigi dilde 2+ sorusu olmayan adaylar **kesinlikle gosterilmez**
- Bu yeni davranis default olur (strict/relaxed ayrimi kalkar)
- `strict_language_mode` kolonu ve UI toggle'i kaldirilir — yeni davranis her zaman strict
- Migration: `strict_language_mode` kolonu deprecate edilir ama silinmez (geriye donuk uyumluluk). Kod bu kolonu artik okumaz

**Mevcut akis:**
```
preferredCandidates = matchingCount >= 2 (tercih edilen dilde)
fallbackCandidates = matchingCount < 2 (tercih edilen dilde degil)
relaxed: [...preferred, ...fallback]  ← fallback gosteriliyor
strict: [...preferred]  ← sadece preferred
```

**Yeni akis:**
```
discoverableFiltered = matchingCount >= 2 (tercih edilen dilde)
// fallback artik yok — dil eslesmesi 2+ zorunlu
```

- Cozucunun dil tercihi bossa → mevcut davranis (tum adaylar, toplam 2+ soru filtresi)

### 3. Swipe (LIKE): Ayni Dil Kontrolu

**Dosya:** `qulo-server/src/services/matching.service.ts`

Swipe LIKE logic'inde de dil bazli 2+ kontrol uygulanir:

- Cozucunun dil tercihine uyan 2+ soru yoksa LIKE yapilamaz → `NO_QUESTIONS` hatasi
- Mevcut `strict_language_mode` kontrolu bu yeni davranisla degistirilir
- Cozucunun dil tercihi bossa → toplam soru sayisi kontrolu (mevcut davranis)

## Dokunulmayan Yerler

- Soru olusturma akisi — degismez (toplam slot, tek dil secimi)
- Kullanici dil tercihleri — degismez (`preferred_languages`, `user_languages` table)
- Slot sistemi — toplam slot kalir, dil bazli slot yok
- Flutter tarafi — degisiklik yok (quiz server'dan gelen sorulari gosteriyor, discover server filtrelemesine guveniyor)

## Edge Case'ler

| Durum | Davranis |
|-------|----------|
| Cozucunun dil tercihi bos | Tum sorular sunulur (mevcut davranis korunur) |
| Sorunun `locale`'i null | `'tr'` kabul edilir (mevcut davranis) |
| Filtreleme sonrasi 2'den az soru | Discover: gosterilmez. Quiz: `NO_QUESTIONS` hatasi |
| Kullanici tum sorularini tek dilde hazirladi | O dili tercih edenler gorebilir, diger dillerdekiler goremez |
| Kullanici farkli dillerde 1'er soru hazirladi (ornek: 1 TR + 1 EN) | Hicbir dil tercihinde 2+ esik karsilanmaz → kimseye gosterilmez. Kullanici en az bir dilde 2+ soru olmali |

## Teknik Degisiklikler

### Server (qulo-server) — Degisen Dosyalar

1. **`src/services/quiz.service.ts`**
   - `orderByLanguagePreference()` → `filterByLanguagePreference()` yeniden adlandirilir
   - Filter logic: `questions.filter(q => solverLanguages.includes(q.locale || 'tr'))` (solverLanguages bos ise tum sorular doner)
   - `startSession()`: filtrelenmis soru ID'leri session'a `question_ids` olarak kaydedilir
   - `getCurrentQuestion()`: `session.question_ids[current_q - 1]` ile soru cekilir (re-filter yok)
   - `answerQuestion()`: ayni `question_ids` listesinden referans alinir
   - `QuestionRow` interface'ine `locale?: string` eklenir
   - Dil kaynagi: once `preferred_languages`, sonra `userLanguageService`, bossa filtreleme yok

2. **`src/migrations/` — Yeni migration**
   - `quiz_sessions` tablosuna `question_ids` kolonu eklenir (JSONB veya TEXT[])

2. **`src/services/matching.service.ts`**
   - Discover: `discoverableFiltered` sadece dil bazli 2+ eslesmeli adaylari icerir
   - Swipe LIKE: `strict_language_mode` kontrolu yerine dil bazli 2+ kontrol
   - fallback candidates mantigi kaldirilir

3. **`src/services/matching.service.ts`**
   - Discover: `discoverableFiltered` sadece dil bazli 2+ eslesmeli adaylari icerir
   - Swipe LIKE: `strict_language_mode` kontrolu yerine dil bazli 2+ kontrol
   - fallback candidates mantigi kaldirilir
   - Dil kaynagi: once `preferred_languages`, sonra `userLanguages`, bossa filtreleme yok (mevcut mantik korunur)

### Flutter (qulov2) — Minimal Degisiklik

- `strict_language_mode` toggle'i varsa UI'dan kaldirilir (artik anlamsiz)
- Quiz ve discover zaten server filtrelemesine guveniyor, baska degisiklik gerekmez

## Test Senaryolari

1. **Kullanici A:** 2 TR + 2 ES soru hazirladi
   - TR tercih eden → 2 TR soru gorunur (quiz + discover)
   - ES tercih eden → 2 ES soru gorunur (quiz + discover)
   - FR tercih eden → A gosterilmez (discover'da cikmaz)

2. **Kullanici B:** 3 TR + 1 EN soru hazirladi
   - TR tercih eden → 3 TR soru gorunur
   - EN tercih eden → B gosterilmez (1 EN soru, 2+ esik karsilanmaz)

3. **Kullanici C:** 5 TR soru hazirladi
   - TR tercih eden → 5 soru gorunur
   - EN tercih eden → C gosterilmez

4. **Kullanici D:** Dil tercihi bos
   - Tum adaylar gosterilir (mevcut davranis)
   - Quiz'de tum sorular sunulur
