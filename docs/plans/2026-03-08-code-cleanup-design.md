# Code Cleanup & SOLID Refactor Tasarımı

## Amaç
Relative importları package importlara çevirmek, hardcoded theme değerlerini temizlemek, SOLID ihlallerini düzeltmek ve repository interface'leri eklemek.

## Faz 1 — Import Refactor
- 155 dosyadaki 365 relative import → `package:qulov2/...` formatına
- Otomatik script veya dart fix ile

## Faz 2 — Theme Tutarlılığı
- 35+ dosyada AppColors direkt kullanım → theme.colorScheme.*
- 8 hardcoded Color(0x...) → AppColors sabitleri (gold, silver, bronze)
- 4 hardcoded TextStyle → theme.textTheme.*
- 3 hardcoded Türkçe string → context.tr()

## Faz 3 — SOLID Refactor
- EditProfileScreen (665L) → EditProfileProvider + PhotoUploadWidget + view-only screen
- RegisterScreen (358L) → Step provider'lar + step widget'ları
- UpsellSheets (349L) → BaseUpsellSheet + konfigürasyon

## Faz 4 — Repository Interface
- 12 repository'ye abstract interface ekle

## Kapsam Dışı
- Dosya/klasör yapısı değişikliği yok
- Yeni paket eklenmeyecek
- Provider/service mimarisi değişmeyecek
