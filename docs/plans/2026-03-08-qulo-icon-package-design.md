# Qulo İkon Paketi Tasarımı

## Kararlar
- **Yaklaşım:** Hibrit — SVG tabanlı, icon font yok
- **Yöntem:** flutter_svg + Dart sabitleri (QIcons class)
- **Geçiş:** Kademeli — önce temizlik, sonra kritik ekranlar
- **İkon seti:** Lucide (açık kaynak, rounded/soft stil)
- **İkon temin:** Otomatik, kullanıcı müdahalesi yok

## Mimari

### QIcons Class (`lib/core/constants/q_icons.dart`)
Tüm ikon path'lerinin tek merkezi. İki kategori:
- Lucide SVG ikonlar (tek renkli, tema uyumlu)
- Branded SVG'ler (çok renkli, özel)

### QIcon Widget (`lib/core/widgets/q_icon.dart`)
SvgPicture.asset() sarmalayıcısı, tema rengi otomatik.

## Asset Klasör Yapısı

```
assets/
├── icons/          → Lucide SVG ikonlar (ic_ prefix, tek renkli)
├── brand/          → Qulo'ya özgü görseller (elmaslar, logo, splash)
├── illustrations/  → Dekoratif SVG'ler (beer, coffee, shapes vb.)
└── lottie/         → Animasyonlar (değişmez)
```

## İsimlendirme Kuralı
- Tümü snake_case
- İkonlar: `ic_` prefix → `ic_heart.svg`
- Brand: prefix yok → `green_diamond.svg`
- İllüstrasyonlar: prefix yok → `no_message.svg`

## Kademeli Geçiş Planı

### Faz 1 — Temizlik & Altyapı
- Mevcut asset'leri yeni klasör yapısına taşı ve yeniden adlandır
- Kullanılmayan dosyaları sil (QuloIcon.ttf, duplicate PNG/SVG'ler)
- QIcons class + QIcon widget oluştur
- AppAssets'i güncelle

### Faz 2 — Kritik Ekranlar (Lucide geçişi)
- Bottom navigation
- Profile screen
- Discover screen
- Quiz power bar

### Faz 3 — Geri Kalan (sonraki iterasyon)
- Auth ekranları
- Settings
- Chat detay
- Diğer Material icon kullanımları

## Silinecekler
- assets/fonts/QuloIcon.ttf
- Duplicate dosyalar: man.png+man.svg, woman.png+woman.svg
- Tutarsız adlı dosyalar yeniden adlandırılacak

## Lucide İkon Eşleştirmesi

| Material Icon | Lucide Dosya | Kullanım |
|---|---|---|
| Icons.explore | ic_compass | Bottom nav - Keşfet |
| Icons.favorite | ic_heart | Bottom nav - Eşleşmeler |
| Icons.person | ic_user | Bottom nav - Profil |
| Icons.diamond | ic_gem | Elmas ekranı |
| Icons.settings | ic_settings | Profil ayarlar |
| Icons.send | ic_send | Chat mesaj gönder |
| Icons.bolt | ic_zap | Boost güç |
| Icons.edit | ic_pencil | Profil düzenle |
| Icons.location_on | ic_map_pin | Konum |
| Icons.close | ic_x | Kapat butonları |
| Icons.visibility | ic_eye | Görüntülenme |
| Icons.logout | ic_log_out | Çıkış |
| Icons.quiz | ic_help_circle | Sorular |
| Icons.add | ic_plus | Ekle butonları |
| Icons.timer | ic_clock | Süre uzatma |
| Icons.skip_next | ic_skip_forward | Pas geç |
| Icons.lightbulb_outline | ic_lightbulb | İpucu |
| Icons.language | ic_globe | Dil seçimi |
| Icons.delete_forever | ic_trash_2 | Hesap sil |
| Icons.lock_outline | ic_lock | Şifre |
| Icons.email_outlined | ic_mail | E-posta |
| Icons.cake_outlined | ic_cake | Doğum günü |
| Icons.chevron_right | ic_chevron_right | Navigasyon oku |
| Icons.arrow_back | ic_arrow_left | Geri butonu |
| Icons.check_circle | ic_check_circle | Onay |
| Icons.call_split | ic_split | Yarı yarıya güç |
| Icons.copy | ic_copy | Kopyala güç |
| Icons.fast_forward | ic_fast_forward | Hepsini geç |
| Icons.favorite_border | ic_heart | Boş kalp |
| Icons.male | ic_male (mevcut) | Cinsiyet |
| Icons.female | ic_female (mevcut) | Cinsiyet |
