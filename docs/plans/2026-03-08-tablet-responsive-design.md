# Tablet Responsive Tasarım

## Amaç
Tablet ekranlarda layout kırılmalarını önlemek ve geniş ekranda "gerilmiş telefon uygulaması" görüntüsünü engellemek.

## Yaklaşım
- Geniş ekranlarda (>560px) içeriği maxWidth: 560 ile ortala
- Hardcoded piksel değerlerini AppSpacing sabitlerine çevir
- Font scaling yok, tablet-specific layout yok

## Teknik Tasarım

### 1. AppScaffold maxWidth Constraint
AppScaffold'un body'sini `Center > ConstrainedBox(maxWidth: 560)` ile sar. Telefonda değişiklik yok (zaten <560px), tablet'te içerik ortalanır.

### 2. Breakpoint Sabiti
`AppSpacing.maxContentWidth = 560` olarak tanımla. Tek noktadan kontrol.

### 3. Hardcoded Değer Düzeltmeleri
- `matches_screen.dart` — 12 hardcoded değer → AppSpacing
- `upsell_sheets.dart` — 10 hardcoded değer → AppSpacing
- `diamond_balance_card.dart` — sabit divider → AppSpacing
- `settings_screen.dart` — sabit spacing → AppSpacing
- `edit_profile_screen.dart` — sabit boyutlar → AppSpacing

## Kapsam Dışı
- İki kolonlu layout
- Font scaling
- Landscape özel layout
- Tablet-specific widget'lar
