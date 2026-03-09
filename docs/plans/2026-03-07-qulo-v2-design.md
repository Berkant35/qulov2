# Qulo V2 - Tasarim Dokumani

**Tarih:** 2026-03-07
**Durum:** Onaylandi

---

## 1. Genel Bakis

Qulo, soru-cevap tabanli bir dating uygulamasidir. Kullanicilar 2-6 soru hazirlayarak profillerini olusturur. Eslesmek isteyen kisi bu sorulari dogru cevaplarsa eslesme saglanir. V2, v1'in Firebase-only mimarisini Supabase + backend sunucu mimarisine tasir ve tum kritik islemleri sunucu tarafina alir.

## 2. Mimari

```
Flutter Mobile (Riverpod + Dio)
    | REST API (HTTPS)
    v
Node.js + Express + TypeScript (api.qulo.app)
    |
    +--- Supabase (PostgreSQL + Realtime + Storage)
    +--- Firebase (FCM + Crashlytics + Analytics)
```

### Teknoloji Kararlari

| Katman | Teknoloji |
|--------|-----------|
| Mobile | Flutter + Riverpod |
| HTTP Client | Dio (interceptor + auto token refresh) |
| Backend | Node.js + Express + TypeScript |
| Database | Supabase PostgreSQL + PostGIS |
| Realtime Chat | Supabase Realtime (WebSocket channels) |
| File Storage | Supabase Storage |
| Push Notification | Firebase Cloud Messaging |
| Crash/Analytics | Firebase Crashlytics + Analytics |
| Auth | Custom (bcrypt + JWT) - email verified |
| IAP Dogrulama | Server-side receipt validation |
| Validation | Zod |

### Temel Prensipler
- Elmas islemleri sadece sunucudan
- Eslesme karari sunucudan
- IAP receipt dogrulama sunucudan
- JWT access (15dk) + refresh (30 gun) token
- Quiz cevaplari client'a gonderilmez

## 3. Veritabani Semasi

### users
```
id              UUID PK
email           TEXT UNIQUE
password_hash   TEXT
email_verified  BOOLEAN (default false)
verify_token    TEXT
name            TEXT
surname         TEXT
age             INT
gender          ENUM (MAN, WOMAN)
gender_pref     ENUM (MAN, WOMAN, BOTH)
bio             TEXT nullable
city            TEXT nullable
country         TEXT nullable
lat             DOUBLE nullable
lng             DOUBLE nullable
match_radius_km INT (default 50)
age_pref_min    INT (default 18)
age_pref_max    INT (default 45)
photos          TEXT[] (max 6)
green_diamonds  INT (default 0)
purple_diamonds INT (default 0)
is_online       BOOLEAN
push_token      TEXT nullable
passport_city   TEXT nullable
passport_lat    DOUBLE nullable
passport_lng    DOUBLE nullable
profile_completion INT (default 0)
locale          TEXT (default 'tr')
like_received_count INT (default 0)
times_shown_count   INT (default 0)
boost_until     TIMESTAMPTZ nullable
created_at      TIMESTAMPTZ
last_seen_at    TIMESTAMPTZ
```

### user_details (opsiyonel profil - asamali)
```
user_id   UUID FK->users PK
height    INT nullable
weight    INT nullable
zodiac    TEXT nullable
job       TEXT nullable
school    TEXT nullable
smoking   ENUM (YES, NO, SOMETIMES) nullable
alcohol   ENUM (YES, NO, SOMETIMES) nullable
pets      TEXT nullable
music_type TEXT nullable
personality TEXT nullable
```

### questions
```
id              UUID PK
user_id         UUID FK->users
order_num       INT (1-6)
question_text   TEXT
correct_answer  INT (1-4)
answer_1        TEXT
answer_2        TEXT
answer_3        TEXT
answer_4        TEXT
stats_correct   INT (default 0)
stats_wrong     INT (default 0)
UNIQUE(user_id, order_num)
```

### swipes
```
id          UUID PK
swiper_id   UUID FK->users
target_id   UUID FK->users
action      ENUM (LIKE, REJECT)
created_at  TIMESTAMPTZ
UNIQUE(swiper_id, target_id)
```

### quiz_sessions
```
id            UUID PK
solver_id     UUID FK->users
target_id     UUID FK->users
current_q     INT (default 1)
status        ENUM (IN_PROGRESS, COMPLETED, FAILED)
started_at    TIMESTAMPTZ
completed_at  TIMESTAMPTZ nullable
```

### quiz_answers
```
id              UUID PK
session_id      UUID FK->quiz_sessions
question_id     UUID FK->questions
selected_answer INT
is_correct      BOOLEAN
power_used      TEXT nullable
answered_at     TIMESTAMPTZ
```

### matches
```
id          UUID PK
user1_id    UUID FK->users
user2_id    UUID FK->users
matched_at  TIMESTAMPTZ
is_active   BOOLEAN (default true)
UNIQUE(user1_id, user2_id)
```

### messages
```
id          UUID PK
match_id    UUID FK->matches
sender_id   UUID FK->users
content     TEXT
is_image    BOOLEAN (default false)
read_at     TIMESTAMPTZ nullable
created_at  TIMESTAMPTZ
```

