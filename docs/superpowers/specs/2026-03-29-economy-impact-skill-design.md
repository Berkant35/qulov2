# Economy Impact Analysis Skill — Design Spec

**Tarih:** 2026-03-29
**Yaklaşım:** Hibrit (Statik Model + Dinamik Doğrulama)
**Skill Adı:** `economy-impact`
**Konum:** `/Users/berkantcalikusu/.claude/skills/economy-impact/SKILL.md`

---

## 1. Amaç

Feature geliştirmeden önce, yapılacak değişikliğin Qulo ekonomi sistemini (elmas, güç, abonelik, IAP, boost, ödül) nasıl etkileyeceğini otomatik analiz eden bir skill. Etki varsa risk raporu sunar, yoksa agent'a otomatik geçiş yapar.

## 2. Tetikleme Koşulları

- Yeni feature geliştirmesi başlatılırken otomatik
- Manuel: `risk analizi`, `economy impact`, `ekonomi etkisi`, `etki analizi`
- Brainstorming → writing-plans geçişinde otomatik araya girerek
- CLAUDE.md'de otomatik review kurallarına eklenir

## 3. Skill Akışı

```
1. Feature açıklamasını al
2. Economy config'den güncel yapıyı doğrula (dinamik)
3. Etki matrisi üzerinden hangi alanları etkilediğini tespit et
4. Etki seviyesini belirle: YOK / DÜŞÜK / ORTA / YÜKSEK / KRİTİK
5. Etki varsa → risk raporu + öneriler sun, kullanıcıya onayla
6. Etki yoksa → "Ekonomi etkisi yok" bildir, agent'a devam et
7. Sonucu memory'ye logla
```

## 4. Statik Ekonomi Modeli

### 4.1 Temel Formüller

```
powerCost       = ceil(baseCost × questionCountMultiplier[questionCount])
greenEarned     = floor(purpleEquivalent × greenDiamondRewardRatio)
purpleFromGreen = greenAmount / greenToPurpleRatio
boostCost       = boostCostGreen (sabit)
```

### 4.2 Varsayılan Sabitler

| Sabit | Değer | Kaynak |
|-------|-------|--------|
| greenDiamondRewardRatio | 0.30 | EconomyConfig.core |
| greenToPurpleRatio | 3 | EconomyConfig.core |
| boostCostGreen | 30 | EconomyConfig.core |
| boostDurationMinutes | 30 | EconomyConfig.core |
| questionTimeSeconds | 30 | EconomyConfig.timing |
| timeExtendSeconds | 15 | EconomyConfig.timing |
| referralPurple | 25 | EconomyConfig.rewards |
| maxCompletedReferrals | 10 | EconomyConfig.rewards |

### 4.3 Güç Maliyetleri (Base)

| Güç | Green | Purple | Etki |
|-----|-------|--------|------|
| ORACLE | 15 | 5 | Doğru cevabı gösterir |
| HALF | 30 | 10 | 2 yanlış şıkkı eler |
| SKIP | 60 | 20 | Otomatik doğru cevap + medya |
| SKIP_ALL | 180 | 60 | Tüm soruları atla |
| TIME_EXTEND | 15 | 5 | +15 saniye |
| HINT | 24 | 8 | İpucu gösterir |
| POWER_BLOCK | 45 | 15 | Güçleri engeller |
| POWER_UNBLOCK | 45 | 15 | Engeli kaldırır |

### 4.4 Soru Sayısı Çarpanları

| Soru Sayısı | Çarpan |
|-------------|--------|
| 2 | 0.50 |
| 3 | 0.75 |
| 4 | 1.00 |
| 5 | 1.25 |
| 6+ | 1.50 |

### 4.5 Abonelik Tier Limitleri

| Özellik | Free | Plus | Premium |
|---------|------|------|---------|
| Günlük Discover | 50 | ∞ | ∞ |
| Max Soru | 4 | 6 | 10 |
| Günlük Undo | 0 | 3 | ∞ |
| Günlük Chat Question | 2 | 5 | ∞ |
| Unmatch Risk/Gün | 1 | 2 | ∞ |
| Aylık Purple Bonus | 0 | 500 | 1500 |
| Passport Mode | Yok | Yok | Var |
| Reklam | Var | Yok | Yok |

### 4.6 IAP Ürünleri

| Ürün ID | Purple Miktarı |
|---------|----------------|
| qulopurple50 | 50 |
| qulopurple150 | 150 |
| qulopurple400 | 400 |
| qulopurple1000 | 1000 |
| qulopurple2500 | 2500 |
| qulopurple6000 | 6000 |

### 4.7 Milestone Ödülleri

| Cevap Sayısı | Purple Ödül |
|--------------|-------------|
| 25 | 5 |
| 50 | 15 |
| 75 | 30 |
| 100 | 50 |

## 5. Etki Matrisi (8 Kategori)

| # | Kategori | Açıklama | Örnek Tetikleyiciler |
|---|----------|----------|---------------------|
| 1 | Elmas Akışı | Green/purple kazanım veya harcama | Yeni kazanım kaynağı, ödül değişikliği |
| 2 | Güç Sistemi | Power maliyetleri, yeni güç | Güç ekleme/kaldırma, maliyet ayarı |
| 3 | Abonelik Limitleri | Tier sınırları, bonus miktarları | Limit değişikliği, yeni tier özelliği |
| 4 | IAP / Monetizasyon | Satın alma akışı, fiyatlama | Yeni ürün, fiyat değişikliği |
| 5 | Günlük Limitler | Discover, undo, chat sınırları | Limit artış/azalış |
| 6 | Boost / Görünürlük | Boost maliyeti, süresi | Boost mekaniği değişikliği |
| 7 | Ödül Sistemi | Milestone, referral, conversion | Yeni ödül, oran değişikliği |
| 8 | Zamanlama | Soru süresi, time extend | Süre değişikliği |

