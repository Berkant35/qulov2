import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/widgets/in_app_banner.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/locale_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/notification_provider.dart';
import 'package:qulo_v2/providers/theme_provider.dart';
import 'package:qulo_v2/core/services/deep_link_parser.dart';
import 'package:qulo_v2/providers/deep_link_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/page_messages_provider.dart';
import 'package:qulo_v2/providers/referral_provider.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/install_referrer_manager.dart';
import 'package:qulo_v2/core/utils/install_referrer_code.dart';
import 'package:qulo_v2/core/services/pending_languages_store.dart';
import 'package:qulo_v2/core/services/pending_referral_store.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/interceptors/session_interceptor.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';
import 'package:qulo_v2/routing/app_router.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';

class QuloApp extends ConsumerStatefulWidget {
  const QuloApp({super.key});

  @override
  ConsumerState<QuloApp> createState() => _QuloAppState();
}

class _QuloAppState extends ConsumerState<QuloApp> with WidgetsBindingObserver {
  bool _callbacksSet = false;
  bool _versionManagerSet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Bicimlendirme: locale (bolge dahil) ve profil ulkesi degisince manager yeniden kurulur.
    ref.listenManual<Locale>(
      localeProvider,
      (_, next) => _configureFormat(next),
      fireImmediately: true,
    );
    ref.listenManual<String?>(
      userProvider.select((u) => u.valueOrNull?.country),
      (_, __) => _configureFormat(ref.read(localeProvider)),
    );

    // Force logout callback — refresh token expire olduğunda tetiklenir
    NetworkManager.instance.onForceLogout =
        () => ref.read(authProvider.notifier).forceLogout();

    // Login transition (unauth → auth) — current UI locale'i backend'e sync et
    ref.listenManual<AuthState>(authProvider, (prev, next) {
      final wasAuthenticated = prev?.status == AuthStatus.authenticated;
      if (next.status == AuthStatus.authenticated && !wasAuthenticated) {
        final code = ref.read(localeProvider).languageCode;
        unawaited(ref.read(userRepositoryProvider).updateProfile({'locale': code}));
        // İlk authenticated anında sayfa mesajlarını çek
        ref.read(pageMessagesProvider.notifier).fetch();
        // Faz 1: onboarding'de (pre-auth) seçilen dilleri flush et.
        unawaited(_flushPendingLanguages(ref));
        // Kurulumla gelen davet kodu (Play Install Referrer) — auth'tan önce
        // yakalandı, uygulanabildiği ilk an burası.
        unawaited(_flushPendingReferral(ref));
      }
    });

    ref.read(analyticsManagerProvider).logAppOpen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationCallbacks();
      _setupDeepLinks();
      unawaited(_captureInstallReferrer(ref));
      _setupVersionManager();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _configureFormat(Locale locale) {
    final country = ref.read(userProvider).valueOrNull?.country;
    unawaited(FormatManager.instance.configure(locale, profileCountry: country));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final analytics = ref.read(analyticsManagerProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        analytics.logAppForeground();
        // Start new analytics session on resume
        SessionInterceptor.resetSession();
        // Auth-required side effects yalnızca authenticated iken. Aksi halde
        // ATT modal / OS resume cycle'ları force-logout fırtınası tetikliyor.
        if (ref.read(authProvider).status == AuthStatus.authenticated) {
          // Permission-dependent provider'ları tekrar kontrol et
          ref.read(locationProvider.notifier).onAppResumed();
          // Restart presence heartbeat
          ref.read(presenceManagerProvider).start();
          // Backend activity heartbeat (debounce in repository)
          unawaited(ref.read(userRepositoryProvider).heartbeat());
          // Resume'da sayfa mesajlarını güncelle
          ref.read(pageMessagesProvider.notifier).fetch();
        }
      case AppLifecycleState.paused:
        analytics.logAppBackground();
        // Flush any buffered analytics events before backgrounding
        unawaited(AnalyticsForwarder.instance.flush());
        // Send offline + stop heartbeat
        ref.read(presenceManagerProvider).stop();
      case AppLifecycleState.detached:
        // App being killed — try to send offline
        ref.read(presenceManagerProvider).stop();
      default:
        break;
    }
  }

