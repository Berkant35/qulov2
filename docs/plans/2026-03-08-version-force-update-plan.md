# App Version & Force Update — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Uygulama versiyon kontrolü + force update + bakım modu sistemi. Splash sonrası ve onResume'da kontrol, blocking UI, 24s akıllı erteleme.

**Architecture:** Supabase `app_config` tablosu → Backend `GET /api/v1/app/config` (auth gerektirmez, platform header'dan okur) → Flutter splash sonrası + lifecycle observer ile kontrol → ForceUpdateScreen / MaintenanceScreen / OptionalUpdateDialog

**Tech Stack:** Supabase PostgreSQL, Express.js, Flutter Riverpod, SharedPreferences, WidgetsBindingObserver, url_launcher

---

### Task 1: Supabase Migration — `app_config` tablosu

**Files:**
- Create: `server/src/migrations/006_app_config.sql`

**Step 1: Migration SQL dosyasını yaz**

```sql
-- 006_app_config.sql
-- App configuration table (single row)

CREATE TABLE IF NOT EXISTS app_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  min_version_ios text NOT NULL DEFAULT '2.0.0',
  min_version_android text NOT NULL DEFAULT '2.0.0',
  latest_version_ios text NOT NULL DEFAULT '2.0.0',
  latest_version_android text NOT NULL DEFAULT '2.0.0',
  store_url_ios text NOT NULL DEFAULT '',
  store_url_android text NOT NULL DEFAULT '',
  is_maintenance boolean NOT NULL DEFAULT false,
  maintenance_message_tr text,
  maintenance_message_en text,
  is_force_update_enabled boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Seed default row
INSERT INTO app_config (
  min_version_ios, min_version_android,
  latest_version_ios, latest_version_android,
  store_url_ios, store_url_android,
  is_maintenance, is_force_update_enabled
) VALUES (
  '2.0.0', '2.0.0',
  '2.0.0', '2.0.0',
  '', '',
  false, true
);

-- Disable RLS (service_role kullanıyoruz)
ALTER TABLE app_config DISABLE ROW LEVEL SECURITY;
```

**Step 2: Kullanıcıya SQL'i Supabase SQL Editor'da çalıştırmasını söyle**

**Step 3: Commit**
```bash
git add server/src/migrations/006_app_config.sql
git commit -m "feat: add app_config migration for version control system"
```

---

### Task 2: Backend — App Config Service

**Files:**
- Create: `server/src/services/app-config.service.ts`

**Step 1: Service dosyasını yaz**

```typescript
import { supabase } from "../config/supabase.js";

interface AppConfigRow {
  id: string;
  min_version_ios: string;
  min_version_android: string;
  latest_version_ios: string;
  latest_version_android: string;
  store_url_ios: string;
  store_url_android: string;
  is_maintenance: boolean;
  maintenance_message_tr: string | null;
  maintenance_message_en: string | null;
  is_force_update_enabled: boolean;
  updated_at: string;
}

class AppConfigService {
  async getConfig(platform: "ios" | "android", locale: string) {
    const { data, error } = await supabase
      .from("app_config")
      .select("*")
      .limit(1)
      .single();

    if (error || !data) {
      // Fallback: return safe defaults (don't block the app)
      return {
        minVersion: "0.0.0",
        latestVersion: "0.0.0",
        storeUrl: "",
        isMaintenance: false,
        maintenanceMessage: null,
        isForceUpdateEnabled: false,
      };
    }

    const row = data as AppConfigRow;
    const isIos = platform === "ios";
    const lang = locale.startsWith("tr") ? "tr" : "en";

    return {
      minVersion: isIos ? row.min_version_ios : row.min_version_android,
      latestVersion: isIos ? row.latest_version_ios : row.latest_version_android,
      storeUrl: isIos ? row.store_url_ios : row.store_url_android,
      isMaintenance: row.is_maintenance,
      maintenanceMessage: row.is_maintenance
        ? (lang === "tr" ? row.maintenance_message_tr : row.maintenance_message_en)
        : null,
      isForceUpdateEnabled: row.is_force_update_enabled,
    };
  }

  async updateConfig(updates: Partial<Omit<AppConfigRow, "id" | "updated_at">>) {
    const { data, error } = await supabase
      .from("app_config")
      .update({ ...updates, updated_at: new Date().toISOString() })
      .select("*")
      .limit(1)
      .single();

    if (error) throw error;
    return data;
  }
}

export const appConfigService = new AppConfigService();
```

**Step 2: Commit**
```bash
git add server/src/services/app-config.service.ts
git commit -m "feat: add app config service for version management"
```

---

### Task 3: Backend — App Config Controller + Route

**Files:**
- Create: `server/src/controllers/app.controller.ts`
- Create: `server/src/routes/app.routes.ts`
- Modify: `server/src/index.ts` (route mount)

**Step 1: Controller dosyasını yaz**

```typescript
import type { Request, Response, NextFunction } from "express";
import { appConfigService } from "../services/app-config.service.js";

export async function getAppConfigHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const platform = (req.headers["x-app-platform"] as string) || "android";
    const locale = (req.headers["accept-language"] as string) || "tr";

    const validPlatform = platform === "ios" ? "ios" : "android";

    const config = await appConfigService.getConfig(validPlatform, locale);
    res.json(config);
  } catch (err) {
    next(err);
  }
}
```

**Step 2: Route dosyasını yaz**

```typescript
import { Router } from "express";
import { generalLimiter } from "../middleware/rateLimit.js";
import { getAppConfigHandler } from "../controllers/app.controller.js";

const router = Router();

// Auth gerektirmiyor — login öncesi de kontrol edilmeli
router.use(generalLimiter);

router.get("/config", getAppConfigHandler);

export default router;
```

**Step 3: index.ts'e route'u ekle**

`server/src/index.ts` dosyasında, mevcut route'ların hemen üstüne ekle (auth gerektirmediği için):

```typescript
import appRoutes from "./routes/app.routes.js";
```

Route mount (diğer route'lardan önce):
```typescript
app.use("/api/v1/app", appRoutes);
```

**Step 4: Commit**
```bash
git add server/src/controllers/app.controller.ts server/src/routes/app.routes.ts server/src/index.ts
git commit -m "feat: add GET /api/v1/app/config endpoint"
```

---

### Task 4: Flutter — AppConfig Model

**Files:**
- Create: `lib/data/models/app_config_model.dart`

**Step 1: Model dosyasını yaz**

```dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_config_model.g.dart';

@JsonSerializable()
class AppConfigModel extends Equatable {
  final String minVersion;
  final String latestVersion;
  final String storeUrl;
  final bool isMaintenance;
  final String? maintenanceMessage;
  final bool isForceUpdateEnabled;

  const AppConfigModel({
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    required this.isMaintenance,
    this.maintenanceMessage,
    required this.isForceUpdateEnabled,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) =>
      _$AppConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigModelToJson(this);

  @override
  List<Object?> get props => [
        minVersion,
        latestVersion,
        storeUrl,
        isMaintenance,
        maintenanceMessage,
        isForceUpdateEnabled,
      ];
}
```

**Step 2: build_runner çalıştır**
```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**
```bash
git add lib/data/models/app_config_model.dart lib/data/models/app_config_model.g.dart
git commit -m "feat: add AppConfigModel for version check"
```

---

### Task 5: Flutter — AppConfig Retrofit Service + Repository

**Files:**
- Create: `lib/core/network/services/app_config_service.dart`
- Create: `lib/data/repositories/app_config_repository.dart`
- Modify: `lib/data/repositories/repositories.dart` (export)
- Modify: `lib/providers/api_provider.dart` (providers)

**Step 1: Retrofit service yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'app_config_service.g.dart';

@RestApi()
abstract class AppConfigRetrofitService {
  factory AppConfigRetrofitService(Dio dio) = _AppConfigRetrofitService;

  @GET('/app/config')
  Future<Map<String, dynamic>> getConfig();
}
```

**Step 2: Repository yaz**

```dart
import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/app_config_service.dart';
import 'package:qulo_v2/data/models/app_config_model.dart';

class AppConfigRepository {
  final AppConfigRetrofitService _service;

  AppConfigRepository(this._service);

  Future<Result<AppConfigModel>> getConfig() async {
    try {
      final response = await _service.getConfig();
      return Success(AppConfigModel.fromJson(response));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 3: repositories.dart'a export ekle**

```dart
export 'app_config_repository.dart';
```

**Step 4: api_provider.dart'a provider'ları ekle**

Import:
```dart
import 'package:qulo_v2/core/network/services/app_config_service.dart';
```

Retrofit service provider (diğer retrofit service provider'ların yanına):
```dart
final appConfigRetrofitServiceProvider = Provider<AppConfigRetrofitService>(
  (ref) => AppConfigRetrofitService(ref.read(networkManagerProvider).dio),
);
```

Repository provider (diğer repository provider'ların yanına):
```dart
final appConfigRepositoryProvider = Provider<AppConfigRepository>(
  (ref) => AppConfigRepository(ref.read(appConfigRetrofitServiceProvider)),
);
```

**Step 5: build_runner çalıştır**
```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart run build_runner build --delete-conflicting-outputs
```

**Step 6: Commit**
```bash
git add lib/core/network/services/app_config_service.dart lib/core/network/services/app_config_service.g.dart lib/data/repositories/app_config_repository.dart lib/data/repositories/repositories.dart lib/providers/api_provider.dart
git commit -m "feat: add app config service, repository, and providers"
```

---

### Task 6: Flutter — Platform Header Interceptor

**Files:**
- Modify: `lib/core/network/network_manager.dart`

**Step 1: NetworkManager'da Dio BaseOptions headers'a platform header ekle**

`network_manager.dart`'taki `BaseOptions` headers kısmına ekle:

```dart
import 'dart:io' show Platform;
```

Headers'a ekle:
```dart
headers: {
  'Content-Type': 'application/json',
  'x-app-platform': Platform.isIOS ? 'ios' : 'android',
},
```

**Step 2: Commit**
```bash
git add lib/core/network/network_manager.dart
git commit -m "feat: add x-app-platform header to all API requests"
```

---

### Task 7: Flutter — Version Comparison Utility

**Files:**
- Create: `lib/core/utils/version_utils.dart`

**Step 1: Utility fonksiyonları yaz**

```dart
/// Semantic version karşılaştırması.
/// Döner: negatif (a < b), 0 (eşit), pozitif (a > b)
int compareVersions(String a, String b) {
  final partsA = a.split('.').map(int.parse).toList();
  final partsB = b.split('.').map(int.parse).toList();

  final length = partsA.length > partsB.length ? partsA.length : partsB.length;

  for (var i = 0; i < length; i++) {
    final partA = i < partsA.length ? partsA[i] : 0;
    final partB = i < partsB.length ? partsB[i] : 0;

    if (partA != partB) return partA - partB;
  }

  return 0;
}

/// current < target ise true
bool isVersionLessThan(String current, String target) {
  return compareVersions(current, target) < 0;
}
```

**Step 2: Commit**
```bash
git add lib/core/utils/version_utils.dart
git commit -m "feat: add semantic version comparison utility"
```

---

### Task 8: Flutter — i18n Keys

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: TR ve EN map'lerine version/update key'lerini ekle**

TR map'e ekle:
```dart
// Version & Update
'update_required_title': 'Güncelleme Gerekli',
'update_required_message': 'Uygulamayı kullanmaya devam etmek için lütfen güncelleyin.',
'update_available_title': 'Yeni Güncelleme Mevcut',
'update_available_message': 'Daha iyi bir deneyim için uygulamayı güncelleyin.',
'update_button': 'Güncelle',
'update_later': 'Daha Sonra',
'maintenance_title': 'Bakım Çalışması',
'maintenance_default_message': 'Uygulama şu anda bakımdadır. Lütfen daha sonra tekrar deneyin.',
```

EN map'e ekle:
```dart
// Version & Update
'update_required_title': 'Update Required',
'update_required_message': 'Please update the app to continue using it.',
'update_available_title': 'Update Available',
'update_available_message': 'Update the app for a better experience.',
'update_button': 'Update',
'update_later': 'Later',
'maintenance_title': 'Under Maintenance',
'maintenance_default_message': 'The app is currently under maintenance. Please try again later.',
```

**Step 2: Commit**
```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat: add i18n keys for version update and maintenance"
```

---

### Task 9: Flutter — AppConfig Provider (Version Checker Logic)

**Files:**
- Create: `lib/providers/app_config_provider.dart`

**Step 1: Provider dosyasını yaz**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/utils/version_utils.dart';
import 'package:qulo_v2/data/models/app_config_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

enum UpdateStatus {
  none,
  optionalUpdate,
  forceUpdate,
  maintenance,
}

class AppConfigState {
  final AppConfigModel? config;
  final UpdateStatus status;
  final bool isLoading;
  final String currentVersion;

  const AppConfigState({
    this.config,
    this.status = UpdateStatus.none,
    this.isLoading = false,
    this.currentVersion = '0.0.0',
  });

  AppConfigState copyWith({
    AppConfigModel? config,
    UpdateStatus? status,
    bool? isLoading,
    String? currentVersion,
  }) {
    return AppConfigState(
      config: config ?? this.config,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      currentVersion: currentVersion ?? this.currentVersion,
    );
  }
}

class AppConfigNotifier extends Notifier<AppConfigState> {
  static const _dismissedKey = 'optional_update_dismissed_at';

  @override
  AppConfigState build() => const AppConfigState();

  Future<UpdateStatus> checkVersion() async {
    state = state.copyWith(isLoading: true);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final result = await ref.read(appConfigRepositoryProvider).getConfig();

      return result.when(
        success: (config) {
          UpdateStatus status;

          if (config.isMaintenance) {
            status = UpdateStatus.maintenance;
          } else if (config.isForceUpdateEnabled &&
              isVersionLessThan(currentVersion, config.minVersion)) {
            status = UpdateStatus.forceUpdate;
          } else if (isVersionLessThan(currentVersion, config.latestVersion)) {
            status = UpdateStatus.optionalUpdate;
          } else {
            status = UpdateStatus.none;
          }

          state = state.copyWith(
            config: config,
            status: status,
            isLoading: false,
            currentVersion: currentVersion,
          );

          return status;
        },
        failure: (_) {
          // Network hatası → sessizce geç
          state = state.copyWith(isLoading: false, status: UpdateStatus.none);
          return UpdateStatus.none;
        },
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, status: UpdateStatus.none);
      return UpdateStatus.none;
    }
  }

  /// Opsiyonel güncelleme 24 saat içinde dismiss edilmiş mi?
  Future<bool> isOptionalUpdateDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedAt = prefs.getInt(_dismissedKey);
    if (dismissedAt == null) return false;

    final dismissedTime = DateTime.fromMillisecondsSinceEpoch(dismissedAt);
    final hoursSince = DateTime.now().difference(dismissedTime).inHours;
    return hoursSince < 24;
  }

  /// Opsiyonel güncellemeyi ertele (24 saat)
  Future<void> dismissOptionalUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedKey, DateTime.now().millisecondsSinceEpoch);
  }
}

final appConfigProvider = NotifierProvider<AppConfigNotifier, AppConfigState>(
  AppConfigNotifier.new,
);
```

**Step 2: Commit**
```bash
git add lib/providers/app_config_provider.dart
git commit -m "feat: add app config provider with version check logic"
```

---

### Task 10: Flutter — ForceUpdateScreen

**Files:**
- Create: `lib/features/update/force_update_screen.dart`

**Step 1: Screen'i yaz**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';

class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider).config;

    return PopScope(
      canPop: false,
      child: AppScaffold(
        padding: const EdgeInsets.all(AppSpacing.xl),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.logoSvg,
                width: AppSizes.logoMd,
                height: AppSizes.logoMd,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                context.tr('update_required_title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('update_required_message'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (config != null && config.storeUrl.isNotEmpty)
                AppButton(
                  label: context.tr('update_button'),
                  onPressed: () {
                    ref
                        .read(urlLauncherManagerProvider)
                        .launchUrl(config.storeUrl);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Commit**
```bash
git add lib/features/update/force_update_screen.dart
git commit -m "feat: add force update screen (blocking, non-dismissable)"
```

---

### Task 11: Flutter — MaintenanceScreen

**Files:**
- Create: `lib/features/update/maintenance_screen.dart`

**Step 1: Screen'i yaz**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider).config;

    return PopScope(
      canPop: false,
      child: AppScaffold(
        padding: const EdgeInsets.all(AppSpacing.xl),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                context.tr('maintenance_title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                config?.maintenanceMessage ??
                    context.tr('maintenance_default_message'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Commit**
```bash
git add lib/features/update/maintenance_screen.dart
git commit -m "feat: add maintenance screen (blocking, no action button)"
```

---

### Task 12: Flutter — Route Tanımlamaları

**Files:**
- Modify: `lib/routing/route_names.dart` (yeni isimler)
- Modify: `lib/routing/app_router.dart` (yeni route'lar + redirect güncelleme)

**Step 1: RouteNames'e yeni isimler ekle**

```dart
static const forceUpdate = 'force-update';
static const maintenance = 'maintenance';
```

**Step 2: app_routes.dart'a (veya _routes listesine) yeni GoRoute'lar ekle**

Import'lar:
```dart
import 'package:qulo_v2/features/update/force_update_screen.dart';
import 'package:qulo_v2/features/update/maintenance_screen.dart';
```

Route tanımları (splash route'unun yanına, top-level):
```dart
GoRoute(
  path: '/force-update',
  name: RouteNames.forceUpdate,
  builder: (context, state) => const ForceUpdateScreen(),
),
GoRoute(
  path: '/maintenance',
  name: RouteNames.maintenance,
  builder: (context, state) => const MaintenanceScreen(),
),
```

**Step 3: Commit**
```bash
git add lib/routing/route_names.dart lib/routing/app_router.dart lib/routing/app_routes.dart
git commit -m "feat: add force-update and maintenance routes"
```

---

### Task 13: Flutter — VersionChecker Service (Lifecycle Observer)

**Files:**
- Create: `lib/core/services/version_checker.dart`

**Step 1: VersionChecker widget'ını yaz**

Bu widget, app shell'de wrap edilerek lifecycle observer görevi görür.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_service.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class VersionChecker extends ConsumerStatefulWidget {
  final Widget child;

  const VersionChecker({super.key, required this.child});

  @override
  ConsumerState<VersionChecker> createState() => _VersionCheckerState();
}

class _VersionCheckerState extends ConsumerState<VersionChecker>
    with WidgetsBindingObserver {
  bool _isDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkOnResume();
    }
  }

  Future<void> _checkOnResume() async {
    final status = await ref.read(appConfigProvider.notifier).checkVersion();
    if (!mounted) return;

    switch (status) {
      case UpdateStatus.maintenance:
        _showMaintenanceDialog();
      case UpdateStatus.forceUpdate:
        _showForceUpdateDialog();
      case UpdateStatus.optionalUpdate:
      case UpdateStatus.none:
        break; // onResume'da opsiyonel gösterme
    }
  }

  void _showForceUpdateDialog() {
    if (_isDialogShown) return;
    _isDialogShown = true;

    final config = ref.read(appConfigProvider).config;
    final navService = ref.read(navigationServiceProvider);

    navService.showAppDialog(
      CustomDialog(
        name: 'force_update_resume',
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(ctx.tr('update_required_title')),
            content: Text(ctx.tr('update_required_message')),
            actions: [
              TextButton(
                onPressed: () {
                  if (config != null && config.storeUrl.isNotEmpty) {
                    ref.read(urlLauncherManagerProvider).launchUrl(config.storeUrl);
                  }
                },
                child: Text(ctx.tr('update_button')),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _isDialogShown = false);
  }

  void _showMaintenanceDialog() {
    if (_isDialogShown) return;
    _isDialogShown = true;

    final config = ref.read(appConfigProvider).config;
    final navService = ref.read(navigationServiceProvider);

    navService.showAppDialog(
      CustomDialog(
        name: 'maintenance_resume',
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(ctx.tr('maintenance_title')),
            content: Text(
              config?.maintenanceMessage ?? ctx.tr('maintenance_default_message'),
            ),
          ),
        ),
      ),
    ).then((_) => _isDialogShown = false);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

**Step 2: Commit**
```bash
git add lib/core/services/version_checker.dart
git commit -m "feat: add VersionChecker widget with lifecycle observer"
```

---

### Task 14: Flutter — Splash Screen'e Version Check Entegrasyonu

**Files:**
- Modify: `lib/features/splash/splash_screen.dart`
- Modify: `lib/app.dart` (VersionChecker wrap)

**Step 1: splash_screen.dart — `_waitForAuth` yerine version check ekle**

`_startAnimation` metodunun sonundaki `_waitForAuth()` çağrısını `_checkVersionAndAuth()` ile değiştir.

Yeni import'lar:
```dart
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/core/navigation/navigation_service.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/routing/route_names.dart';
```

`_waitForAuth()` metodunu sil ve yerine yeni metodu koy:

```dart
Future<void> _checkVersionAndAuth() async {
  final status = await ref.read(appConfigProvider.notifier).checkVersion();
  if (!mounted) return;

  switch (status) {
    case UpdateStatus.maintenance:
      ref.read(navigationServiceProvider).go(RouteNames.maintenance);
      return;
    case UpdateStatus.forceUpdate:
      ref.read(navigationServiceProvider).go(RouteNames.forceUpdate);
      return;
    case UpdateStatus.optionalUpdate:
      _showOptionalUpdateThenContinue();
      return;
    case UpdateStatus.none:
      break; // Normal auth flow'a devam
  }

  // Auth check (mevcut davranış)
  _continueToAuth();
}

Future<void> _showOptionalUpdateThenContinue() async {
  final notifier = ref.read(appConfigProvider.notifier);
  final isDismissed = await notifier.isOptionalUpdateDismissed();

  if (isDismissed) {
    _continueToAuth();
    return;
  }

  if (!mounted) return;

  final config = ref.read(appConfigProvider).config;
  final result = await ref.read(navigationServiceProvider).showAppDialog<bool>(
    ConfirmDialog(
      name: 'optional_update',
      title: context.tr('update_available_title'),
      message: context.tr('update_available_message'),
      confirmText: context.tr('update_button'),
      cancelText: context.tr('update_later'),
    ),
  );

  if (result == true && config != null && config.storeUrl.isNotEmpty) {
    ref.read(urlLauncherManagerProvider).launchUrl(config.storeUrl);
  } else {
    await notifier.dismissOptionalUpdate();
  }

  _continueToAuth();
}

void _continueToAuth() {
  final authState = ref.read(authProvider);
  if (authState.status != AuthStatus.initial) return;
  ref.listenManual(authProvider, (_, next) {
    if (next.status != AuthStatus.initial && mounted) {}
  });
}
```

`_startAnimation` içinde `_waitForAuth()` → `_checkVersionAndAuth()` olarak değiştir.

**Step 2: app.dart — VersionChecker wrap**

`lib/app.dart`'ta `MaterialApp.router` veya router delegate'in child'ını `VersionChecker` ile wrap et.

Import:
```dart
import 'package:qulo_v2/core/services/version_checker.dart';
```

`MaterialApp.router`'ın `builder` parametresine ekle (varsa mevcut builder'ı wrap et, yoksa yeni builder ekle):

```dart
builder: (context, child) {
  return VersionChecker(
    child: child ?? const SizedBox.shrink(),
  );
},
```

**Step 3: Commit**
```bash
git add lib/features/splash/splash_screen.dart lib/app.dart
git commit -m "feat: integrate version check into splash flow and app lifecycle"
```

---

### Task 15: Flutter — url_launcher import kontrolü + package_info_plus

**Files:**
- Modify: `pubspec.yaml` (gerekirse)

**Step 1: pubspec.yaml'da package_info_plus ve shared_preferences dependency'lerini kontrol et**

Eğer yoksa ekle:
```yaml
  package_info_plus: ^8.0.0
  shared_preferences: ^2.2.0
```

`url_launcher` zaten `UrlLauncherManager` var — mevcut olmalı.

**Step 2: flutter pub get çalıştır**
```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter pub get
```

**Step 3: Commit (sadece değişiklik varsa)**
```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: ensure package_info_plus and shared_preferences deps"
```

---

### Task 16: Backend — Admin Panel'den App Config Yönetimi

**Files:**
- Modify: `server/src/admin/admin.controller.ts` (yeni handler'lar)
- Modify: `server/src/admin/admin.routes.ts` (yeni route'lar)
- Create: `server/src/admin/views/app-config.ejs` (admin panel sayfası)

**Step 1: admin.controller.ts'e handler'lar ekle**

```typescript
import { appConfigService } from "../services/app-config.service.js";

export async function getAppConfigPageHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const { data } = await supabase.from("app_config").select("*").limit(1).single();
    res.render("app-config", { config: data, success: req.query.success });
  } catch (err) {
    next(err);
  }
}

export async function updateAppConfigHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const {
      min_version_ios, min_version_android,
      latest_version_ios, latest_version_android,
      store_url_ios, store_url_android,
      is_maintenance, maintenance_message_tr, maintenance_message_en,
      is_force_update_enabled,
    } = req.body;

    await appConfigService.updateConfig({
      min_version_ios,
      min_version_android,
      latest_version_ios,
      latest_version_android,
      store_url_ios,
      store_url_android,
      is_maintenance: is_maintenance === "on",
      maintenance_message_tr: maintenance_message_tr || null,
      maintenance_message_en: maintenance_message_en || null,
      is_force_update_enabled: is_force_update_enabled === "on",
    });

    res.redirect("/admin/app-config?success=1");
  } catch (err) {
    next(err);
  }
}
```

**Step 2: admin.routes.ts'e route ekle**

```typescript
router.get("/app-config", adminAuth, getAppConfigPageHandler);
router.post("/app-config", adminAuth, updateAppConfigHandler);
```

**Step 3: app-config.ejs görünümünü yaz**

Basit form: tüm alanlar için input'lar, checkbox'lar (is_maintenance, is_force_update_enabled), submit butonu. Mevcut admin panel tasarım pattern'ini takip et.

**Step 4: Commit**
```bash
git add server/src/admin/admin.controller.ts server/src/admin/admin.routes.ts server/src/admin/views/app-config.ejs
git commit -m "feat: add app config management page to admin panel"
```

---

### Task 17: Test & Doğrulama

**Step 1: Backend endpoint'i test et**

```bash
curl -X GET http://localhost:3001/api/v1/app/config \
  -H "x-app-platform: ios" \
  -H "Accept-Language: tr"
```

Beklenen response:
```json
{
  "minVersion": "2.0.0",
  "latestVersion": "2.0.0",
  "storeUrl": "",
  "isMaintenance": false,
  "maintenanceMessage": null,
  "isForceUpdateEnabled": true
}
```

**Step 2: Flutter analyze**
```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze
```

**Step 3: Admin panelden force update'i test et**
- Tarayıcıda `/admin/app-config` sayfasını aç
- `min_version_ios` = `99.0.0` yap → Uygulamada force update ekranı görmeli
- `is_maintenance` = true yap → Uygulamada maintenance ekranı görmeli
- Geri al: `min_version` = `2.0.0`, `is_maintenance` = false

**Step 4: Final commit**
```bash
git add -A
git commit -m "feat: complete app version & force update system"
```
