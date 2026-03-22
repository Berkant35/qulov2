# Profile Preview + Save Success Feedback — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kullanicinin kendi profilini baskasinin gozunden on izlemesi ve kaydetme sonrasi basari feedback'i almasi.

**Architecture:** Mevcut `profile_detail/widgets/` altindaki widget'lar reuse edilir. `UserModel` → `PublicProfileModel` mapper'i ile veri donusumu yapilir. Yeni `ProfilePreviewScreen` `features/profile/` altinda olusturulur. Save sonrasi success bottom sheet + on izleme navigasyonu eklenir.

**Tech Stack:** Flutter, Riverpod, GoRouter, i18n (translations/*.dart), AnalyticsManager

**Spec:** `docs/superpowers/specs/2026-03-22-profile-preview-design.md`

---

## File Structure

### New Files
- `lib/features/profile/screens/profile_preview_screen.dart` — On izleme ekrani (ConsumerStatefulWidget + mixin)
- `lib/features/profile/mixins/profile_preview_screen_mixin.dart` — On izleme ekran logic'i (analytics, navigasyon)
- `lib/features/profile/widgets/profile_save_success_sheet.dart` — Basari bottom sheet widget

### Modified Files
- `lib/features/profile_detail/widgets/profile_basic_info.dart` — `showDistance` parametresi eklenir
- `lib/data/models/user_model.dart` — `toPublicProfile()` extension metodu eklenir
- `lib/routing/route_names.dart` — `profilePreview` route name eklenir
- `lib/routing/app_routes.dart` — `/profile/preview` route tanimlanir
- `lib/core/services/analytics_events.dart` — 3 yeni analytics event eklenir
- `lib/core/l10n/translations/tr.dart` — Turkce i18n key'leri eklenir
- `lib/core/l10n/translations/en.dart` — Ingilizce i18n key'leri eklenir
- `lib/features/profile/screens/edit_profile_screen.dart` — AppBar'a goz ikonu eklenir
- `lib/features/profile/mixins/edit_profile_screen_mixin.dart` — Save sonrasi success sheet + on izleme navigasyonu
- `lib/features/profile/widgets/profile_identity_card.dart` — Tiklanabilir + goz ikonu eklenir
- `lib/features/profile/screens/profile_screen.dart` — IdentityCard tiklama callback'i eklenir

---

## Task 1: ProfileBasicInfo'ya `showDistance` Parametresi Ekle

**Files:**
- Modify: `lib/features/profile_detail/widgets/profile_basic_info.dart:9-17,59-75`

- [ ] **Step 1:** `ProfileBasicInfo`'ya `showDistance` parametresi ekle

```dart
class ProfileBasicInfo extends StatelessWidget {
  final PublicProfileModel profile;
  final bool showOnlineStatus;
  final bool showDistance;

  const ProfileBasicInfo({
    super.key,
    required this.profile,
    this.showOnlineStatus = false,
    this.showDistance = true,
  });
```

- [ ] **Step 2:** `_formatDistance` cagrisini `showDistance` kontrolune bağla

```dart
          // Location + Distance
          if (profile.city != null)
            Row(
              children: [
                QIcon(
                  QIcons.icMapPin,
                  size: 16,
                  color: context.appColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${profile.city}${showDistance ? ' ${_formatDistance(context)}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
```

- [ ] **Step 3:** `flutter analyze` calistir, sifir hata

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/profile_detail/widgets/profile_basic_info.dart
```

- [ ] **Step 4:** Commit

```bash
git add lib/features/profile_detail/widgets/profile_basic_info.dart
git commit -m "feat(profile): add showDistance parameter to ProfileBasicInfo"
```

---

## Task 2: UserModel → PublicProfileModel Mapper

**Files:**
- Modify: `lib/data/models/user_model.dart`

- [ ] **Step 1:** `UserModel`'a `toPublicProfile()` extension metodu ekle (dosyanin sonuna)

```dart
extension UserModelToPublicProfile on UserModel {
  PublicProfileModel toPublicProfile() {
    return PublicProfileModel(
      userId: id,
      name: name,
      age: age,
      bio: bio,
      city: city,
      country: country,
      photos: photos ?? [],
      distanceKm: 0,
      relationshipGoal: relationshipGoal,
      isOnline: false,
      lastSeen: null,
      profileCompletion: profileCompletion,
      isBoosted: boostUntil != null &&
          DateTime.tryParse(boostUntil!)?.isAfter(DateTime.now().toUtc()) == true,
      details: details,
      questionInfo: QuestionInfoModel(
        count: questionCount,
      ),
    );
  }
}
```

- [ ] **Step 2:** Gerekli import'u ekle (dosya basinda `public_profile_model.dart` ve `discover_model.dart` import'lari yoksa ekle)

```dart
import 'package:qulo_v2/data/models/public_profile_model.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
```

- [ ] **Step 3:** `flutter analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/data/models/user_model.dart
```

- [ ] **Step 4:** Commit

```bash
git add lib/data/models/user_model.dart
git commit -m "feat(profile): add toPublicProfile() mapper to UserModel"
```

---

## Task 3: Analytics Events + i18n Keys

**Files:**
- Modify: `lib/core/services/analytics_events.dart`
- Modify: `lib/core/l10n/translations/tr.dart`
- Modify: `lib/core/l10n/translations/en.dart`

- [ ] **Step 1:** Analytics events ekle (`analytics_events.dart`'in sonuna, uygun section'a)

```dart
  // ─── Profile Preview ───────────────────────────────────────────────
  static const String profilePreviewOpened = 'profile_preview_opened';
  static const String profilePreviewEditTapped = 'profile_preview_edit_tapped';
  static const String saveSuccessPreviewTapped = 'save_success_preview_tapped';

  // Param
  static const String paramSource = 'source';
```

**Not:** `paramSource` zaten varsa ekleme. `grep` ile kontrol et.

- [ ] **Step 2:** Turkce i18n key'leri ekle (`tr.dart` map'ine)

```dart
  'profile_preview': 'Profil On Izleme',
  'profile_preview_tooltip': 'Profilini on izle',
  'preview_profile': 'On Izle',
  'profile_updated_success': 'Profilin basariyla guncellendi',
```

- [ ] **Step 3:** Ingilizce i18n key'leri ekle (`en.dart` map'ine)

```dart
  'profile_preview': 'Profile Preview',
  'profile_preview_tooltip': 'Preview your profile',
  'preview_profile': 'Preview',
  'profile_updated_success': 'Profile updated successfully',
```

- [ ] **Step 4:** Diger dil dosyalarini da guncelle (en azindan key'leri Ingilizce degerlerle ekle)

Tum `lib/core/l10n/translations/*.dart` dosyalarina ayni 4 key'i ekle.

- [ ] **Step 5:** `flutter analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/core/
```

- [ ] **Step 6:** Commit

```bash
git add lib/core/services/analytics_events.dart lib/core/l10n/translations/
git commit -m "feat(profile): add profile preview analytics events and i18n keys"
```

---

## Task 4: Route Tanimlama

**Files:**
- Modify: `lib/routing/route_names.dart:30`
- Modify: `lib/routing/app_routes.dart:205-282`

- [ ] **Step 1:** `RouteNames`'e `profilePreview` ekle

```dart
  static const profilePreview = 'profile-preview';
```

- [ ] **Step 2:** `app_routes.dart`'ta root-level route olarak ekle (`profileDetail` route'unun yanina, `StatefulShellRoute`'un DISINDA)

**ONEMLI:** Bu route `StatefulShellRoute` icine degil, root navigator'a eklenmeli. Aksi halde bottom nav bar gorunur kalir. `profileDetail` route'unu (satir 170-179) referans al.

```dart
  // Profile Preview (root navigator — full screen, no bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/profile/preview',
    name: RouteNames.profilePreview,
    builder: (context, state) {
      final source = state.extra is String ? state.extra as String : 'profile_screen';
      return ProfilePreviewScreen(source: source);
    },
  ),
```

- [ ] **Step 3:** `ProfilePreviewScreen` import'unu ekle (`app_router.dart`'daki import bolumune)

```dart
import 'package:qulo_v2/features/profile/screens/profile_preview_screen.dart';
```

**Not:** `ProfilePreviewScreen` henuz olusturulmadi, bu adimda sadece route tanimla. Task 5'te ekran olusturulunca analyze gecer.

- [ ] **Step 4:** Commit

```bash
git add lib/routing/route_names.dart lib/routing/app_routes.dart
git commit -m "feat(profile): add profilePreview route"
```

---

## Task 5: ProfilePreviewScreen + Mixin Olustur

**Files:**
- Create: `lib/features/profile/screens/profile_preview_screen.dart`
- Create: `lib/features/profile/mixins/profile_preview_screen_mixin.dart`

- [ ] **Step 1:** Mixin olustur

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/profile/screens/profile_preview_screen.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin ProfilePreviewScreenMixin on ConsumerState<ProfilePreviewScreen> {
  void initMixin() {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.profilePreviewOpened,
      params: {
        AnalyticsEvents.paramSource: widget.source,
      },
    );
  }

  void disposeMixin() {}

  void onEditProfile() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.profilePreviewEditTapped);
    final nav = ref.read(navigationServiceProvider);
    nav.pop();
    if (widget.source != 'edit_screen') {
      nav.push(RouteNames.editProfile);
    }
  }

  void onClose() {
    ref.read(navigationServiceProvider).pop();
  }

  void onPhotoChanged(int index, int total) {
    // No analytics needed for own profile photo nav
  }
}
```

- [ ] **Step 2:** Screen olustur

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/profile/mixins/profile_preview_screen_mixin.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_basic_info.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_bio_section.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_details_grid.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_photo_gallery.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_question_info.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class ProfilePreviewScreen extends ConsumerStatefulWidget {
  final String source;

  const ProfilePreviewScreen({
    super.key,
    this.source = 'profile_screen',
  });

  @override
  ConsumerState<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends ConsumerState<ProfilePreviewScreen>
    with ProfilePreviewScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: context.appColors.scaffold,
      body: userAsync.when(
        loading: () => const Center(child: AppLoadingWidget.large()),
        error: (_, __) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) onClose();
          });
          return const SizedBox.shrink();
        },
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          final profile = user.toPublicProfile();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfilePhotoGallery(
                  photos: profile.photos,
                  onClose: onClose,
                  onPhotoChanged: onPhotoChanged,
                ),
                const SizedBox(height: AppSpacing.lg),
                ProfileBasicInfo(
                  profile: profile,
                  showOnlineStatus: false,
                  showDistance: false,
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  ProfileBioSection(bio: profile.bio!),
                ],
                if (profile.details != null) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  ProfileDetailsGrid(details: profile.details!),
                ],
                if (profile.questionInfo != null) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  ProfileQuestionInfo(questionInfo: profile.questionInfo!),
                ],
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: AppButton(
            label: context.tr('edit_profile'),
            onPressed: onEditProfile,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3:** `flutter analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/profile/screens/profile_preview_screen.dart lib/features/profile/mixins/profile_preview_screen_mixin.dart
```

- [ ] **Step 4:** Commit

```bash
git add lib/features/profile/screens/profile_preview_screen.dart lib/features/profile/mixins/profile_preview_screen_mixin.dart
git commit -m "feat(profile): create ProfilePreviewScreen with mixin"
```

---

## Task 6: Save Success Bottom Sheet

**Files:**
- Create: `lib/features/profile/widgets/profile_save_success_sheet.dart`

- [ ] **Step 1:** Success sheet widget'ini olustur

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

class ProfileSaveSuccessSheet extends StatelessWidget {
  final VoidCallback? onPreview;

  const ProfileSaveSuccessSheet({super.key, this.onPreview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.appColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: context.appColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('profile_updated_success'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (onPreview != null)
            AppButton(
              label: context.tr('preview_profile'),
              onPressed: onPreview!,
              icon: Icons.visibility,
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2:** `flutter analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/profile/widgets/profile_save_success_sheet.dart
```

- [ ] **Step 3:** Commit

```bash
git add lib/features/profile/widgets/profile_save_success_sheet.dart
git commit -m "feat(profile): create ProfileSaveSuccessSheet widget"
```

---

## Task 7: Edit Profile — Save Sonrasi Success Sheet + AppBar Goz Ikonu

**Files:**
- Modify: `lib/features/profile/mixins/edit_profile_screen_mixin.dart:255-321`
- Modify: `lib/features/profile/screens/edit_profile_screen.dart:47-49`

- [ ] **Step 1:** `edit_profile_screen_mixin.dart`'a success sheet gosterme + on izleme navigasyonu ekle

Save metodunun sonuna ekle: `save()` metodundaki `if (mounted)` blogunun icinde, milestone `if (newMilestones.isNotEmpty)` blogunun KAPANMASINDAN SONRA (satir ~320), ama `if (mounted)` blogunun kapanmasindan ONCE:

```dart
      // Show success sheet (after milestone if any)
      if (mounted) {
        await ref.read(navigationServiceProvider).showAppBottomSheet(
          CustomBottomSheet(
            name: 'profile_save_success',
            builder: (_) => ProfileSaveSuccessSheet(
              onPreview: () {
                ref.read(navigationServiceProvider).closeOverlay();
                AnalyticsManager.instance.logEvent(
                  AnalyticsEvents.saveSuccessPreviewTapped,
                );
                ref.read(navigationServiceProvider).push(
                  RouteNames.profilePreview,
                  extra: 'edit_screen',
                );
              },
            ),
          ),
        );
      }
```

- [ ] **Step 2:** Gerekli import'lari ekle

```dart
import 'package:qulo_v2/features/profile/widgets/profile_save_success_sheet.dart';
import 'package:qulo_v2/routing/route_names.dart';
```

**Not:** `RouteNames` zaten import edilmis olabilir, kontrol et.

- [ ] **Step 3:** `edit_profile_screen.dart`'ta AppBar'a goz ikonu ekle

`AppScaffold`'a `actions` parametresi ekle:

```dart
    return AppScaffold(
      title: context.tr('edit_profile'),
      showBackButton: true,
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.visibility),
          tooltip: context.tr('profile_preview_tooltip'),
          onPressed: () {
            ref.read(navigationServiceProvider).push(
              RouteNames.profilePreview,
              extra: 'edit_screen',
            );
          },
        ),
      ],
      bottomNavigationBar: EditProfileSaveButton(
```

- [ ] **Step 4:** Gerekli import'lari ekle (`edit_profile_screen.dart`'a)

```dart
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/routing/route_names.dart';
```

- [ ] **Step 5:** `flutter analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/profile/
```

- [ ] **Step 6:** Commit

```bash
git add lib/features/profile/mixins/edit_profile_screen_mixin.dart lib/features/profile/screens/edit_profile_screen.dart
git commit -m "feat(profile): add preview icon to edit screen + success sheet after save"
```

---

## Task 8: ProfileIdentityCard Tiklanabilir + Profile Screen Callback

**Files:**
- Modify: `lib/features/profile/widgets/profile_identity_card.dart`
- Modify: `lib/features/profile/screens/profile_screen.dart:103`

- [ ] **Step 1:** `ProfileIdentityCard`'a `onTap` callback + goz ikonu ekle

```dart
class ProfileIdentityCard extends ConsumerWidget {
  const ProfileIdentityCard({
    super.key,
    required this.user,
    this.onTap,
  });

  final UserModel user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Text(
                  '${user.name ?? ''}, ${user.age ?? ''}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                _SubscriptionBadge(ref: ref),
                if (user.city != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QIcon(QIcons.icMapPin, color: theme.colorScheme.onSurfaceVariant, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          user.city!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (onTap != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  Icons.visibility,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2:** `profile_screen.dart`'ta `ProfileIdentityCard`'a `onTap` callback'i ekle

`profile_screen.dart` mevcut navigasyonlarini `ProfileScreenMixin` uzerinden yapar (`navigateTo` metodu). Ayni pattern'i kullan — mixin'e `onPreviewProfile` metodu ekle:

`profile_screen_mixin.dart`'a ekle:

```dart
  void onPreviewProfile() {
    ref.read(navigationServiceProvider).push(
      RouteNames.profilePreview,
      extra: 'profile_screen',
    );
  }
```

Ardindan `profile_screen.dart`'ta:

```dart
                // ─── Identity ───
                ProfileIdentityCard(
                  user: user,
                  onTap: onPreviewProfile,
                ),
```

- [ ] **Step 3:** Gerekli import'lari ekle (`profile_screen_mixin.dart`'a)

`RouteNames` import'u yoksa ekle. `navigationServiceProvider` zaten mixin'de kullaniliyordur, kontrol et.

- [ ] **Step 4:** `flutter analyze` calistir

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/profile/
```

- [ ] **Step 5:** Commit

```bash
git add lib/features/profile/widgets/profile_identity_card.dart lib/features/profile/screens/profile_screen.dart
git commit -m "feat(profile): make ProfileIdentityCard tappable for preview"
```

---

## Task 9: Final Verification

- [ ] **Step 1:** Tum projeyi analyze et

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze
```

Beklenen: 0 hata

- [ ] **Step 2:** Degisen dosyalarin listesini kontrol et

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && git log --oneline -8
```

Beklenen: 8 commit (Task 1-8)

- [ ] **Step 3:** Manuel test plani (cihazda)

1. Profil ekrani → `ProfileIdentityCard`'a tikla → on izleme acilir
2. On izlemede: foto carousel, isim/yas/sehir, bio, detaylar grid, soru bilgisi gorulur
3. On izlemede: mesafe ve online durumu GORUNMEZ
4. On izlemede: "Profili Duzenle" butonu → edit ekranina gider
5. Edit ekrani → AppBar'da goz ikonu → on izleme acilir
6. Edit ekrani → kaydet → milestone varsa celebration sheet → success sheet acilir
7. Success sheet'te "On Izle" butonu → on izleme acilir
8. Success sheet kapatilabilir (disina tiklama)