  void _setupVersionManager() {
    if (_versionManagerSet) return;
    _versionManagerSet = true;

    ref.read(versionManagerProvider).init(
      onCheckVersion: () =>
          ref.read(appConfigProvider.notifier).checkVersion(),
      onResumeResult: (status) {
        final manager = ref.read(versionManagerProvider);
        if (manager.isDialogShown) return;
        manager.setDialogShown(true);

        final config = ref.read(appConfigProvider).config;
        final navService = ref.read(navigationServiceProvider);
        final ctx = rootNavigatorKey.currentContext;
        if (ctx == null) return;

        if (status == UpdateStatus.forceUpdate) {
          navService.showAppDialog(
            CustomDialog(
              name: 'force_update_resume',
              barrierDismissible: false,
              builder: (dialogCtx) => PopScope(
                canPop: false,
                child: AlertDialog(
                  title: Text(dialogCtx.tr('update_required_title')),
                  content: Text(dialogCtx.tr('update_required_message')),
                  actions: [
                    TextButton(
                      onPressed: () {
                        if (config != null && config.storeUrl.isNotEmpty) {
                          ref.read(urlLauncherManagerProvider).launch(config.storeUrl);
                        }
                      },
                      child: Text(dialogCtx.tr('update_button')),
                    ),
                  ],
                ),
              ),
            ),
          ).then((_) => manager.setDialogShown(false));
        } else if (status == UpdateStatus.maintenance) {
          navService.showAppDialog(
            CustomDialog(
              name: 'maintenance_resume',
              barrierDismissible: false,
              builder: (dialogCtx) => PopScope(
                canPop: false,
                child: AlertDialog(
                  title: Text(dialogCtx.tr('maintenance_title')),
                  content: Text(
                    config?.maintenanceMessage ??
                        dialogCtx.tr('maintenance_default_message'),
                  ),
                ),
              ),
            ),
          ).then((_) => manager.setDialogShown(false));
        }
      },
    );
  }

