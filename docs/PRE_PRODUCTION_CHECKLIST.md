# Pre-Production Checklist — Qulo V2

Production'a çıkmadan önce tamamlanması gereken kritik işler.

## IAP & Ödeme Sistemi (KRİTİK)

- [ ] **Migration 008** çalıştır — `iap_transactions`, `user_subscriptions` tabloları + users kolonları
- [ ] **RevenueCat Webhook** entegrasyonu:
  - [ ] Backend'i public URL'e deploy et (Railway/Render/VPS)
  - [ ] RevenueCat Dashboard → Webhooks → URL ekle: `https://DOMAIN/api/v1/webhooks/revenuecat`
  - [ ] `REVENUECAT_WEBHOOK_SECRET`'i backend .env'ye ve RevenueCat'e ayarla
  - [ ] Webhook events seç: NON_RENEWING_PURCHASE, INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION
  - [ ] Test webhook gönder ve doğrula
- [ ] **Receipt Validation**: `purchaseHandler`'da Apple/Google receipt doğrulaması ekle (şu an client-trust)
- [ ] **Google Play ürünleri** oluştur (qulopurple50, qulopurple150, vs.)
- [ ] **RevenueCat Entitlements/Offerings** kur (Plus, Premium paketleri)
- [ ] `REVENUECAT_GOOGLE_KEY` env.dart'a ekle
- [ ] `env.dart`'taki RevenueCat Apple key'i defaultValue'dan kaldır → sadece `--dart-define` ile geç

## Güvenlik

- [ ] `env.dart`'taki tüm defaultValue'ları kaldır (Supabase key, RevenueCat key)
- [ ] JWT secret'ları production-grade secret'larla değiştir
- [ ] `ADMIN_SEED_PASSWORD` güçlendir
- [ ] `.env` dosyasının `.gitignore`'da olduğundan emin ol
- [ ] FIREBASE_SERVICE_ACCOUNT private key'i env variable'a taşı
- [ ] Rate limiting production değerlerine ayarla

## Backend Deploy

- [ ] Backend'i cloud'a deploy et
- [ ] `API_BASE_URL`'yi production URL ile güncelle
- [ ] HTTPS zorunlu kıl
- [ ] CORS origin'i production domain ile sınırla
- [ ] `NODE_ENV=production` ayarla

## Veritabanı

- [ ] Tüm migration'lar çalıştırıldı mı kontrol et (001-009)
- [ ] Index'lerin performansını kontrol et
- [ ] Backup stratejisi belirle

## Debug Temizliği

- [ ] `index.ts`'teki `/debug/test-labels` endpoint'ini kaldır
- [ ] `dev.log()` çağrılarını kaldır veya conditional yap
- [ ] `console.log` debug satırlarını temizle
