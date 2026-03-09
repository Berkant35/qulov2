# Photo System — Storage Fix + Custom Crop Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Supabase Storage bucket auto-create ile "Bucket not found" hatasını düzelt + Flutter'da custom crop ekranı ekle (1:1 kare, daire mask, pinch-to-zoom, rotate, Qulo koyu+mor tema).

**Architecture:** Backend startup'ta Supabase Storage bucket varlığını kontrol edip yoksa oluşturur. Flutter tarafında `crop_your_image` paketi ile custom crop ekranı eklenir, `ImagePickerManager`'a `pickAndCrop` metodu eklenir, `EditProfileScreen`'daki fotoğraf seçme akışına crop entegre edilir.

**Tech Stack:** Node.js/Express (backend), Flutter + crop_your_image (mobile), Supabase Storage (storage)

---

### Task 1: Backend — Supabase Bucket Auto-Create

**Files:**
- Modify: `server/src/config/supabase.ts`
- Modify: `server/src/index.ts`

**Step 1: `supabase.ts`'e `ensureBucketExists` fonksiyonu ekle**

```typescript
// server/src/config/supabase.ts — dosyanın sonuna ekle
export async function ensureStorageBuckets() {
  const { data: buckets, error } = await supabase.storage.listBuckets();
  if (error) {
    console.error("[storage] Failed to list buckets:", error.message);
    return;
  }

  const bucketName = "photos";
  const exists = buckets?.some((b) => b.name === bucketName);

  if (!exists) {
    const { error: createError } = await supabase.storage.createBucket(bucketName, {
      public: true,
      fileSizeLimit: 5 * 1024 * 1024, // 5MB
      allowedMimeTypes: ["image/jpeg", "image/png"],
    });

    if (createError) {
      console.error("[storage] Failed to create bucket:", createError.message);
    } else {
      console.log("[storage] Created 'photos' bucket");
    }
  } else {
    console.log("[storage] 'photos' bucket exists");
  }
}
```

**Step 2: `index.ts`'te startup'ta çağır**

`server/src/index.ts` — `app.listen` callback'inde `adminService.seedAdmin` altına ekle:

```typescript
// index.ts — app.listen callback içi, seedAdmin'den sonra
import { ensureStorageBuckets } from "./config/supabase.js";

// Startup'ta çağır:
ensureStorageBuckets().catch(console.error);
```

**Step 3: Backend'i çalıştırıp test et**

Run: `cd server && npm run dev`
Expected: Konsolda `[storage] Created 'photos' bucket` veya `[storage] 'photos' bucket exists` mesajı

**Step 4: Fotoğraf yüklemeyi test et**

Mevcut Flutter uygulamasından fotoğraf yükle — artık "Bucket not found" hatası gelmemeli.

**Step 5: Commit**

```bash
git add server/src/config/supabase.ts server/src/index.ts
git commit -m "fix: auto-create Supabase 'photos' storage bucket on startup"
```

---

### Task 2: Flutter — `crop_your_image` Paketini Ekle

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Paketi ekle**

`pubspec.yaml` dependencies bölümüne ekle:

```yaml
  crop_your_image: ^1.1.0
```

**Step 2: Paketleri indir**

Run: `flutter pub get`
Expected: Başarılı, hata yok

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add crop_your_image dependency"
```

---

### Task 3: Flutter — CropScreen Widget'ı Oluştur

**Files:**
- Create: `lib/core/widgets/crop_screen.dart`

**Step 1: CropScreen widget'ını yaz**

```dart
// lib/core/widgets/crop_screen.dart
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _cropController = CropController();
  bool _isCropping = false;
  int _rotationTurns = 0;

  void _rotate() {
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
  }

  void _confirm() {
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  void _onCropped(Uint8List croppedBytes) {
    if (mounted) {
      Navigator.of(context).pop(croppedBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right),
            tooltip: 'Rotate',
            onPressed: _isCropping ? null : _rotate,
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _isCropping ? null : _confirm,
              child: _isCropping
                  ? const AppLoadingWidget.small()
                  : Text(
                      'OK',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: RotatedBox(
        quarterTurns: _rotationTurns,
        child: Crop(
          controller: _cropController,
          image: widget.imageBytes,
          aspectRatio: 1,
          withCircleUi: true,
          baseColor: AppColors.background,
          maskColor: AppColors.background.withAlpha(200),
          cornerDotBuilder: (size, edgeAlignment) => const SizedBox.shrink(),
          onCropped: _onCropped,
          initialSize: 0.8,
          interactive: true,
        ),
      ),
    );
  }
}
```

**Tasarım detayları:**
- `withCircleUi: true` → daire mask önizleme
- `aspectRatio: 1` → 1:1 kare crop (gerçek çıktı kare, daire sadece görsel)
- `interactive: true` → pinch-to-zoom + pan gesture
- `RotatedBox` ile 90° rotate (0, 90, 180, 270)
- Koyu arka plan (`AppColors.background`), mor accent (`AppColors.primary`)
- `cornerDotBuilder` boş → köşe noktaları gizli (daire UI'da gereksiz)
- Crop sırasında `AppLoadingWidget.small()` gösterir

**Step 2: Commit**

```bash
git add lib/core/widgets/crop_screen.dart
git commit -m "feat: add custom CropScreen with circle mask and Qulo theme"
```

---

### Task 4: Flutter — ImagePickerManager'a `pickAndCrop` Ekle

**Files:**
- Modify: `lib/core/services/image_picker_manager.dart`

**Step 1: `pickAndCrop` metodu ekle**

`ImagePickerManager` class'ına yeni metod ekle. Bu metod `BuildContext` alır çünkü crop ekranına navigate etmesi gerekir:

```dart
// image_picker_manager.dart — import'lar
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/widgets/crop_screen.dart';

// ImagePickerManager class'ına ekle:
  Future<PickedImage?> pickAndCrop(
    BuildContext context,
    ImageSource source, {
    double maxWidth = _defaultMaxWidth,
    int imageQuality = _defaultImageQuality,
  }) async {
    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
    if (xFile == null) return null;

    final originalBytes = await xFile.readAsBytes();

    if (!context.mounted) return null;

    final croppedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CropScreen(imageBytes: originalBytes),
      ),
    );

    if (croppedBytes == null) return null;

    final mimeType = xFile.mimeType ?? 'image/jpeg';
    final fileName = xFile.name;

    return PickedImage(
      bytes: croppedBytes,
      mimeType: mimeType,
      fileName: fileName,
    );
  }
