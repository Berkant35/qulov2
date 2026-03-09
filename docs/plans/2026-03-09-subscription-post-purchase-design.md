# Subscription Post-Purchase Flow & Aylık Haklar

## 1. Satın Alma Sonrası Akış

Başarılı subscription purchase sonrası:
1. SubscriptionComparisonScreen → Kutlama Dialog'u açılır
2. Dialog: Plan adı (gradient), kazanılan elmas animasyonlu, özellik listesi, "Harika!" butonu
3. Butona basınca → DiamondsScreen'e navigate (comparison screen pop)
4. Diamonds ekranı otomatik refresh (diamond + subscription provider invalidate)

## 2. Profile Ekranı

### İsim altı badge
- Kullanıcı adının altında gradient badge: "Plus" veya "Premium"
- Free kullanıcıda badge yok

### Menü satırı
- "Aboneliğim" satırı eklenir
- Aktif: plan adı + bitiş tarihi
- Free: "Ücretsiz Plan • Yükselt" → comparison screen'e yönlendir

## 3. Diamonds Ekranı — Aylık Haklarım Kartı

SubscriptionBanner altına yeni kart:

### Aktif abonelik
- Günlük Keşif: progress bar (12/50 veya ∞)
- Soru Slotu: progress bar (3/4, 3/6, 3/10)
- Günlük Geri Alma: progress bar (0/0, 1/3, ∞)
- Aylık Mor Elmas: check ikonu + miktar
- Pasaport Modu: Aktif/Kapalı
- Reklamlar: Yok/Var

### Free kullanıcı
- Aynı kart, düşük limitler + "Yükselt" CTA

## 4. Backend — Günlük Counter

### Endpoint
- GET /api/v1/users/me/daily-stats → günlük kullanım verileri

### Response
```json
{
  "dailyDiscoversUsed": 12,
  "dailyDiscoversLimit": 50,
  "dailyUndosUsed": 0,
  "dailyUndosLimit": 0,
  "questionsCreated": 3,
  "questionsLimit": 4
}
```

### Lazy reset
- Her discover/undo isteğinde daily_*_reset_at kontrol
- Tarih değiştiyse counter sıfırla (cron gerektirmez)

### Limit enforcement
- Discover endpoint'inde counter artır + limit aşıldıysa 403
- Undo endpoint'inde counter artır + limit aşıldıysa 403