### diamond_transactions
```
id            UUID PK
user_id       UUID FK->users
type          ENUM (GREEN, PURPLE)
amount        INT (+ veya -)
reason        TEXT (QUIZ_CORRECT, IAP_PURCHASE, POWER_USED, POWER_REWARD, PASSPORT, BOOST)
reference_id  TEXT nullable
created_at    TIMESTAMPTZ
```

### powers
```
id          UUID PK
name        TEXT UNIQUE (COPY, HALF, SKIP, SKIP_ALL, TIME_EXTEND, HINT)
base_cost   INT
description TEXT
is_active   BOOLEAN (default true)
```

### iap_products
```
id                UUID PK
store_id_android  TEXT
store_id_ios      TEXT
purple_amount     INT
tier              INT (1-6)
is_active         BOOLEAN
```

### reports
```
id            UUID PK
reporter_id   UUID FK->users
reported_id   UUID FK->users
reason        TEXT
status        ENUM (PENDING, REVIEWED, RESOLVED)
created_at    TIMESTAMPTZ
```

## 4. API Endpoints

### Auth
```
POST /api/v1/auth/register
POST /api/v1/auth/verify-email
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password
```

### Users
```
GET    /api/v1/users/me
PATCH  /api/v1/users/me
PATCH  /api/v1/users/me/details
PATCH  /api/v1/users/me/location
POST   /api/v1/users/me/photos
DELETE /api/v1/users/me/photos/:index
PATCH  /api/v1/users/me/push-token
DELETE /api/v1/users/me
```

### Questions
```
GET    /api/v1/questions/me
POST   /api/v1/questions/me
PUT    /api/v1/questions/me/:order
DELETE /api/v1/questions/me/:order
GET    /api/v1/questions/count/me
```

### Matching
```
GET    /api/v1/match/discover
POST   /api/v1/match/swipe
GET    /api/v1/match/list
DELETE /api/v1/match/:match_id
```

### Quiz
```
POST   /api/v1/quiz/start
GET    /api/v1/quiz/:session_id
POST   /api/v1/quiz/:session_id/answer
GET    /api/v1/quiz/:session_id/result
```

### Diamonds
```
GET    /api/v1/diamonds/balance
GET    /api/v1/diamonds/history
POST   /api/v1/diamonds/purchase
```

### Powers
```
GET    /api/v1/powers
```

### Passport
```
POST   /api/v1/passport/activate
POST   /api/v1/passport/deactivate
```

### Chat
```
GET    /api/v1/chat/:match_id/messages
POST   /api/v1/chat/:match_id/messages
POST   /api/v1/chat/:match_id/read
```

### Reports
```
POST   /api/v1/reports
```

## 5. Elmas Ekonomisi

### Temel Kural
Yesil elmas sadece soru sahibi kazanir. Birisi sorularini cozerken mor elmas harcarsa, harcanan miktarin %30'u soru sahibine yesil elmas olarak gelir.

### Guc Maliyetleri (soru sayisina gore degisir)

Carpanlar:
- 2 soru: x0.5
- 3 soru: x0.75
- 4 soru: x1.0 (referans)
- 5 soru: x1.25
- 6 soru: x1.5

Baz maliyetler:
- COPY (Kopya Al): 15 mor elmas
- HALF (Sik Ele): 10 mor elmas
- SKIP (Soruyu Gec): 20 mor elmas
- SKIP_ALL (Hepsini Gec): 60 mor elmas
- TIME_EXTEND (Sure Uzat): 5 mor elmas
- HINT (Ipucu): 8 mor elmas
- PASSPORT (Pasaport Modu): 50 mor elmas / 24 saat

Yesil elmas harcama:
- BOOST (One Cikar): 30 yesil elmas -> 30dk discover'da ust siralarda

### IAP Tier'lar (Mor Elmas)
- Tier 1: 30 mor elmas
- Tier 2: 80 mor elmas
- Tier 3: 180 mor elmas
- Tier 4: 400 mor elmas
- Tier 5: 900 mor elmas
- Tier 6: 2000 mor elmas

## 6. Discover Algoritmasi (Hibrit Skor)

```
discover_score =
    (desirability_score  x 0.25)
  + (engagement_score    x 0.25)
  + (recency_score       x 0.20)
  + (distance_score      x 0.15)
  + (profile_score       x 0.10)
  + (compatibility_score x 0.05)
  + (boost_active ? 50 : 0)
```

### Desirability Score (ELO benzeri)
like_received / times_shown = like_ratio
- > 0.6 -> 10 puan
- > 0.4 -> 7
- > 0.2 -> 5
- > 0.1 -> 3
- geri kalan -> 1

### Engagement Score (Qulo'ya ozgu)
- quiz_completion_rate = tamamen cozulme / denenme
- Toplam kazanilan yesil elmas
- Guc kullanilma orani

### Recency Score
- Son 1 saat: 10
- Son 6 saat: 8
- Son 24 saat: 6
- Son 3 gun: 3
- Son 7 gun: 1
- 7 gun+: gosterilmez

