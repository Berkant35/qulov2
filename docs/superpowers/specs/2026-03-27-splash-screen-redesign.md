# Splash Screen Redesign — Glitch Reveal

## Özet
Mevcut splash ekranını (soru yağmuru + "Sor/Cevapla/Eşleş" timeline) kaldırıp, minimal ama vurucu bir **glitch reveal** animasyonuyla değiştiriyoruz. Sadece logo, güçlü bir giriş animasyonu, temiz arka plan.

## Kararlar
| Karar | Seçim |
|-------|-------|
| Hissiyat | Kinetik & Enerjik |
| Logo girişi | Glitch Reveal (RGB shift, scan lines, slice displacement) |
| Arka plan | Sade derin mor/siyah gradient |
| Süre | ~3s minimum, auth check'e bağlı dinamik |
| QULO text | Kaldırılıyor — sadece logo |
| Yaklaşım | Pure Flutter (CustomPainter + AnimationController) |

## Kaldırılan Elementler
- `SplashFlowStory` — "Sor / Cevapla / Eşleş" timeline
- `QuestionRain` — Düşen soru işaretleri arka plan
- `SplashText` — "QULO" staggered text animasyonu

## Yeni Tasarım

### Arka Plan
- Lineer gradient: `#0D0015` (üst) → `#1A0A2E` (alt)
- Radial gradient overlay: merkezde `#2D1B4E` @ %15 opacity (spotlight)
- Statik, animasyonsuz

### Glitch Reveal Animasyonu

**Teknik: Slice-Based Glitch**
- Logo görüntüsü 10-15 yatay slice'a bölünür
- Her slice bağımsız olarak animasyonlanır

**Fazlar:**

#### Faz 1 — Kaos (0-600ms)
- Logo slice'ları rastgele X offset ile kayıyor (±20-40px)
- RGB channel separation: R/G/B kanalları ayrı offset'lerle render
- Opacity flicker: 0.3-1.0 arası rastgele (her 50-80ms)
- İnce yatay scan line overlay (2px, %20 opacity beyaz)
- Genel opacity 0→1 (ilk 200ms'de fade in)

#### Faz 2 — Stabilize (600-1000ms)
- Slice offset'leri easeOut ile 0'a dönüyor
- RGB separation azalıyor → tekrar birleşiyor
- Flicker durarak sabit opacity 1.0'a geçiyor
- Scan line'lar fade out

#### Faz 3 — Glow Settle (1000-1500ms)
- Logo stabilize olduktan sonra hafif bir neon pulse (mevcut glow efektinden esinlenilmiş)
- Tek pulse: glow alpha 0→0.4→0.2 (settle)
- Mor glow: `primary` renk, blur radius 40-60px

#### Faz 4 — Hold & Auth (1500ms+)
- Logo sabit, hafif glow ile bekliyor
- Auth check paralel çalışıyor (splash başlangıcından itibaren)
- Minimum gösterim: ~3 saniye (animasyon + hold)
- Auth tamamlanınca fade out → sonraki ekran

### Geçiş (Exit)
- Tüm ekran fade out (300ms)
- Veya logo scale up + fade (zoom-out hissi)

## Dosya Yapısı (Sonrası)

```
lib/features/splash/
├── splash_screen.dart          # Orchestration (güncellenir)
├── mixins/
│   └── splash_screen_mixin.dart # Yeni timing (güncellenir)
└── widgets/
    ├── splash_logo.dart         # Glitch reveal + glow (yeniden yazılır)
    ├── glitch_painter.dart      # NEW — CustomPainter for glitch slices
    ├── splash_text.dart         # SİLİNECEK
    ├── splash_flow_story.dart   # SİLİNECEK
    └── question_rain.dart       # SİLİNECEK
```

## Animasyon Controller'lar
- `_glitchController` — 1000ms, kaos→stabilize (Faz 1-2)
- `_glowController` — 500ms, settle pulse (Faz 3)
- `_holdTimer` — Auth check + minimum süre mantığı

## Performans
- `RepaintBoundary` ile logo izole edilir
- Glitch efekti `CustomPainter` + `Canvas.clipRect` ile slice render
- RGB separation: `ColorFilter` veya `BlendMode` ile (3 pass render)
- 60fps hedef — slice sayısı 10-12 ile sınırlı

## Lokalizasyon
- `splash_flow_ask`, `splash_flow_answer`, `splash_flow_match` key'leri artık kullanılmıyor
- Silinebilir veya gelecekte başka yerde kullanılmak üzere bırakılabilir

## Analytics
- `splash_duration` metric'i korunuyor, yeni timing ile güncelleniyor