```

**Step 2: Commit**

```bash
git add lib/core/services/image_picker_manager.dart
git commit -m "feat: add pickAndCrop method to ImagePickerManager"
```

---

### Task 5: Flutter — EditProfileScreen'da Crop Entegrasyonu

**Files:**
- Modify: `lib/features/profile/screens/edit_profile_screen.dart`

**Step 1: `_pickFromGallery` ve `_pickFromCamera` metodlarını güncelle**

Mevcut `_pickFromGallery`, `_pickFromCamera`, `_pickAndUpload` metodlarını değiştir:

```dart
// Eski:
Future<void> _pickFromGallery() => _pickAndUpload(
      ref.read(imagePickerManagerProvider).pickFromGallery(),
    );

Future<void> _pickFromCamera() => _pickAndUpload(
      ref.read(imagePickerManagerProvider).pickFromCamera(),
    );

Future<void> _pickAndUpload(Future<PickedImage?> pickFuture) async {
  final picked = await pickFuture;
  if (picked == null) return;
  // ...
}

// Yeni:
Future<void> _pickFromGallery() => _pickCropAndUpload(ImageSource.gallery);

Future<void> _pickFromCamera() => _pickCropAndUpload(ImageSource.camera);

Future<void> _pickCropAndUpload(ImageSource source) async {
  final picked = await ref.read(imagePickerManagerProvider).pickAndCrop(context, source);
  if (picked == null) return;

  final result = await ref.read(userProvider.notifier).uploadPhoto(picked.bytes, picked.mimeType);

  if (mounted) {
    if (result.isSuccess) {
      ref.read(editProfileProvider.notifier).refreshPhotos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('save_error'))),
      );
    }
  }
}
```

**Step 2: `image_picker` import'u ekle** (ImageSource için)

```dart
import 'package:image_picker/image_picker.dart';
```

**Step 3: Eski `_pickAndUpload` metodunu sil**

Artık kullanılmıyor.

**Step 4: Uygulamayı çalıştırıp test et**

Run: `flutter run`
Test akışı:
1. Profil düzenle → fotoğraf slot'una bas
2. Galeri/Kamera seç
3. Fotoğraf seç → CropScreen açılsın
4. Pinch-to-zoom, pan, rotate test et
5. Onayla → fotoğraf yüklensin
6. İptal (X) → geri dönülsün, yükleme olmasın

**Step 5: Commit**

```bash
git add lib/features/profile/screens/edit_profile_screen.dart
git commit -m "feat: integrate crop screen into photo upload flow"
```

---

### Task 6: Flutter — Onboarding Fotoğraf Akışına Crop Ekle (varsa)

**Files:**
- Check: `lib/features/onboarding/screens/onboarding_screen.dart`

**Step 1: Onboarding'de fotoğraf yükleme var mı kontrol et**

Eğer onboarding'de de fotoğraf yükleme varsa, aynı `pickAndCrop` pattern'ini uygula.
Eğer yoksa bu task'ı atla.

**Step 2: Commit (eğer değişiklik varsa)**

```bash
git add lib/features/onboarding/
git commit -m "feat: add crop to onboarding photo upload"
```

---

### Task 7: Temizlik + Final Test

**Files:**
- Tüm değişen dosyalar

**Step 1: Flutter analyze**

Run: `flutter analyze`
Expected: Hata yok

**Step 2: Tam akış testi**

1. Backend'i başlat → konsolda bucket mesajı gör
2. Uygulamayı aç → profil düzenle → fotoğraf ekle
3. Galeri'den seç → crop ekranı açılsın
4. Daire mask + pinch-to-zoom + rotate test et
5. Onayla → fotoğraf başarıyla yüklensin
6. Kamera'dan seç → aynı akış
7. İptal → yükleme olmasın

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: photo crop + storage — cleanup and final polish"
```