### Distance Score
(1 - mesafe_km / max_radius) x 10

### Profile Score
profile_completion / 100 x 10 + foto bonus + bio bonus

### Filtreleme Kurallari
Gosterilmez: daha once swipe edilen, 7+ gun inaktif, sorusu olmayan, email unverified, cinsiyet/yas/mesafe uyumsuz
Oncelikli: boost aktif -> uste, seni LIKE'lamis -> hafif yukari

## 7. Chat & Bildirim Mimarisi

### Chat Akisi
1. Mesaj gonderme: her zaman backend API uzerinden
2. Mesaj alma: Supabase Realtime (WebSocket subscribe)
3. Offline: FCM push notification

### Bildirim Lokalizasyonu
- users.locale alani (tr | en)
- Backend push gonderirken alicinin locale'ine gore sablon secer
- Sablon dosyalari: server/src/locales/tr.json, en.json

### Push Tipleri
- NEW_MESSAGE: mesaj bildirimi
- NEW_MATCH: eslesme bildirimi
- QUIZ_STARTED: soru cozme basladi

## 8. Eslesme Akisi

```
Discover -> LIKE -> Quiz baslat
  -> Soru 1 dogru -> Soru 2 dogru -> ... -> Tum sorular dogru
    -> matches tablosuna yaz
    -> Her iki kullaniciya FCM push gonder
    -> Soru sahibine yesil elmas ekle
    -> Chat acilir

  -> Herhangi bir soru yanlis
    -> Session FAILED, eslesme yok
    -> Tekrar deneme icin yeni swipe gerekir
```

## 9. Guc Kullanma Akisi

```
Client: guc kullan istegi
  -> POST /quiz/:session_id/answer { power_used: "HALF" }

Sunucu (tek DB transaction):
  1. Session aktif mi kontrol
  2. Target'in soru sayisini cek -> carpan belirle
  3. Maliyet hesapla: ceil(baz_maliyet x carpan)
  4. Solver mor elmas bakiyesi yeterli mi?
     -> Hayir: 403 INSUFFICIENT_DIAMONDS
     -> Evet:
       5. solver.purple_diamonds -= maliyet
       6. target.green_diamonds += ceil(maliyet x 0.30)
       7. diamond_transactions loglari yaz
       8. Guc sonucunu don
```

## 10. Guvenlik

| Katman | Onlem |
|--------|-------|
| Auth | JWT access (15dk) + refresh (30 gun) |
| Email | Verification zorunlu |
| Elmas | Tum islemler sunucu tarafi + DB transaction |
| IAP | Server-side receipt validation |
| Quiz | Cevaplar client'a gonderilmez, sunucu timer |
| Rate Limit | Login: 5/dk, Discover: 30/dk, Chat: 60/dk |
| Input | Zod validation her endpoint'te |
| Upload | 5MB limit, jpg/png only |
| Report | 3+ sikayet -> otomatik inceleme |

### Quiz Anti-Cheat
- Sunucu tarafli timer (30sn/soru, TIME_EXTEND +15sn)
- Cevap sirasi sunucudan takip
- Paralel cevap engeli (mutex)
- Siklar her seferinde farkli sirada

### Hata Kodlari
```
AUTH:    INVALID_CREDENTIALS, EMAIL_NOT_VERIFIED, TOKEN_EXPIRED, EMAIL_ALREADY_EXISTS
QUIZ:    SESSION_EXPIRED, TIME_UP, ALREADY_ANSWERED, SESSION_NOT_FOUND
DIAMOND: INSUFFICIENT_DIAMONDS, INVALID_RECEIPT, DUPLICATE_RECEIPT
MATCH:   ALREADY_SWIPED, NO_QUESTIONS, SELF_SWIPE
CHAT:    NOT_MATCHED, MATCH_INACTIVE
USER:    PROFILE_INCOMPLETE, MAX_PHOTOS_REACHED, MAX_QUESTIONS_REACHED
GENERAL: RATE_LIMITED, VALIDATION_ERROR, SERVER_ERROR
```

Client tarafi hata kodlarini i18n key'e cevirip localize eder.

## 11. Proje Klasor Yapisi

### Backend
```
server/
  src/
    index.ts
    config/ (env, supabase, firebase)
    middleware/ (auth, validate, rateLimit)
    routes/ (auth, user, question, match, quiz, diamond, power, passport, chat, report)
    controllers/
    services/ (auth, user, matching, quiz, diamond, iap, chat, notification, scoring)
    validators/
    utils/ (jwt, hash, email, math)
    locales/ (tr.json, en.json)
    types/
    cron/ (scoring)
```

### Mobile
```
lib/
  main.dart
  app.dart
  core/ (config, network, theme, l10n, utils, constants)
  data/ (models, repositories, datasources)
  providers/
  features/ (auth, onboarding, discover, quiz, chat, diamonds, profile, passport, settings)
  shared/ (widgets, dialogs)
  routing/
```

## 12. UI Tarzi
- Renkli ve eglenceli
- Mor/yesil elmas temasina uygun palette
- v1'deki renk dili devam eder
