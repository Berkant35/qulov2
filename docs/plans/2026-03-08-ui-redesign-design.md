# Qulo V2 — UI Redesign Design

**Goal:** Mevcut kurumsal Material 3 tasarimini, koyu temali, neon aksanli, genc hedef kitleye yonelik bir dating app tasarimina donusturmek. Tinder/Bumble UX pattern'leri + Qulo'nun soru-cevap kimligi.

**Architecture:** Flutter tema sistemi uzerinden global degisiklik (AppColors, AppTheme, component themes). Ekran bazinda widget yeniden yazimi. Mevcut provider/repository/routing yapisi korunur.

**Tech Stack:** Flutter, Riverpod, GoRouter, mevcut AppScaffold + core widgets

---

## Genel Tasarim Dili

### Renk Paleti (Koyu Tema)
- **Background**: `#0D0D0D` (ana arka plan), `#121212` (scaffold)
- **Surface**: `#1A1A1A` (kartlar), `#242424` (elevated surface), `#2A2A2A` (input bg)
- **Primary (Mor neon)**: `#BB86FC` (ana), `#9C27B0` (koyu), `#E1BEE7` (acik)
- **Secondary (Yesil neon)**: `#69F0AE` (ana), `#4CAF50` (koyu), `#B9F6CA` (acik)
- **Error**: `#CF6679`
- **Text**: `#FFFFFF` (primary), `#B0B0B0` (secondary), `#666666` (hint)
- **Border**: Mor/yesil gradient (1px, subtle glow)

### Tipografi
- Mevcut Poppins font ailesi korunur
- Basliklar: Bold, beyaz
- Body: Regular, beyaz/gri
- Label: Medium, gri

