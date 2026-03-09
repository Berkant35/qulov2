# Exchange Center (Dönüşüm Merkezi) — Design Document

## Özet

Yeşil elmasları mor elmaslara dönüştürme + power haklarını önceden satın alma sistemi. Quiz sırasında envanterdeki haklar öncelikli kullanılır, yoksa anlık mor elmas ödemesi devam eder.

---

## 1. Veritabanı

### Yeni tablo: `user_power_inventory`

```sql
CREATE TABLE user_power_inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  power_name TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0 CHECK (count >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, power_name)
);
```

### Yeni tablo: `power_purchase_transactions`

```sql
CREATE TABLE power_purchase_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  power_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  diamond_type diamond_type NOT NULL,
  total_cost INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### `powers` tablosuna yeni kolonlar

```sql
ALTER TABLE powers ADD COLUMN green_cost INTEGER NOT NULL DEFAULT 0;
ALTER TABLE powers ADD COLUMN purple_cost INTEGER NOT NULL DEFAULT 0;
ALTER TABLE powers ADD COLUMN accuracy_rate DECIMAL DEFAULT NULL;
```

### COPY → ORACLE değişikliği

```sql
UPDATE powers SET name = 'ORACLE', base_cost = 5, accuracy_rate = 0.70 WHERE name = 'COPY';
```

---

## 2. Power Tablosu (Güncel)

| Power | Mor (Anlık base_cost) | Açıklama | Accuracy |
|-------|----------------------|----------|----------|
| ORACLE | 5 | Bir şık önerir — %70 doğru, %30 yanlış | 0.70 |
| TIME_EXTEND | 5 | +15 saniye | - |
| HINT | 8 | İpucu göster | - |
| HALF | 10 | 2 yanlış şıkkı ele | - |
| SKIP | 20 | Soruyu doğru say, geç | - |
| SKIP_ALL | 60 | Tüm kalanları doğru say | - |

- `green_cost` ve `purple_cost` backoffice'ten ayarlanır (Dönüşüm Merkezi fiyatları)
- `accuracy_rate` sadece ORACLE için kullanılır, backoffice'ten ayarlanabilir

---

## 3. Yeşil → Mor Dönüşüm

- **Oran**: 3:1 (3 yeşil = 1 mor)
- Dönüşüm oranı `app_settings` veya env variable'dan yönetilir
- `diamond_transactions` tablosuna 2 kayıt: GREEN çıkış + PURPLE giriş (`reason: GREEN_TO_PURPLE_CONVERT`)
- Atomik işlem: yeşil bakiye kontrolü + güncelleme

---

## 4. Backend API

### Yeni endpoint'ler

```
POST /api/v1/exchange/convert        — Yeşil → Mor dönüşüm
  Body: { green_amount: 30 }
  Response: { purple_received: 10, new_balance: { green, purple } }

POST /api/v1/exchange/buy-power      — Power hakkı satın al
  Body: { power_name: "ORACLE", diamond_type: "GREEN", quantity: 1 }
  Response: { new_count: 4, new_balance: { green, purple } }

GET  /api/v1/exchange/inventory      — Kullanıcının power envanteri
  Response: { inventory: [{ power_name, count }] }

GET  /api/v1/exchange/rates          — Dönüşüm oranı + power fiyatları
  Response: { convert_ratio: 3, powers: [{ name, green_cost, purple_cost, accuracy_rate? }] }
```

### Quiz entegrasyonu (answerQuestion değişikliği)

```
1. power_used geldi → user_power_inventory'de count > 0?
2. Evet → count-- (atomik), elmas harcanmaz
3. Hayır → mevcut akış: mor elmas harcanır (base_cost × multiplier)
4. ORACLE: Math.random() < accuracy_rate ? doğru cevap : rastgele yanlış cevap
```

---

## 5. Flutter — Dosya Yapısı

### Yeni dosyalar

```
lib/features/exchange/screens/exchange_screen.dart
lib/features/exchange/widgets/convert_section.dart
lib/features/exchange/widgets/power_shop_card.dart
lib/core/widgets/power_icon.dart
lib/core/network/services/exchange_service.dart
lib/data/repositories/exchange_repository.dart
lib/providers/exchange_provider.dart
```

### Değişen dosyalar

```
lib/features/quiz/widgets/power_bar.dart          — PowerIcon kullanımı + envanter badge
lib/features/diamonds/screens/diamonds_screen.dart — Dönüşüm Merkezi butonu eklenir
lib/core/constants/q_icons.dart                    — ic_oracle.svg eklenir
lib/routing/                                       — /exchange route eklenir
```

---

## 6. Dönüşüm Merkezi Ekranı

Route: `/exchange` (Diamonds ekranından navigate)

### Düzen (tek scroll)

1. **Balance Card** — Mor + yeşil bakiye (mevcut widget reuse)
2. **Elmas Dönüşümü** — Miktar input (3'ün katları) + anlık hesaplama + Dönüştür butonu
3. **Power Hakları** — 6 power kartı: ikon + başlık + açıklama + envanter badge + mor/yeşil satın al butonları

### Animasyonlar

- Dönüştür: yeşil→mor parçacık animasyonu
- Satın alma: envanter sayısı scale bounce
- Power kartı: tıklayınca açıklama expand

---

## 7. Power İkon Sistemi

Merkezi widget: `lib/core/widgets/power_icon.dart`

```dart
enum PowerType { oracle, half, skip, skipAll, timeExtend, hint }

class PowerIcon extends StatelessWidget {
  final PowerType type;
  final double size;
  final bool showLabel;
  final bool showCount;
  final int? count;
}
```

| Power | SVG | Renk |
|-------|-----|------|
| ORACLE | ic_oracle.svg | Mor/mistik |
| HALF | ic_split.svg | Kırmızı |
| SKIP | ic_skip_forward.svg | Mavi |
| SKIP_ALL | ic_fast_forward.svg | Mor |
| TIME_EXTEND | ic_clock.svg | Yeşil |
| HINT | ic_lightbulb.svg | Turuncu |

Tüm projede power ikonu sadece bu widget'tan kullanılır.

---

## 8. Quiz İçi ORACLE UX

- Kullanıcı ORACLE'a basar
- Backend %70/%30 hesaplar, önerilen şık index'i döner
- Önerilen şık üzerinde mistik mor aura/pulse animasyonu
- Uyarı: "Kahin önerisi — garanti değil!"
- Kullanıcı istediği şıkkı seçer (awaiting_answer: true)

---

## 9. Quiz Power Bar Değişiklikleri

- COPY chip → ORACLE olarak değişir
- Envanterde hak varsa chip üzerinde badge (×3)
- Envanterdeyse farklı renk tonu (bedava hissi)
- Kullanılınca badge scale bounce ile azalır
- Envanterde yoksa mevcut davranış: anlık mor elmas ödemesi