  void _setupNotificationCallbacks() {
    if (_callbacksSet) return;
    _callbacksSet = true;

    ref.read(notificationProvider.notifier).setUICallbacks(
      onForegroundNotification: (message) {
        final title = message.notification?.title ?? 'Qulo';
        final body = message.notification?.body ?? '';
        final actionUrl = message.data['action_url'] as String?;

        final overlayState = rootNavigatorKey.currentState?.overlay;
        if (overlayState == null) return;

        final bannerId = 'banner_${message.messageId ?? message.hashCode}';

        OverlayQueueService.instance.enqueue(
          OverlayRequest(
            id: bannerId,
            priority: OverlayPriority.notification,
            show: () {
              final completer = Completer<void>();
              bool removed = false;
              late OverlayEntry entry;
              void removeEntry() {
                if (removed) return;
                removed = true;
                entry.remove();
                if (!completer.isCompleted) completer.complete();
              }

              AnalyticsManager.instance.logEvent(
                AnalyticsEvents.notificationBannerShow,
                params: {AnalyticsEvents.paramType: message.data['type'] ?? 'unknown'},
              );

              entry = OverlayEntry(
                builder: (_) => Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InAppBanner(
                      title: title,
                      body: body,
                      onTap: () {
                        AnalyticsManager.instance.logEvent(
                          AnalyticsEvents.notificationBannerTap,
                          params: {AnalyticsEvents.paramType: message.data['type'] ?? 'unknown'},
                        );
                        removeEntry();
                        if (actionUrl != null && actionUrl.isNotEmpty) {
                          final navType = DeepLinkParser.resolveNavType(actionUrl);
                          final router = ref.read(routerProvider);
                          navType == DeepLinkNavType.push
                              ? router.push(actionUrl)
                              : router.go(actionUrl);
                        }
                      },
                      onDismiss: () {
                        AnalyticsManager.instance.logEvent(
                          AnalyticsEvents.notificationBannerDismiss,
                          params: {AnalyticsEvents.paramType: message.data['type'] ?? 'unknown'},
                        );
                        removeEntry();
                      },
                    ),
                  ),
                ),
              );
              overlayState.insert(entry);
              // Failsafe: InAppBanner unmount olursa onDismiss atlanabilir;
              // widget'tan bağımsız bir timer removeEntry'i garanti eder ki
              // kuyruk asla kilitlenmesin (banner ~4sn + 300ms reverse içinde
              // normalde kendi kapanır; bu 6sn failsafe sadece anormal durumda).
              Timer(const Duration(seconds: 6), removeEntry);
              return completer.future;
            },
          ),
        );
      },
      onNavigate: (actionUrl) {
        final navType = DeepLinkParser.resolveNavType(actionUrl);
        final router = ref.read(routerProvider);
        navType == DeepLinkNavType.push
            ? router.push(actionUrl)
            : router.go(actionUrl);
      },
    );
  }

  void _setupDeepLinks() {
    final deepLinkManager = ref.read(deepLinkManagerProvider);
    final analytics = ref.read(analyticsManagerProvider);
    deepLinkManager.init();

    // Cold start — ilk link
    deepLinkManager.getInitialLink().then((uri) {
      if (uri != null) {
        analytics.logDeepLinkReceived(uri.toString(), source: 'initial');
        _handleDeepLink(uri);
      }
    });

    // Foreground/background — stream
    deepLinkManager.listen((uri) {
      analytics.logDeepLinkReceived(uri.toString(), source: 'stream');
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final result = DeepLinkParser.parse(uri);
    final analytics = ref.read(analyticsManagerProvider);

    if (result == null) {
      analytics.logDeepLinkInvalid(uri.toString(), 'unsupported_path');
      return;
    }

    final authState = ref.read(authProvider);
    final isAuth = authState.status == AuthStatus.authenticated;

    if (result.requiresAuth && !isAuth) {
      // Deferred deep link — login sonrasi replay edilecek
      ref.read(pendingDeepLinkProvider.notifier).state = result.goRouterPath;
      analytics.logDeepLinkDeferred(result.goRouterPath);
      return;
    }

    // Hemen navigate et
    ref.read(navigationServiceProvider).navigateDeepLink(result);
    analytics.logDeepLinkNavigated(
      result.goRouterPath,
      result.navType.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final appThemeMode = ref.watch(themeProvider);
    final themeMode = switch (appThemeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'Qulo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      // Bolge korunsun: `Locale('en','US')` desteklenen `Locale('en')`'e indirgenmesin.
      localeResolutionCallback: (locale, _) =>
          locale ?? const Locale(AppConstants.fallbackLocale),
      // Tek kaynak: AppConstants.supportedQuestionLocales (delegate ile aynı küme).
      supportedLocales: AppConstants.supportedQuestionLocales
          .map((code) => Locale(code))
          .toList(growable: false),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

/// Kurulumla gelen davet kodunu bir kez okuyup saklar.
///
/// Kod, arkadaşın paylaştığı linkle Play'e gidip kuran kullanıcıda cihazda
/// hazır duruyor (`web/src/lib/constants/links.ts` onu `utm_content`'e koyuyor)
/// ama uygulama 27.09.2026'ya kadar onu hiç okumuyordu: kodu elle yazmak
/// gerekiyordu ve `referrals` tablosu boştu.
///
/// Bir kez okunur — Play aynı değeri her açılışta döndürüyor; tekrar okumak,
/// kullanıcı vazgeçip kodu sildikten sonra onu geri getirirdi.
Future<void> _captureInstallReferrer(WidgetRef ref) async {
  final wasRead = await PendingReferralStore.wasReferrerRead();
  if (wasRead) return;

  // Karar (neyin işaretleneceği, neyin saklanacağı) `captureInstallReferrer`
  // içinde ve test altında — burada yalnız yan etkiler var.
  final capture = captureInstallReferrer(
    wasRead: wasRead,
    raw: await InstallReferrerManager.instance.rawReferrer(),
  );
  if (!capture.markRead) return;
  await PendingReferralStore.markReferrerRead();

  final code = capture.code;
  if (code == null) return;
  await PendingReferralStore.write(code);

  // Yakalama, auth geçişi listener'ından SONRA bitmiş olabilir (yeni kurulumda
  // kayıt akışı çok daha uzun sürdüğü için pratikte olmaz, ama garanti değil).
  // O durumda kod bir sonraki açılışa kalırdı; zaten girişliysek şimdi uygula.
  if (ref.read(authProvider).status == AuthStatus.authenticated) {
    await _flushPendingReferral(ref);
  }
}

/// Bekleyen davet kodunu uygular (ilk authenticated an).
///
/// Ağ hatasında kod saklanır, sonraki auth geçişinde tekrar denenir; kalıcı
/// redlerde (kendini davet etme, zaten davet edilmiş, geçersiz kod) silinir —
/// yoksa her açılışta boşuna istek atılır.
/// İki çağrı yeri var (yakalama + auth geçişi) ve ikisi üst üste gelebilir;
/// sunucu ikinciye `ALREADY_REFERRED` döndüğü için sonuç yine doğru olurdu ama
/// istek boşa gidiyordu.
bool _flushingReferral = false;

Future<void> _flushPendingReferral(WidgetRef ref) async {
  if (_flushingReferral) return;
  final code = await PendingReferralStore.read();
  if (code == null) return;
  _flushingReferral = true;
  try {
    await _applyPendingReferral(ref, code);
  } finally {
    _flushingReferral = false;
  }
}

Future<void> _applyPendingReferral(WidgetRef ref, String code) async {
  final result = await ref.read(referralProvider.notifier).applyCode(code);
  result.when(
    success: (_) => PendingReferralStore.clear(),
    failure: (f) {
      final errorCode = switch (f) {
        ServerFailure(:final code) => code,
        _ => 'NETWORK',
      };
      if (shouldDropPendingReferral(errorCode)) PendingReferralStore.clear();
    },
  );
}

/// Onboarding carousel'de (auth öncesi) seçilen dilleri backend'e flush eder.
/// Başarısız olursa [PendingLanguagesStore] key'i silinmez; bir sonraki
/// unauth→auth geçişinde tekrar denenir.
Future<void> _flushPendingLanguages(WidgetRef ref) async {
  final pending = await PendingLanguagesStore.read();
  if (pending.isEmpty) return;
  final result = await ref.read(userRepositoryProvider).setUserLanguages(pending);
  result.when(
    success: (_) => PendingLanguagesStore.clear(),
    failure: (_) {}, // başarısızsa key kalır, sonraki auth'ta tekrar denenir
  );
}