### 5.1 Etki Zincirleri

| Değişen Parametre | Etkilenen Alanlar |
|---|---|
| greenDiamondRewardRatio | Tüm green kazanım, exchange dengesi, green→purple oranı |
| greenToPurpleRatio | Exchange, green değeri, power satın alma tercihi |
| questionCountMultiplier | Power maliyetleri, soru oluşturma teşviki, green kazanım |
| powerCosts.* | Güç kullanım oranı, green kazanım (SKIP), monetizasyon |
| subscriptionLimits.* | Kullanıcı davranışı, churn, upsell potansiyeli |
| monthlyPurpleBonus | Subscription değeri, IAP cannibalization |
| dailyDiscovers | Engagement, upsell fırsatı, reklam geliri |
| milestones.* | Retention, purple enflasyonu |
| referralPurple | Organik büyüme, purple enflasyonu |
| boostCostGreen | Green demand, boost kullanım oranı |

## 6. Risk Skorlama

| Seviye | Skor | Tanım |
|--------|------|-------|
| YOK | 0 | Feature ekonomi parametrelerine dokunmuyor |
| DÜŞÜK | 1-2 | Dolaylı etki, tek parametre, geri alınabilir |
| ORTA | 3-4 | 2-3 parametre etkileniyor, davranış değişebilir |
| YÜKSEK | 5-7 | Monetizasyon akışı etkileniyor, enflasyon riski |
| KRİTİK | 8+ | Gelir modeli değişiyor, tüm tier'lar etkileniyor |

**Skor hesaplama:**
- Her etkilenen kategori: +1 puan
- Doğrudan monetizasyon etkisi: +2 puan
- Birden fazla tier etkileniyorsa: +1 puan
- Enflasyon/deflasyon riski: +2 puan
- Geri alınamaz değişiklik: +1 puan

## 7. Dinamik Doğrulama

### 7.1 Doğrulanan Dosyalar

| Dosya | Kontrol |
|-------|---------|
| `qulov2/lib/data/models/economy_config_model.dart` | Parametre yapısı |
| `qulo-server/src/services/economy-config.service.ts` | Server defaults |
| `qulov2/lib/data/models/power_model.dart` | Güç tipleri |

### 7.2 Doğrulama Süreci

1. Dosyaları oku → parametre isimlerini çıkar
2. Skill'deki statik modelle karşılaştır
3. Yapısal fark varsa → kullanıcıya uyar, güncelleme öner
4. Fark yoksa → statik modeli güvenle kullan

## 8. Raporlama Formatı

### 8.1 Etki Yoksa
```
Ekonomi Etkisi: YOK (0)
[Feature adı] ekonomi parametrelerine dokunmuyor. Devam ediliyor.
```

### 8.2 Etki Varsa
```
┌─────────────────────────────────────┐
│ EKONOMİ ETKİ ANALİZİ               │
├─────────────────────────────────────┤
│ Feature: [Feature adı]             │
│ Etki Seviyesi: [SEVİYE] ([skor])   │
├─────────────────────────────────────┤
│ Etkilenen Alanlar:                  │
│  • [Kategori] — [açıklama]         │
├─────────────────────────────────────┤
│ Riskler:                            │
│  1. [Risk açıklaması]              │
├─────────────────────────────────────┤
│ Öneriler:                           │
│  1. [Öneri + formül]               │
├─────────────────────────────────────┤
│ Gecmis Pattern:                     │
│  [Varsa benzer analizlerden bilgi]  │
└─────────────────────────────────────┘

Devam etmemi onaylıyor musun? [Evet / Ayarla / İptal]
```

## 9. Memory Entegrasyonu

### 9.1 Dosyalar

| Dosya | Konum | Amaç |
|-------|-------|------|
| economy_impact_log.md | memory/ | Geçmiş analizlerin logu |
| economy_suggestions.md | memory/ | Ekonomi iyileştirme önerileri |

### 9.2 Log Formatı

```markdown
## YYYY-MM-DD — [Feature Adı]
- **Etki:** [SEVİYE] ([skor])
- **Alanlar:** [etkilenen kategoriler]
- **Risk:** [risk açıklaması]
- **Öneri:** [yapılan öneri]
- **Karar:** [Devam / Ayarlandı / İptal]
```

### 9.3 Öğrenme Mekanizması

- Aynı kategorideki feature'lar için geçmiş analizleri referans göster
- Kullanıcının geçmiş kararlarını (kabul/red) gelecek önerilere yansıt
- Tekrar eden pattern'leri proaktif uyarıya dönüştür

## 10. CLAUDE.md Entegrasyonu

Mevcut otomatik review kurallarına ekleme:
```
- Feature geliştirmesi öncesi → economy-impact skill çalıştır
- Flutter/Server review'dan ÖNCE ekonomi analizi yapılmalı
```

## 11. Agent Geçiş Kuralları

- Etki YOK → otomatik devam, agent'a feature context ilet
- Etki DÜŞÜK → bilgi ver, otomatik devam
- Etki ORTA+ → kullanıcı onayı bekle
- Etki KRİTİK → plan moduna geç, detaylı analiz yap
