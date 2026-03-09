# Diamonds & IAP System Design

## Overview
Qulo V2 dating app icin in-app purchase sistemi. RevenueCat entegrasyonu ile consumable mor elmas paketleri ve 2 katmanli subscription (Plus/Premium). Tum monetizasyon mor elmas ekonomisi uzerinden doner.

## Urun Tipleri

### 1. Consumable — Mor Elmas Paketleri

| ID | Paket | Miktar | Fiyat | Store ID |
|---|---|---|---|---|
| 1 | Starter | 50 | $0.99 | `qulo_purple_50` |
| 2 | Popular | 150 | $2.49 | `qulo_purple_150` |
| 3 | Best Value | 400 | $4.99 | `qulo_purple_400` |
| 4 | Mega | 1000 | $9.99 | `qulo_purple_1000` |
| 5 | Ultra | 2500 | $19.99 | `qulo_purple_2500` |
| 6 | VIP | 6000 | $39.99 | `qulo_purple_6000` |

### 2. Subscription — 2 Katman

| Ozellik | Free | Qulo Plus ($4.99/ay) | Qulo Premium ($9.99/ay) |
|---|---|---|---|
| Store ID | - | `qulo_plus_monthly` | `qulo_premium_monthly` |
| Aylik mor elmas | - | 100 | 300 |
| Swipe limiti | 20/gun | 50/gun | Sinirsiz |
| Geri alma (undo) | - | 3/gun | Sinirsiz |
| Otomatik boost | - | 1x/hafta | 1x/gun |
| Kim bakti | - | - | ✓ |
| Reklam (match kart ici) | Var | Yok | Yok |
| Profil rozeti | - | Plus | Premium |

Not: Premium, Plus'in tum ozelliklerini kapsar.

## Teknik Mimari

### Akis Diyagrami

```
Flutter App (purchases_flutter)
       │
       ▼
  RevenueCat SDK ──────► Apple/Google Store
       │
       │ Webhook
       ▼
  Backend API (/api/v1/webhooks/revenuecat)
       │
       ▼
  Supabase DB (user_subscriptions, iap_transactions, diamond_transactions)
```

### RevenueCat Yapisi

- **Offerings:** `default` offering, 3 package grubu (consumables, plus, premium)
- **Entitlements:** `plus`, `premium`
- **Webhook:** RevenueCat → `POST /api/v1/webhooks/revenuecat` → DB guncelle

### Backend Yeni Endpoint'ler

| Method | Route | Aciklama |
|---|---|---|
| POST | `/api/v1/webhooks/revenuecat` | Webhook handler |
| GET | `/api/v1/subscriptions/status` | Aktif subscription durumu |
| POST | `/api/v1/subscriptions/restore` | Satin alma geri yukleme |

### Webhook Islem Akisi

**Consumable satin alma:**
1. RevenueCat webhook → `INITIAL_PURCHASE` event
2. Backend product_id'den mor elmas miktarini bul
3. `diamond.service.addPurple(userId, amount, 'IAP_PURCHASE', transactionId)`
4. Transaction log kaydi

**Subscription baslama:**
1. RevenueCat webhook → `INITIAL_PURCHASE` veya `RENEWAL`
2. `user_subscriptions` tablosuna kayit (plan, baslangic, bitis)
3. Aylik mor elmas bonusu kredile
4. User'a entitlement flag'leri set et

**Subscription iptal/sure dolma:**
1. RevenueCat webhook → `EXPIRATION` veya `CANCELLATION`
2. `user_subscriptions` tablosunda status guncelle
3. Entitlement'lar kalk

### Yeni DB Tablolari

