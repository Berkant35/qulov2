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
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/interceptors/session_interceptor.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/routing/app_router.dart';

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

    // Force logout callback — refresh token expire olduğunda tetiklenir
    NetworkManager.instance.onForceLogout =
        () => ref.read(authProvider.notifier).forceLogout();

    ref.read(analyticsManagerProvider).logAppOpen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationCallbacks();
      _setupDeepLinks();
      _setupVersionManager();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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

        final context = rootNavigatorKey.currentContext;
        if (context == null) return;

        final overlayState = rootNavigatorKey.currentState?.overlay;
        if (overlayState == null) return;

        bool removed = false;
        late OverlayEntry entry;
        void removeEntry() {
          if (removed) return;
          removed = true;
          entry.remove();
        }

        AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationBannerShow, params: {
          AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
        });

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
                  AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationBannerTap, params: {
                    AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
                  });
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
                  AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationBannerDismiss, params: {
                    AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
                  });
                  removeEntry();
                },
              ),
            ),
          ),
        );
        overlayState.insert(entry);
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
      supportedLocales: const [
            Locale('tr'), Locale('en'), Locale('de'), Locale('fr'),
            Locale('es'), Locale('ar'), Locale('ru'), Locale('pt'),
            Locale('it'), Locale('ja'), Locale('ko'), Locale('zh'),
            Locale('nl'), Locale('pl'), Locale('sv'), Locale('hi'),
          ],
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
