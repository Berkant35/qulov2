# Qulo V2 Backoffice - Tasarim Dokumani

**Tarih:** 2026-03-07
**Durum:** Onaylandi

---

## 1. Genel Bakis

Qulo V2 backend'ine entegre, EJS template'li server-side rendered backoffice paneli.
Gorunumun cok onemli olmadigi, islevsel ve guvenli bir admin arayuzu.

## 2. Mimari

- Ayni Express server uzerine `/admin` prefix'li route'lar
- EJS template engine ile server-side render
- Basit CSS (framework yok, minimal styling)
- Ayri `admin_users` tablosu, normal kullanicilardan izole

## 3. Guvenlik Katmanlari

| Katman | Detay |
|--------|-------|
| Auth | Session-based (httpOnly + secure + sameSite cookie) |
| Password | bcrypt hash |
| CSRF | Her form'da CSRF token |
| Rate Limit | Login: 5 deneme/15dk |
| IP Whitelist | Opsiyonel — ADMIN_ALLOWED_IPS env variable (bossa herkes, doluysa sadece o IP'ler) |
| Helmet | Mevcut, CSP header'lari guclendirilecek |
| Session Timeout | 2 saat inaktivite sonrasi otomatik cikis |

## 4. Veritabani

```
admin_users
  id              UUID PK
  email           TEXT UNIQUE
  password_hash   TEXT
  role            ENUM (SUPER_ADMIN, ADMIN)
  created_at      TIMESTAMPTZ
  last_login_at   TIMESTAMPTZ nullable
```

- SUPER_ADMIN: admin ekleme/silme yetkisi
- ADMIN: sadece goruntuleme + moderasyon

## 5. Sayfalar

1. **Login** (`/admin/login`) — email + password formu
2. **Dashboard** (`/admin/`) — toplam/aktif kullanici, bugunku kayit, eslesme sayisi, elmas dolasimi
3. **Kullanicilar** (`/admin/users`) — sayfali liste, arama (email/isim), filtre (gender, online)
   - Detay (`/admin/users/:id`) — profil bilgileri, sorulari, fotograflar, elmas bakiyesi, son aktivite
   - Aksiyonlar: ban/unban, sil, elmas bakiyesi duzenle
4. **Raporlar** (`/admin/reports`) — PENDING/REVIEWED/RESOLVED filtreli liste
   - Detay: raporlayan + raporlanan bilgisi, aksiyon (uyar/ban/reddet)
5. **Eslesmeler** (`/admin/matches`) — liste (tarih, kullanicilar), aktif/pasif filtre
6. **Elmas Islemleri** (`/admin/transactions`) — transaction log, kullanici/tip/tarih filtre
7. **Quiz Istatistikleri** (`/admin/quiz-stats`) — toplam oturum, basari orani, guc kullanim dagilimi
8. **Admin Yonetimi** (`/admin/admins`) — sadece SUPER_ADMIN gorebilir, admin ekle/sil

## 6. Dosya Yapisi

```
server/src/
  admin/
    admin.routes.ts        — tum admin route'lar
    admin.controller.ts    — controller logic
    admin.service.ts       — DB sorgulari
    admin.middleware.ts     — session auth, IP whitelist, CSRF
    views/
      layout.ejs           — ortak layout (nav, footer)
      login.ejs
      dashboard.ejs
      users.ejs
      user-detail.ejs
      reports.ejs
      report-detail.ejs
      matches.ejs
      transactions.ejs
      quiz-stats.ejs
      admins.ejs
```

## 7. Seed Admin

Ilk SUPER_ADMIN `.env`'den seed edilecek:
```
ADMIN_SEED_EMAIL=admin@qulo.app
ADMIN_SEED_PASSWORD=...
```
Server baslandiginda bu admin yoksa otomatik olusturulur.

## 8. Bagimliliklar

- `ejs` — template engine
- `express-session` — session yonetimi
- `crypto` (built-in) — CSRF token uretimi
- `connect-pg-simple` veya in-memory session store
