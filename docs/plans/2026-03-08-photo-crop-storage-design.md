# Photo System — Storage Fix + Custom Crop

## Date: 2026-03-08

## Problem
1. Supabase Storage'da `photos` bucket'ı yok → "Bucket not found" hatası
2. Fotoğraf seçildikten sonra crop yapılamıyor → kötü UX

## Design

### 1. Supabase Bucket Auto-Create
- Backend startup'ta `photos` bucket kontrol + yoksa oluştur
- Public erişim, 5MB limit, JPEG/PNG only
- `server/src/config/supabase.ts` → `ensureBucketExists()`
- `server/src/index.ts` → startup'ta çağır

### 2. Custom Crop Ekranı
- **Paket**: `crop_your_image` (Flutter-native, tam kontrol)
- **Crop ratio**: 1:1 kare (discover kartlarına uyum)
- **Mask**: Daire önizleme (profil avatarı böyle görünecek)
- **Gesture**: Pinch-to-zoom + pan
- **Rotate**: 90° döndürme butonu
- **Tema**: Koyu arka plan + mor accent (Qulo teması)
- **Gerçek kayıt**: Kare — profilde ClipOval ile daire, kartlarda kare

### 3. Akış
```
Galeri/Kamera → ImagePicker → CropScreen (kare+daire mask, zoom, rotate)
    → Onay → Bytes → Upload API → Supabase "photos" bucket → Public URL → DB
```

### 4. Dosya Yapısı
```
lib/core/widgets/crop_screen.dart           — Custom crop ekranı
lib/core/services/image_picker_manager.dart  — pickAndCrop metodu
server/src/config/supabase.ts               — ensureBucketExists()
server/src/index.ts                         — startup bucket check
```

### 5. Ayarlar (değişmez)
- Max genişlik: 1080px
- JPEG kalitesi: %85
- Max dosya boyutu: 5MB (Multer)
- Fotoğraf limiti: 6 adet

### 6. Gelecek Plan
- Supabase Storage → Cloudflare R2 geçişi (StorageService abstraction ile)
- Egress maliyeti sıfıra iner, ölçekte kritik tasarruf