```sql
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  plan TEXT NOT NULL, -- 'plus' | 'premium'
  status TEXT NOT NULL, -- 'active' | 'expired' | 'cancelled'
  rc_customer_id TEXT,
  store_transaction_id TEXT,
  started_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE iap_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  product_id TEXT NOT NULL,
  store TEXT NOT NULL, -- 'apple' | 'google'
  transaction_id TEXT UNIQUE,
  rc_event_type TEXT,
  amount_usd DECIMAL(10,2),
  purple_credited INT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### iap_products Tablosu Guncelleme

Mevcut seed data guncellenmeli:

```sql
TRUNCATE iap_products;
INSERT INTO iap_products (store_id_ios, store_id_android, purple_amount, tier, is_active) VALUES
('qulo_purple_50', 'qulo_purple_50', 50, 1, true),
('qulo_purple_150', 'qulo_purple_150', 150, 2, true),
('qulo_purple_400', 'qulo_purple_400', 400, 3, true),
('qulo_purple_1000', 'qulo_purple_1000', 1000, 4, true),
('qulo_purple_2500', 'qulo_purple_2500', 2500, 5, true),
('qulo_purple_6000', 'qulo_purple_6000', 6000, 6, true);
```

## Flutter Tarafi

### Yeni Paketler
- `purchases_flutter` (RevenueCat SDK)

### Yeni Provider'lar
- `SubscriptionProvider` — aktif plan durumu (RevenueCat SDK'dan)
- `PurchaseService` — satin alma tetikleme, restore

### Mevcut Guncelleme
- `DiamondProvider` — bakiye webhook sonrasi client yeniden fetch eder
- `DiamondsScreen` — yeniden tasarlanacak (asagida)

## Diamonds Ekrani UI

### Ana Ekran Yapisi

```
┌─────────────────────────────┐
│  ← Elmaslarim               │  (AppBar)
├─────────────────────────────┤
│  mor: 1,250     yesil: 340  │  (Bakiye karti)
├─────────────────────────────┤
│  ┌─ Subscription Banner ──┐ │
│  │ Qulo Premium'a gec!    │ │
│  │ 300 elmas/ay + sinirsiz│ │
│  │ [Planlari Gor]          │ │
│  └────────────────────────┘ │
├─────────────────────────────┤
│  Mor Elmas Paketleri        │  (Section header)
│  ┌──────┐ ┌──────┐ ┌──────┐│
│  │  50  │ │ 150  │ │ 400  ││  (3x2 grid)
│  │$0.99 │ │$2.49 │ │$4.99 ││
│  └──────┘ └──────┘ └──────┘│
│  ┌──────┐ ┌──────┐ ┌──────┐│
│  │ 1000 │ │ 2500 │ │ 6000 ││
│  │$9.99 │ │$19.99│ │$39.99││
│  └──────┘ └──────┘ └──────┘│
├─────────────────────────────┤
│  Islem Gecmisi        [Tumu]│
│  + 300 mor  Premium bonus   │
│  - 20 mor   SKIP kullanildi │
│  + 6 yesil  Guc odulu       │
└─────────────────────────────┘
```

- Subscriber ise banner yerine aktif plan badge gosterilir
- "Best Value" paketine ozel etiket
- Islem gecmisi en son 5 kayit, "Tumu" ile tam listeye git

### Subscription Karsilastirma Sayfasi

"Planlari Gor" butonuna basinca full-screen modal:

```
┌─────────────────────────────┐
│  × Planini Sec              │
├──────────┬──────────────────┤
│  FREE    │  Gunluk 20 swipe │
│          │  Reklam var       │
├──────────┼──────────────────┤
│  PLUS    │  50 swipe/gun    │
│ $4.99/ay │  100 elmas/ay    │
│          │  3 geri alma/gun │
│          │  Haftalik boost  │
│          │  Reklam yok      │
│  [Basla] │                  │
├──────────┼──────────────────┤
│ PREMIUM  │  Sinirsiz swipe  │
│ $9.99/ay │  300 elmas/ay    │
│  ONERI   │  Sinirsiz geri al│
│          │  Gunluk boost    │
│          │  Kim bakti       │
│          │  Reklam yok      │
│  [Basla] │                  │
└──────────┴──────────────────┘
```

## Upsell & Tetikleyici Sistem

### Tetikleyiciler

| Tetikleyici | Kosul | Gosterim | Cooldown |
|---|---|---|---|
| Onboarding | Kayit tamamlandi, ilk ana ekrana gecis | Premium tanitim (full bottom sheet) | 1 kez |
| Elmas bitti | Guc kullanmak istedi, bakiye yetersiz | Consumable paketler (compact sheet) | 24 saat |
| Ilk match | Ilk match olustugunda | Plus/Premium tanitim | 1 kez |
| Swipe limit | Gunluk swipe limiti doldu | Plus/Premium (limit vurgusu) | Oturum basina 1 |
| 3. gun | Kayittan 3 gun sonra, aktif kullanici | Ozel %20 indirim teklifi | 1 kez |
| Boost ihtiyaci | Boost yapmak isteyip elmasi yokken | Consumable paketler | 12 saat |

### Cooldown & Spam Onleme Kurallari

- `SharedPreferences` ile son gosterim zamani + sayisi tutulur
- Bir oturumda **maksimum 2 upsell** gosterilir
- Kullanici zaten Plus/Premium ise subscription upsell gosterilmez (sadece consumable)
- 3. gun indirimi: RevenueCat Promotional Offers API kullanilir

### Bottom Sheet Tipleri

**1. Premium Tanitim (Full Sheet)** — Onboarding, ilk match
- Ustte Premium/Plus karsilastirma
- One cikan ozellikler listesi (ikon + aciklama)
- 2 buton: "Plus Basla" / "Premium Basla"
- Altta "Belki sonra" linki

**2. Consumable Paket (Compact Sheet)** — Elmas bitti, boost ihtiyaci
- "Elmaslarin bitti!" basligi
- 6 paketin grid'i (en populer vurgulu)
- Tek tap ile satin alma

**3. Limit Uyarisi Sheet** — Swipe limit
- "Bugünlük swipe hakkin doldu"
- Plus/Premium ile sinirsiz swipe vurgusu
- Upgrade butonu

## Onemli Kurallar

- Super begeni YOK — tum monetizasyon mor elmas uzerinden
- Reklam match karti icinde gosteriliyor (interstitial degil)
- Plus ve Premium'da reklam kalkiyor
- Server-side receipt validation zorunlu (cheat onleme)
- RevenueCat webhook ile backend bilgilendirilir
- Consumable alimlarda aninda mor elmas kredilenir