### Komponent Kurallari
- Kartlar: Koyu yuzey (#1A1A1A), 16px radius, ince gradient border opsiyonel
- Butonlar: Mor gradient dolgu, 52px yukseklik, 12px radius
- Input: Koyu arka plan (#2A2A2A), beyaz metin, mor focus border
- Bottom nav: Koyu (#1A1A1A), ust kenarda ince mor cizgi
- Divider: #2A2A2A (cok subtle)

---

## 1. Discover Ekrani (Hybrid Swipe + Quiz)

### Layout
- Swipeable card stack (3 kart ust uste, arkadakiler kuculur)
- Kart: Tam fotograf, altta siyah gradient overlay

### Kart Icerigi
- Alt bolum (gradient overlay uzerinde):
  - Isim + yas (headlineSmall, bold, beyaz)
  - Konum ikonu + sehir + mesafe (bodySmall, gri)
  - Soru sayisi badge (mor pill: "4 soru")

### Aksiyonlar
- Kart altinda: "Tanimak icin X soruyu coz" gradient buton (ana CTA)
- Sol/sag swipe: Dislike (kirmizi glow) / Like (yesil glow)
- Quiz cozmeden eslesme olmaz — swipe sadece ilgi gosterir
- Sag ustte "?" ikonu → quiz'e direkt giris

### Bos State
- "?" animasyonu + "Yakinlarda kimse yok" mesaji

---

## 2. Matches Ekrani (Chat List + Ust Bolum)

### Ust Bolum — Yeni Eslesmeler
- Baslik: "Yeni Eslesmeler" (titleMedium, beyaz)
- Yatay scroll: Daire avatarlar (56px)
  - Mor neon halka = okunmamis mesaj
  - Yesil nokta (sag alt) = online
  - Isim altinda (labelSmall, gri)

### Alt Bolum — Sohbet Listesi
- Koyu kart satirlar (ListTile tarzi ama koyu)
- Avatar (48px) + isim (bold, beyaz) + son mesaj preview (bodySmall, gri, 1 satir)
- Sagda: zaman (labelSmall, gri) + okunmamis sayi badge (mor daire, beyaz yazi)
- Satirlar arasi 8px bosluk (divider yok)

### Bos State
- Kalp + "?" ikonu
- "Sorulari coz, eslesmeleri bul"

---

## 3. Profil Ekrani (Card-Based Moduler)

### Fotograf Bolumu
- Rounded kart (16px), golge, ekranin %35'i
- ClipRRect ile cached image

### Bilgi Bolumu
- Isim + yas: headlineMedium, bold, beyaz
- Sehir: bodyMedium, gri

### Istatistik Kartlari (2x2 Grid)
Her biri koyu kart (#1A1A1A) + ikon + deger + label:
- Soru sayisi (quiz ikonu, mor)
- Eslesme sayisi (kalp ikonu, yesil)
- Mor elmas bakiyesi (mor elmas ikonu)
- Yesil elmas bakiyesi (yesil elmas ikonu)

### Sorularim Preview
- Yatay scroll'da soru kartlari
- Koyu kart, mor border, soru metni, "?" numarasi

### Menu
- Profili duzenle, Passport, Ayarlar
- Koyu ListTile'lar, chevron trailing, mor ikon

---

## 4. Chat Ekrani (Minimal & Temiz)

### AppBar
- Avatar (kucuk, 32px) + isim + online/offline durum (yesil/gri nokta)
- Koyu arka plan

### Mesaj Balonlari
- Gonderen: Mor gradient arka plan (#9C27B0 → #7B1FA2), beyaz metin
- Alinan: Koyu gri (#2A2A2A), beyaz metin
- Max genislik %75
- Rounded: 16px genel, gonderenin sag alt / alinanin sol alt kosesi 4px
- Zaman damgasi: Balon altinda, labelSmall, gri

### Input Alani
- Koyu arka plan (#2A2A2A), rounded (999px)
- Mor gradient gonder butonu (IconButton.filled)
- SafeArea alt

---

## 5. Bottom Navigation

- Koyu arka plan (#1A1A1A)
- Ust kenarda ince mor cizgi (1px, #BB86FC %50 opacity)
- 3 tab: Discover (pusula), Matches (kalp), Profile (kisi)
- Secili: Mor neon ikon + label
- Secilmemis: Gri ikon, label yok

---

## 6. Splash & Auth Ekranlari

### Splash
- Siyah arka plan
- Logo: Mor neon glow efekti ile fade-in + scale
- "QULO" text: Beyaz, letter-spacing

### Login
- Koyu tema arka plan
- Logo ust orta
- Input'lar koyu arka planli (#2A2A2A), beyaz metin
- Login butonu: Mor gradient
- Register link: Mor renk metin

### Register
- Koyu tema
- Step gostergesi: Mor progress bar
- Input'lar ve butonlar login ile ayni stil
- Gender kartlari: Koyu, secili olunca mor border + glow

---

## 7. Settings Ekrani

- Koyu arka plan
- ListTile'lar koyu yuzey uzerinde
- Dil secimi: Koyu SegmentedButton, mor secili
- Logout/Delete: Koyu ListTile, delete icin kirmizi ikon/yazi

---

## 8. Diger Ekranlar

### Diamonds
- Bakiye kartlari: Koyu, mor/yesil gradient border
- Satin alma chipleri: Koyu kartlar, mor gradient "Satin Al" butonu
- Islem gecmisi: Koyu satirlar

### Passport
- Koyu arka plan
- Ucak ikonu: Mor neon
- Aktif/pasif durum kartlari

### Quiz
- Koyu arka plan
- Soru karti: Koyu yuzey, mor border
- Cevap butonlari: Koyu, secilince mor glow
- Timer: Mor neon daire animasyonu

### Onboarding
- Siyah arka plan
- Ikonlar: Mor neon
- Dot indicators: Mor aktif, gri pasif

---

## Logout Fix (Bug)
- `auth_provider.dart`: logout() try-catch eklendi, API basarisiz olsa bile lokal temizlik yapilir
- `auth_interceptor.dart`: `/auth/logout` no-refresh listesine eklendi

## Korunacak Yapilar
- Tum provider/repository/service yapisi
- GoRouter routing yapisi
- AppScaffold wrapper (arka plan renkleri guncellenecek)
- i18n sistemi
- Retrofit servisleri
