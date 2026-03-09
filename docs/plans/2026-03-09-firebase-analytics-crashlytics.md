# Firebase Analytics & Crashlytics Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Uygulamaya kapsamlı Firebase Analytics event tracking (~148 event), Crashlytics breadcrumb sistemi, non-fatal error genişletme ve 15 user property entegrasyonu eklemek.

**Architecture:** Singleton AnalyticsManager pattern — mevcut manager convention'ına uygun (ImagePickerManager, LocationManager gibi). Her logEvent() çağrısı Firebase Analytics'e event + Crashlytics'e breadcrumb yazar. NavigationService observer pattern'i ile otomatik screen tracking.

**Tech Stack:** Firebase Analytics (firebase_analytics: ^11.4.1), Firebase Crashlytics (firebase_crashlytics: ^4.2.1), Flutter Riverpod, GoRouter

---

## Task 1: Analytics Event Sabitleri

**Files:**
- Create: `lib/core/services/analytics_events.dart`

**Step 1: Event sabit dosyasını oluştur**

```dart
abstract class AnalyticsEvents {
  // ─── Auth ───
  static const authLoginStart = 'auth_login_start';
  static const authLoginSuccess = 'auth_login_success';
  static const authLoginFail = 'auth_login_fail';
  static const authRegisterStart = 'auth_register_start';
  static const authRegisterSuccess = 'auth_register_success';
  static const authRegisterFail = 'auth_register_fail';
  static const authLogout = 'auth_logout';
  static const authForgotPassword = 'auth_forgot_password';

  // ─── Onboarding ───
  static const onboardingStart = 'onboarding_start';
  static const onboardingStepView = 'onboarding_step_view';
  static const onboardingStepComplete = 'onboarding_step_complete';
  static const onboardingStepSkip = 'onboarding_step_skip';
  static const onboardingPhotoAdd = 'onboarding_photo_add';
  static const onboardingPhotoRemove = 'onboarding_photo_remove';
  static const onboardingGenderSelect = 'onboarding_gender_select';
  static const onboardingBirthdateSet = 'onboarding_birthdate_set';
  static const onboardingLocationPermit = 'onboarding_location_permit';
  static const onboardingComplete = 'onboarding_complete';

  // ─── Discover ───
  static const discoverScreenView = 'discover_screen_view';
  static const discoverSwipeRight = 'discover_swipe_right';
  static const discoverSwipeLeft = 'discover_swipe_left';
  static const discoverSwipeVelocity = 'discover_swipe_velocity';
  static const discoverProfileExpand = 'discover_profile_expand';
  static const discoverPhotoView = 'discover_photo_view';
  static const discoverPhotoZoom = 'discover_photo_zoom';
  static const discoverScrollDepth = 'discover_scroll_depth';
  static const discoverUndo = 'discover_undo';
  static const discoverLimitReached = 'discover_limit_reached';
  static const discoverCardsEmpty = 'discover_cards_empty';
  static const discoverFilterOpen = 'discover_filter_open';
  static const discoverFilterApply = 'discover_filter_apply';
  static const discoverSessionStart = 'discover_session_start';
  static const discoverSessionEnd = 'discover_session_end';

  // ─── Match ───
  static const matchNew = 'match_new';
  static const matchScreenView = 'match_screen_view';
  static const matchOpenChat = 'match_open_chat';
  static const matchUnmatch = 'match_unmatch';
  static const matchListScroll = 'match_list_scroll';
  static const matchTapProfile = 'match_tap_profile';

  // ─── Chat ───
  static const chatOpen = 'chat_open';
  static const chatClose = 'chat_close';
  static const chatMessageSend = 'chat_message_send';
  static const chatMessageReceive = 'chat_message_receive';
  static const chatImageSend = 'chat_image_send';
  static const chatImageView = 'chat_image_view';
  static const chatKeyboardOpen = 'chat_keyboard_open';
  static const chatKeyboardClose = 'chat_keyboard_close';
  static const chatScrollToTop = 'chat_scroll_to_top';
  static const chatTypingStart = 'chat_typing_start';
  static const chatTypingDuration = 'chat_typing_duration';
  static const chatRetrySend = 'chat_retry_send';
  static const chatLinkTap = 'chat_link_tap';
  static const chatFirstMessage = 'chat_first_message';

  // ─── Quiz ───
  static const quizStart = 'quiz_start';
  static const quizAnswer = 'quiz_answer';
  static const quizComplete = 'quiz_complete';
  static const quizAbandon = 'quiz_abandon';

  // ─── Questions ───
  static const questionCreateStart = 'question_create_start';
  static const questionCreateComplete = 'question_create_complete';
  static const questionCreateAbandon = 'question_create_abandon';
  static const questionDelete = 'question_delete';
  static const questionEdit = 'question_edit';
  static const questionAnalyticsView = 'question_analytics_view';
  static const questionSlotLimitHit = 'question_slot_limit_hit';
  static const questionListView = 'question_list_view';

  // ─── Profile ───
  static const profileViewOwn = 'profile_view_own';
  static const profileEditStart = 'profile_edit_start';
  static const profileEditSave = 'profile_edit_save';
  static const profileEditCancel = 'profile_edit_cancel';
  static const profilePhotoAdd = 'profile_photo_add';
  static const profilePhotoRemove = 'profile_photo_remove';
  static const profilePhotoReorder = 'profile_photo_reorder';
  static const profileCompletionChange = 'profile_completion_change';
  static const profilePreview = 'profile_preview';
  static const profileSettingsOpen = 'profile_settings_open';
  static const profileShare = 'profile_share';
  static const profileBioEdit = 'profile_bio_edit';
  static const profileScreenDuration = 'profile_screen_duration';
  static const profileTabSwitch = 'profile_tab_switch';

  // ─── Diamonds & Monetization ───
  static const diamondsScreenView = 'diamonds_screen_view';
  static const diamondsPurchaseStart = 'diamonds_purchase_start';
  static const diamondsPurchaseSuccess = 'diamonds_purchase_success';
  static const diamondsPurchaseFail = 'diamonds_purchase_fail';
  static const diamondsPurchaseCancel = 'diamonds_purchase_cancel';
  static const diamondsSpend = 'diamonds_spend';
  static const diamondsBalanceView = 'diamonds_balance_view';
  static const subscriptionScreenView = 'subscription_screen_view';
  static const subscriptionCompareView = 'subscription_compare_view';
  static const subscriptionPurchaseStart = 'subscription_purchase_start';
  static const subscriptionPurchaseSuccess = 'subscription_purchase_success';
  static const subscriptionPurchaseFail = 'subscription_purchase_fail';
  static const subscriptionCancel = 'subscription_cancel';
  static const subscriptionRenew = 'subscription_renew';
  static const upsellShown = 'upsell_shown';
  static const upsellTapCta = 'upsell_tap_cta';
  static const upsellDismiss = 'upsell_dismiss';
  static const upsellConvert = 'upsell_convert';

  // ─── Passport ───
  static const passportActivate = 'passport_activate';
  static const passportDeactivate = 'passport_deactivate';
  static const passportExpire = 'passport_expire';
  static const passportCitySelect = 'passport_city_select';
  static const passportScreenView = 'passport_screen_view';
  static const passportMapInteract = 'passport_map_interact';

  // ─── Notifications ───
  static const notificationPermissionAsk = 'notification_permission_ask';
  static const notificationPermissionGrant = 'notification_permission_grant';
  static const notificationPermissionDeny = 'notification_permission_deny';
  static const notificationReceiveForeground = 'notification_receive_foreground';
  static const notificationReceiveBackground = 'notification_receive_background';
  static const notificationTap = 'notification_tap';
  static const notificationBannerShow = 'notification_banner_show';
  static const notificationBannerTap = 'notification_banner_tap';
  static const notificationBannerDismiss = 'notification_banner_dismiss';
  static const notificationInboxView = 'notification_inbox_view';

  // ─── App Lifecycle ───
  static const appOpen = 'app_open';
  static const appForeground = 'app_foreground';
  static const appBackground = 'app_background';
  static const appForceUpdateShown = 'app_force_update_shown';
  static const appOptionalUpdateShown = 'app_optional_update_shown';
  static const appMaintenanceShown = 'app_maintenance_shown';
  static const appErrorScreen = 'app_error_screen';
  static const appNetworkChange = 'app_network_change';
  static const appNetworkTimeout = 'app_network_timeout';
  static const appApiError = 'app_api_error';
  static const appApiSuccess = 'app_api_success';
  static const appDeepLinkOpen = 'app_deep_link_open';
  static const appSplashDuration = 'app_splash_duration';
  static const appRetryAction = 'app_retry_action';
  static const appPermissionRequest = 'app_permission_request';

  // ─── UI Micro-Interactions ───
  static const uiTabSwitch = 'ui_tab_switch';
  static const uiDialogShow = 'ui_dialog_show';
  static const uiDialogAction = 'ui_dialog_action';
  static const uiBottomSheetShow = 'ui_bottom_sheet_show';
  static const uiBottomSheetDismiss = 'ui_bottom_sheet_dismiss';
  static const uiPullToRefresh = 'ui_pull_to_refresh';
  static const uiScrollToEnd = 'ui_scroll_to_end';
  static const uiInputFocus = 'ui_input_focus';
  static const uiInputBlur = 'ui_input_blur';
  static const uiButtonTap = 'ui_button_tap';
  static const uiImageLoadFail = 'ui_image_load_fail';
  static const uiAnimationComplete = 'ui_animation_complete';

  // ─── Settings ───
  static const settingsScreenView = 'settings_screen_view';
  static const settingsChange = 'settings_change';
  static const settingsNotificationToggle = 'settings_notification_toggle';
  static const settingsDistanceChange = 'settings_distance_change';
  static const settingsAgeRangeChange = 'settings_age_range_change';
  static const settingsLanguageChange = 'settings_language_change';
  static const settingsDeleteAccountStart = 'settings_delete_account_start';
  static const settingsDeleteAccountConfirm = 'settings_delete_account_confirm';

  // ─── Common Param Keys ───
  static const paramMethod = 'method';
  static const paramDurationMs = 'duration_ms';
  static const paramErrorCode = 'error_code';
  static const paramStep = 'step';
  static const paramStepName = 'step_name';
  static const paramStepIndex = 'step_index';
  static const paramPhotoIndex = 'photo_index';
  static const paramSource = 'source';
  static const paramGender = 'gender';
  static const paramAge = 'age';
  static const paramGranted = 'granted';
  static const paramPhotosCount = 'photos_count';
  static const paramTargetUserId = 'target_user_id';
  static const paramSwipeDurationMs = 'swipe_duration_ms';
  static const paramCardIndex = 'card_index';
  static const paramDirection = 'direction';
  static const paramVelocity = 'velocity';
  static const paramDepthPercent = 'depth_percent';
  static const paramTotalSwipesToday = 'total_swipes_today';
  static const paramSwipesCountSession = 'swipes_count_session';
  static const paramAgeMin = 'age_min';
  static const paramAgeMax = 'age_max';
  static const paramDistance = 'distance';
  static const paramSwipesRight = 'swipes_right';
  static const paramSwipesLeft = 'swipes_left';
  static const paramProfilesViewed = 'profiles_viewed';
  static const paramRemainingSwipes = 'remaining_swipes';
  static const paramMatchUserId = 'match_user_id';
  static const paramIsInstant = 'is_instant';
  static const paramMatchesCount = 'matches_count';
  static const paramTimeSinceMatchMs = 'time_since_match_ms';
  static const paramReason = 'reason';
  static const paramScrollDepthPercent = 'scroll_depth_percent';
  static const paramChatId = 'chat_id';
  static const paramType = 'type';
  static const paramCharCount = 'char_count';
  static const paramMessageId = 'message_id';
  static const paramMessagesSent = 'messages_sent';
  static const paramRetryCount = 'retry_count';
  static const paramUrlDomain = 'url_domain';
  static const paramQuizId = 'quiz_id';
  static const paramPartnerId = 'partner_id';
  static const paramQuestionIndex = 'question_index';
  static const paramScore = 'score';
  static const paramTotalDurationMs = 'total_duration_ms';
  static const paramQuestionType = 'question_type';
  static const paramQuestionId = 'question_id';
  static const paramCurrentSlots = 'current_slots';
  static const paramQuestionsCount = 'questions_count';
  static const paramFieldName = 'field_name';
  static const paramFromIndex = 'from_index';
  static const paramToIndex = 'to_index';
  static const paramOldPercent = 'old_percent';
  static const paramNewPercent = 'new_percent';
  static const paramTabName = 'tab_name';
  static const paramProductId = 'product_id';
  static const paramTier = 'tier';
  static const paramPrice = 'price';
  static const paramDiamondsAmount = 'diamonds_amount';
  static const paramSpendType = 'spend_type';
  static const paramRemainingBalance = 'remaining_balance';
  static const paramBalance = 'balance';
  static const paramCurrentTier = 'current_tier';
  static const paramDaysSubscribed = 'days_subscribed';
  static const paramTrigger = 'trigger';
  static const paramUpsellType = 'upsell_type';
  static const paramDestinationCity = 'destination_city';
  static const paramDurationUsedMs = 'duration_used_ms';
  static const paramCityName = 'city_name';
  static const paramIsActive = 'is_active';
  static const paramAction = 'action';
  static const paramActionUrl = 'action_url';
  static const paramUnreadCount = 'unread_count';
  static const paramBackgroundDurationMs = 'background_duration_ms';
  static const paramSessionDurationMs = 'session_duration_ms';
  static const paramCurrentVersion = 'current_version';
  static const paramRequiredVersion = 'required_version';
  static const paramLatestVersion = 'latest_version';
  static const paramErrorType = 'error_type';
  static const paramScreen = 'screen';
  static const paramStatus = 'status';
  static const paramEndpoint = 'endpoint';
  static const paramStatusCode = 'status_code';
  static const paramUrl = 'url';
  static const paramActionType = 'action_type';
  static const paramPermissionType = 'permission_type';
  static const paramFromTab = 'from_tab';
  static const paramToTab = 'to_tab';
  static const paramDialogType = 'dialog_type';
  static const paramSheetType = 'sheet_type';
  static const paramListType = 'list_type';
  static const paramHasValue = 'has_value';
  static const paramButtonId = 'button_id';
  static const paramAnimationType = 'animation_type';
  static const paramSettingName = 'setting_name';
  static const paramOldValue = 'old_value';
  static const paramNewValue = 'new_value';
  static const paramEnabled = 'enabled';
  static const paramOldKm = 'old_km';
  static const paramNewKm = 'new_km';
  static const paramMin = 'min';
  static const paramMax = 'max';
  static const paramLanguage = 'language';
  static const paramDaysSinceRegister = 'days_since_register';
  static const paramCurrentBalance = 'current_balance';
}
```

**Step 2: Commit**

```bash
git add lib/core/services/analytics_events.dart
git commit -m "feat: add analytics event name constants"
```

---

## Task 2: Breadcrumb Model

**Files:**
- Create: `lib/core/services/analytics_breadcrumb.dart`

**Step 1: Breadcrumb model ve queue oluştur**

```dart
import 'dart:collection';

class BreadcrumbEntry {
  final String event;
  final Map<String, Object>? params;
  final DateTime timestamp;

  BreadcrumbEntry(this.event, this.params, this.timestamp);

  @override
  String toString() {
    final paramStr = params != null && params!.isNotEmpty ? ' $params' : '';
    return '${timestamp.toIso8601String()} $event$paramStr';
  }

  String toShortString() => event;
}

class BreadcrumbQueue {
  final int maxSize;
  final Queue<BreadcrumbEntry> _queue = Queue<BreadcrumbEntry>();

  BreadcrumbQueue({this.maxSize = 30});

  void add(BreadcrumbEntry entry) {
    _queue.add(entry);
    if (_queue.length > maxSize) {
      _queue.removeFirst();
    }
  }

  List<BreadcrumbEntry> get entries => _queue.toList();

  String getTrailSummary({int count = 5}) {
    final recent = _queue.toList().reversed.take(count);
    return recent.map((e) => e.toShortString()).join(' → ');
  }

  void clear() => _queue.clear();
}
```

**Step 2: Commit**

```bash
git add lib/core/services/analytics_breadcrumb.dart
git commit -m "feat: add breadcrumb model and queue for crash context"
```

---

## Task 3: AnalyticsManager Singleton

**Files:**
- Create: `lib/core/services/analytics_manager.dart`

**Step 1: AnalyticsManager singleton oluştur**

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:qulo_v2/core/services/analytics_breadcrumb.dart';

class AnalyticsManager {
  AnalyticsManager._();
  static final AnalyticsManager instance = AnalyticsManager._();

  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  final BreadcrumbQueue _breadcrumbs = BreadcrumbQueue(maxSize: 30);

  bool _initialized = false;
  String? _lastScreen;
  String? _lastAction;
  DateTime? _sessionStart;
  DateTime? _backgroundStart;

  Future<void> init() async {
    if (_initialized) return;
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _sessionStart = DateTime.now();
    _initialized = true;

    // Enable analytics collection
    await _analytics.setAnalyticsCollectionEnabled(kReleaseMode);
  }

  // ─── Core Event Logging ───

  void logEvent(String name, {Map<String, Object>? params}) {
    if (!_initialized) return;

    // Firebase Analytics
    _analytics.logEvent(name: name, parameters: params);

    // Crashlytics breadcrumb
    _crashlytics.log('EVENT: $name${params != null ? ' $params' : ''}');

    // Breadcrumb queue
    _breadcrumbs.add(BreadcrumbEntry(name, params, DateTime.now()));

    // Update last action
    _lastAction = name;
    _crashlytics.setCustomKey('last_action', name);
    _crashlytics.setCustomKey('breadcrumb_trail', _breadcrumbs.getTrailSummary());

    if (kDebugMode) {
      debugPrint('[Analytics] $name${params != null ? ' | $params' : ''}');
    }
  }

  // ─── Screen Tracking ───

  void logScreenView(String screenName, {String? screenClass}) {
    if (!_initialized) return;

    _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );

    _lastScreen = screenName;
    _crashlytics.setCustomKey('last_screen', screenName);
    _crashlytics.log('SCREEN: $screenName');
    _breadcrumbs.add(BreadcrumbEntry('screen_view:$screenName', null, DateTime.now()));

    if (kDebugMode) {
      debugPrint('[Analytics] Screen: $screenName');
    }
  }

  // ─── User Identity ───

  void setUserId(String? userId) {
    if (!_initialized) return;
    _analytics.setUserId(id: userId);
    if (userId != null) {
      _crashlytics.setUserIdentifier(userId);
    }
  }

  // ─── User Properties ───

  void setUserProperty(String name, String? value) {
    if (!_initialized) return;
    _analytics.setUserProperty(name: name, value: value);
    if (value != null) {
      _crashlytics.setCustomKey('up_$name', value);
    }
  }

  void updateUserProperties({
    String? subscriptionTier,
    String? diamondBalance,
    String? gender,
    String? ageRange,
    String? city,
    String? profileCompletion,
    String? totalMatches,
    String? totalMessagesSent,
    String? questionsCount,
    String? daysSinceRegister,
    String? hasPassport,
    String? notificationEnabled,
    String? appVersion,
    String? onboardingCompleted,
    String? photoCount,
  }) {
    if (subscriptionTier != null) setUserProperty('subscription_tier', subscriptionTier);
    if (diamondBalance != null) setUserProperty('diamond_balance', diamondBalance);
    if (gender != null) setUserProperty('gender', gender);
    if (ageRange != null) setUserProperty('age_range', ageRange);
    if (city != null) setUserProperty('city', city);
    if (profileCompletion != null) setUserProperty('profile_completion', profileCompletion);
    if (totalMatches != null) setUserProperty('total_matches', totalMatches);
    if (totalMessagesSent != null) setUserProperty('total_messages_sent', totalMessagesSent);
    if (questionsCount != null) setUserProperty('questions_count', questionsCount);
    if (daysSinceRegister != null) setUserProperty('days_since_register', daysSinceRegister);
    if (hasPassport != null) setUserProperty('has_passport', hasPassport);
    if (notificationEnabled != null) setUserProperty('notification_enabled', notificationEnabled);
    if (appVersion != null) setUserProperty('app_version', appVersion);
    if (onboardingCompleted != null) setUserProperty('onboarding_completed', onboardingCompleted);
    if (photoCount != null) setUserProperty('photo_count', photoCount);
  }

  // ─── App Lifecycle ───

  void logAppOpen() {
    _sessionStart = DateTime.now();
    logEvent('app_open');
    _crashlytics.setCustomKey('app_state', 'foreground');
  }

  void logAppForeground() {
    final backgroundDuration = _backgroundStart != null
        ? DateTime.now().difference(_backgroundStart!).inMilliseconds
        : 0;
    _backgroundStart = null;
    logEvent('app_foreground', params: {
      'background_duration_ms': backgroundDuration,
    });
    _crashlytics.setCustomKey('app_state', 'foreground');
  }

  void logAppBackground() {
    _backgroundStart = DateTime.now();
    final sessionDuration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!).inMilliseconds
        : 0;
    logEvent('app_background', params: {
      'session_duration_ms': sessionDuration,
    });
    _crashlytics.setCustomKey('app_state', 'background');
    _crashlytics.setCustomKey('session_duration_ms', sessionDuration.toString());
  }

  // ─── Non-Fatal Error Tracking ───

  void logNonFatalError(
    Object error,
    StackTrace? stack, {
    String? context,
    Map<String, String>? extras,
  }) {
    if (!_initialized) return;

    // Set context keys before recording
    if (context != null) {
      _crashlytics.setCustomKey('error_context', context);
    }
    extras?.forEach((key, value) {
      _crashlytics.setCustomKey('err_$key', value);
    });

    _crashlytics.recordError(error, stack, reason: context);

    // Also log as analytics event for non-fatal tracking
    final params = <String, Object>{};
    if (context != null) params['context'] = context;
    if (extras != null) params.addAll(extras);
    logEvent('app_non_fatal_error', params: params.isEmpty ? null : params);
  }

  // ─── Helpers ───

  static String diamondRange(int balance) {
    if (balance == 0) return '0';
    if (balance <= 100) return '1-100';
    if (balance <= 500) return '100-500';
    return '500+';
  }

  static String ageRange(int age) {
    if (age <= 24) return '18-24';
    if (age <= 30) return '25-30';
    if (age <= 40) return '31-40';
    return '40+';
  }

  static String completionRange(int percent) {
    if (percent <= 25) return '0-25';
    if (percent <= 50) return '25-50';
    if (percent <= 75) return '50-75';
    return '75-100';
  }

  static String matchRange(int count) {
    if (count == 0) return '0';
    if (count <= 5) return '1-5';
    if (count <= 20) return '6-20';
    return '20+';
  }

  static String messageRange(int count) {
    if (count == 0) return '0';
    if (count <= 10) return '1-10';
    if (count <= 50) return '11-50';
    return '50+';
  }

  static String dayRange(DateTime createdAt) {
    final days = DateTime.now().difference(createdAt).inDays;
    if (days <= 1) return '1';
    if (days <= 7) return '2-7';
    if (days <= 30) return '8-30';
    return '30+';
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/services/analytics_manager.dart
git commit -m "feat: add AnalyticsManager singleton with breadcrumb and non-fatal tracking"
```

---

## Task 4: Analytics Navigation Observer

**Files:**
- Create: `lib/core/navigation/observers/analytics_observer.dart`

**Step 1: Observer oluştur**

Bu observer `AppNavigationObserver` interface'ini implement eder ve her navigation event'ini `AnalyticsManager`'a iletir.

```dart
import 'package:qulo_v2/core/navigation/navigation_observer.dart';
import 'package:qulo_v2/core/navigation/navigation_event.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';

class AnalyticsNavigationObserver extends AppNavigationObserver {
  final AnalyticsManager _analytics = AnalyticsManager.instance;

  @override
  void onNavigate(NavigationEvent event) {
    _analytics.logScreenView(event.routeName);
  }

  @override
  void onPop(NavigationEvent event) {
    // Pop events don't need separate screen tracking;
    // the next navigate event will track the new screen.
  }

  @override
  void onDialogOpen(String dialogName, {Map<String, dynamic>? params}) {
    _analytics.logEvent(AnalyticsEvents.uiDialogShow, params: {
      AnalyticsEvents.paramDialogType: dialogName,
    });
  }

  @override
  void onDialogClose(String dialogName, {dynamic result}) {
    _analytics.logEvent(AnalyticsEvents.uiDialogAction, params: {
      AnalyticsEvents.paramDialogType: dialogName,
      AnalyticsEvents.paramAction: result?.toString() ?? 'dismiss',
    });
  }

  @override
  void onBottomSheetOpen(String sheetName, {Map<String, dynamic>? params}) {
    _analytics.logEvent(AnalyticsEvents.uiBottomSheetShow, params: {
      AnalyticsEvents.paramSheetType: sheetName,
    });
  }

  @override
  void onBottomSheetClose(String sheetName, {dynamic result}) {
    _analytics.logEvent(AnalyticsEvents.uiBottomSheetDismiss, params: {
      AnalyticsEvents.paramSheetType: sheetName,
    });
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/navigation/observers/analytics_observer.dart
git commit -m "feat: add AnalyticsNavigationObserver for automatic screen and UI tracking"
```

---

## Task 5: Provider & Initialization Entegrasyonu

**Files:**
- Modify: `lib/providers/api_provider.dart` (line 7 — import ekle, line 38 — provider ekle)
- Modify: `lib/core/navigation/navigation_provider.dart` (line 4 — import ekle, line 11 — observer ekle)
- Modify: `lib/main.dart` (line 7 — import ekle, line 20 — init ekle)

**Step 1: api_provider.dart'a analytics provider ekle**

Import ekle (line 7 civarı):
```dart
import 'package:qulo_v2/core/services/analytics_manager.dart';
```

Provider ekle (line 38'den sonra, versionManagerProvider'dan sonra):
```dart
final analyticsManagerProvider = Provider<AnalyticsManager>(
  (_) => AnalyticsManager.instance,
);
```

**Step 2: navigation_provider.dart'a analytics observer ekle**

Import ekle (line 4'ten sonra):
```dart
import 'package:qulo_v2/core/navigation/observers/analytics_observer.dart';
```

Observer listesine ekle (line 11 — `observers: [LoggingObserver()]` satırını güncelle):
```dart
observers: [LoggingObserver(), AnalyticsNavigationObserver()],
```

**Step 3: main.dart'a init ekle**

Import ekle (line 7'den sonra):
```dart
import 'package:qulo_v2/core/services/analytics_manager.dart';
```

Init ekle (line 20, `await ErrorManager.init();` satırından sonra):
```dart
await AnalyticsManager.instance.init();
```

**Step 4: Commit**

```bash
git add lib/providers/api_provider.dart lib/core/navigation/navigation_provider.dart lib/main.dart
git commit -m "feat: integrate AnalyticsManager provider, navigation observer, and init"
```

---

## Task 6: App Lifecycle Tracking

**Files:**
- Modify: `lib/app.dart` (line 23 — mixin ekle, lifecycle methods ekle)

**Step 1: QuloApp'e WidgetsBindingObserver ekle**

`_QuloAppState` class'ına `WidgetsBindingObserver` mixin'i ekle ve lifecycle event'lerini track et.

Class declaration'ı güncelle (line 23):
```dart
class _QuloAppState extends ConsumerState<QuloApp> with WidgetsBindingObserver {
```

Mevcut field'lardan sonra (line 26 civarı) import ve didChangeAppLifecycleState ekle:

initState ve dispose override'ları ekle (field tanımlarından sonra, `_setupVersionManager` methodundan önce):
```dart
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
    final analytics = ref.read(analyticsManagerProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        analytics.logAppForeground();
      case AppLifecycleState.paused:
        analytics.logAppBackground();
      default:
        break;
    }
  }
```

Import ekle (dosya başı):
```dart
import 'package:qulo_v2/providers/api_provider.dart'; // zaten var, analyticsManagerProvider için kontrol et
```

NOT: `api_provider.dart` zaten import edilmiş (line 9), bu yüzden `analyticsManagerProvider` erişilebilir.

**Step 2: Commit**

```bash
git add lib/app.dart
git commit -m "feat: add app lifecycle tracking (foreground/background/resume)"
```

---

## Task 7: ErrorManager Genişletme

**Files:**
- Modify: `lib/core/error/error_manager.dart`

**Step 1: ErrorManager'a breadcrumb ve genişletilmiş non-fatal error tracking ekle**

Mevcut `logError` method'unu güncelle ve yeni method'lar ekle. AnalyticsManager'ı import et ve breadcrumb entegrasyonu ekle.

Dosyanın tamamını güncelle:
```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';

class ErrorManager {
  static final _crashlytics = FirebaseCrashlytics.instance;

  static Future<void> init() async {
    FlutterError.onError = (details) {
      if (kReleaseMode) {
        _crashlytics.recordFlutterFatalError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kReleaseMode) {
        _crashlytics.recordError(error, stack, fatal: true);
      } else {
        debugPrint('Async error: $error\n$stack');
      }
      return true;
    };

    await _crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);
  }

  static void logError(Object error, [StackTrace? stack, String? reason]) {
    if (kReleaseMode) {
      _crashlytics.recordError(error, stack, reason: reason);
    } else {
      debugPrint('Error: $error${reason != null ? ' ($reason)' : ''}');
    }

    // Forward to AnalyticsManager for breadcrumb tracking
    AnalyticsManager.instance.logNonFatalError(error, stack, context: reason);
  }

  static void setUser(String userId) {
    _crashlytics.setUserIdentifier(userId);
    AnalyticsManager.instance.setUserId(userId);
  }

  static void setCustomKey(String key, Object value) {
    _crashlytics.setCustomKey(key, value);
  }

  /// Log API errors with extended context
  static void logApiError({
    required String endpoint,
    required int? statusCode,
    required int responseTimeMs,
    Object? error,
    StackTrace? stack,
  }) {
    logError(
      error ?? 'API Error: $endpoint ($statusCode)',
      stack,
      'API: $endpoint',
    );
  }

  /// Log network errors
  static void logNetworkError({
    required String endpoint,
    required String errorType,
    required int durationMs,
    Object? error,
    StackTrace? stack,
  }) {
    logError(
      error ?? 'Network Error: $errorType on $endpoint',
      stack,
      'Network: $endpoint ($errorType)',
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/error/error_manager.dart
git commit -m "feat: extend ErrorManager with breadcrumb forwarding and API/network error helpers"
```

---

## Task 8: Auth Events Entegrasyonu

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**Step 1: Auth provider'a analytics event'leri ekle**

Import ekle (dosya başı, line 5'ten sonra):
```dart
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
```

`checkAuth()` method'unda — line 80 (`ErrorManager.setUser(userId);`) sonrasına:
```dart
        AnalyticsManager.instance.setUserId(userId);
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authLoginSuccess, params: {
          AnalyticsEvents.paramMethod: 'auto',
        });
```

`login()` method'unda — line 146 (`ErrorManager.setUser(data.userId);`) sonrasına:
```dart
        AnalyticsManager.instance.setUserId(data.userId);
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authLoginSuccess, params: {
          AnalyticsEvents.paramMethod: 'email',
        });
```

`logout()` method'unda — line 166 methodun başına:
```dart
    AnalyticsManager.instance.logEvent(AnalyticsEvents.authLogout);
    AnalyticsManager.instance.setUserId(null);
```

`register()` method'unda — line 115 (state = state.copyWith(isLoading: true...)) öncesine:
```dart
    AnalyticsManager.instance.logEvent(AnalyticsEvents.authRegisterStart, params: {
      AnalyticsEvents.paramMethod: 'email',
    });
```

`register()` success callback'inde (line 128):
```dart
      success: (_) {
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authRegisterSuccess, params: {
          AnalyticsEvents.paramMethod: 'email',
        });
        state = state.copyWith(isLoading: false);
      },
```

`register()` failure callback'inde (line 129):
```dart
      failure: (f) {
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authRegisterFail, params: {
          AnalyticsEvents.paramMethod: 'email',
          AnalyticsEvents.paramErrorCode: f.message ?? 'unknown',
        });
        state = state.copyWith(isLoading: false, failure: f);
      },
```

`forgotPassword()` method'una (line 196):
```dart
  Future<Result<void>> forgotPassword(String email) async {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.authForgotPassword);
    return ref.read(authRepositoryProvider).forgotPassword(email);
  }
```

**Step 2: Commit**

```bash
git add lib/providers/auth_provider.dart
git commit -m "feat: add analytics events to auth flow (login, register, logout)"
```

---

## Task 9: Splash Screen Duration Tracking

**Files:**
- Modify: `lib/features/splash/screens/splash_screen.dart` (veya `lib/features/splash/splash_screen.dart`)

**Step 1: Splash ekranına süre tracking'i ekle**

Import ekle:
```dart
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
```

`_SplashScreenState` class'ına field ekle (line 27 civarı):
```dart
  final Stopwatch _splashStopwatch = Stopwatch()..start();
```

`_checkVersionAndAuth()` method'unun başına (line 80) ekle:
```dart
    _splashStopwatch.stop();
    AnalyticsManager.instance.logEvent(AnalyticsEvents.appSplashDuration, params: {
      AnalyticsEvents.paramDurationMs: _splashStopwatch.elapsedMilliseconds,
    });
```

`_showOptionalUpdateThenContinue()`'da — optional update dialog gösterildiğinde (line 113 civarı):
```dart
    AnalyticsManager.instance.logEvent(AnalyticsEvents.appOptionalUpdateShown, params: {
      AnalyticsEvents.paramCurrentVersion: '', // VersionManager'dan al
    });
```

`_checkVersionAndAuth()` switch cases'inde:
- maintenance case'ine ekle:
```dart
        AnalyticsManager.instance.logEvent(AnalyticsEvents.appMaintenanceShown);
```
- forceUpdate case'ine ekle:
```dart
        AnalyticsManager.instance.logEvent(AnalyticsEvents.appForceUpdateShown);
```

**Step 2: Commit**

```bash
git add lib/features/splash/splash_screen.dart
git commit -m "feat: add splash duration and update/maintenance screen analytics"
```

---

## Task 10: Notification Events Entegrasyonu

**Files:**
- Modify: `lib/core/services/notification_manager.dart`
- Modify: `lib/app.dart` (notification callback'lerde banner event'leri)

**Step 1: NotificationManager'a permission tracking ekle**

Import ekle:
```dart
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
```

`init()` method'unda — permission request sonrasına (line 37 civarı, `dev.log('[FCM] Permission status...')` satırından sonra):
```dart
    AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationPermissionAsk);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationPermissionGrant);
      AnalyticsManager.instance.setUserProperty('notification_enabled', 'true');
    } else {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationPermissionDeny);
      AnalyticsManager.instance.setUserProperty('notification_enabled', 'false');
    }
```

`setCallbacks()` method'unda — foreground message listener'ında (line 93-96 civarı):
```dart
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      dev.log('[FCM] Foreground message: ${message.notification?.title}', name: 'NotificationManager');
      AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationReceiveForeground, params: {
        AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
      });
      _onForegroundMessage?.call(message);
    });
```

Message opened app listener'ında (line 98-101):
```dart
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      dev.log('[FCM] Message opened app: ${message.notification?.title}', name: 'NotificationManager');
      AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationTap, params: {
        AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
        AnalyticsEvents.paramActionUrl: message.data['action_url'] ?? '',
      });
      _onMessageOpenedApp?.call(message);
    });
```

**Step 2: app.dart'taki banner callback'lerine event ekle**

`_setupNotificationCallbacks()` method'unda (line 114 civarı, `entry = OverlayEntry` öncesinde):
```dart
        AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationBannerShow, params: {
          AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
        });
```

Banner `onTap` callback'inde (line 124):
```dart
                onTap: () {
                  AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationBannerTap, params: {
                    AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
                  });
                  removeEntry();
                  if (actionUrl != null && actionUrl.isNotEmpty) {
                    ref.read(routerProvider).go(actionUrl);
                  }
                },
```

Banner `onDismiss` callback'inde (line 130):
```dart
                onDismiss: () {
                  AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationBannerDismiss, params: {
                    AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
                  });
                  removeEntry();
                },
```

**Step 3: Commit**

```bash
git add lib/core/services/notification_manager.dart lib/app.dart
git commit -m "feat: add notification permission, receive, and banner analytics events"
```

---

## Task 11: Feature-by-Feature Event Entegrasyonu — Discover

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart`
- Modify: İlgili discover provider dosyası (varsa)

**Step 1: Discover ekranına analytics event'leri ekle**

Bu task'ın detayları discover_screen.dart'ın mevcut yapısına bağlı. Genel pattern:

Import ekle:
```dart
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
```

Eklenecek event'ler (kod yerleştirmesi ekranın mevcut yapısına göre yapılacak):
- `initState` veya build'de: `discoverScreenView`, `discoverSessionStart`
- Swipe callback'lerinde: `discoverSwipeRight`, `discoverSwipeLeft`, `discoverSwipeVelocity`
- Profil expand: `discoverProfileExpand`
- Photo view: `discoverPhotoView`, `discoverPhotoZoom`
- Scroll: `discoverScrollDepth`
- Undo: `discoverUndo`
- Limit: `discoverLimitReached`
- Cards empty: `discoverCardsEmpty`
- Filter: `discoverFilterOpen`, `discoverFilterApply`
- dispose'da: `discoverSessionEnd` (session süre, swipe sayıları)

Session tracking için state field'lar:
```dart
final Stopwatch _sessionStopwatch = Stopwatch()..start();
int _swipesRight = 0;
int _swipesLeft = 0;
int _profilesViewed = 0;
```

dispose'da session end event'i:
```dart
AnalyticsManager.instance.logEvent(AnalyticsEvents.discoverSessionEnd, params: {
  AnalyticsEvents.paramDurationMs: _sessionStopwatch.elapsedMilliseconds,
  AnalyticsEvents.paramSwipesRight: _swipesRight,
  AnalyticsEvents.paramSwipesLeft: _swipesLeft,
  AnalyticsEvents.paramProfilesViewed: _profilesViewed,
});
```

**Step 2: Commit**

```bash
git add lib/features/discover/
git commit -m "feat: add discover screen analytics (swipes, sessions, filters)"
```

---

## Task 12: Feature-by-Feature Event Entegrasyonu — Chat

**Files:**
- Modify: `lib/features/chat/screens/chat_screen.dart`
- Modify: `lib/features/chat/screens/matches_screen.dart`

**Step 1: Chat ve matches ekranlarına analytics event'leri ekle**

Pattern aynı — import ekle, ilgili callback'lere event'ler yerleştir:

**matches_screen.dart:**
- `matchScreenView` (build/initState)
- `matchOpenChat` (chat'e tıklandığında, `time_since_match_ms` parametresi ile)
- `matchTapProfile` (profil'e tıklandığında)
- `matchListScroll` (scroll depth)

**chat_screen.dart:**
- `chatOpen` (initState)
- `chatClose` (dispose, duration_ms ve messages_sent ile)
- `chatMessageSend` (mesaj gönderme callback'inde)
- `chatImageSend` (resim gönderme)
- `chatImageView` (resim görüntüleme)
- `chatFirstMessage` (ilk mesaj gönderiminde, time_since_match_ms ile)
- `chatTypingStart`, `chatTypingDuration` (typing indicator)
- `chatKeyboardOpen`, `chatKeyboardClose` (FocusNode listener ile)
- `chatScrollToTop` (scroll controller ile)
- `chatRetrySend` (retry callback'inde)
- `chatLinkTap` (link tıklama)

Session tracking:
```dart
final Stopwatch _chatStopwatch = Stopwatch()..start();
int _messagesSentCount = 0;
```

**Step 2: Commit**

```bash
git add lib/features/chat/
git commit -m "feat: add chat and matches analytics events"
```

---

## Task 13: Feature-by-Feature Event Entegrasyonu — Diamonds & Subscription

**Files:**
- Modify: `lib/features/diamonds/screens/diamonds_screen.dart`
- Modify: `lib/features/diamonds/screens/subscription_comparison_screen.dart`
- Modify: `lib/core/services/revenuecat_service.dart`
- Modify: `lib/core/services/upsell_service.dart`

**Step 1: Diamonds screen'e event'ler ekle**
- `diamondsScreenView` (initState, `current_balance` parametresi)
- `diamondsPurchaseStart` (satın alma butonu tıklandığında)
- `diamondsPurchaseSuccess` / `diamondsPurchaseFail` / `diamondsPurchaseCancel`
- `diamondsBalanceView`

**Step 2: Subscription comparison screen'e event'ler ekle**
- `subscriptionScreenView`, `subscriptionCompareView`
- `subscriptionPurchaseStart` / `subscriptionPurchaseSuccess` / `subscriptionPurchaseFail`

**Step 3: RevenueCat service'e event'ler ekle**

`purchasePackage` ve `purchaseByProductId` method'larına:
```dart
static Future<CustomerInfo> purchasePackage(Package package) async {
  _ensureConfigured();
  AnalyticsManager.instance.logEvent(AnalyticsEvents.diamondsPurchaseStart, params: {
    AnalyticsEvents.paramProductId: package.storeProduct.identifier,
  });
  try {
    final result = await Purchases.purchasePackage(package);
    AnalyticsManager.instance.logEvent(AnalyticsEvents.diamondsPurchaseSuccess, params: {
      AnalyticsEvents.paramProductId: package.storeProduct.identifier,
    });
    return result;
  } catch (e) {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.diamondsPurchaseFail, params: {
      AnalyticsEvents.paramProductId: package.storeProduct.identifier,
      AnalyticsEvents.paramErrorCode: e.toString(),
    });
    rethrow;
  }
}
```

**Step 4: Upsell service'e event'ler ekle**

Her `shouldShow*` true döndüğünde ve `mark*Shown` çağrıldığında:
```dart
AnalyticsManager.instance.logEvent(AnalyticsEvents.upsellShown, params: {
  AnalyticsEvents.paramTrigger: 'onboarding', // or diamond_empty, first_match, etc.
  AnalyticsEvents.paramUpsellType: 'subscription',
});
```

**Step 5: Commit**

```bash
git add lib/features/diamonds/ lib/core/services/revenuecat_service.dart lib/core/services/upsell_service.dart
git commit -m "feat: add diamonds, subscription, and upsell analytics events"
```

---

## Task 14: Feature-by-Feature Event Entegrasyonu — Profile & Settings

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`
- Modify: `lib/features/profile/screens/edit_profile_screen.dart`
- Modify: `lib/features/settings/screens/settings_screen.dart`

**Step 1: Profile screen event'leri**
- `profileViewOwn` (initState)
- `profileSettingsOpen` (settings butonuna tıklandığında)
- `profileTabSwitch` (tab değişiminde)
- `profileScreenDuration` (dispose'da)

**Step 2: Edit profile screen event'leri**
- `profileEditStart` (field düzenleme başladığında)
- `profileEditSave` / `profileEditCancel`
- `profilePhotoAdd` / `profilePhotoRemove` / `profilePhotoReorder`
- `profileBioEdit` (bio kaydedildiğinde, char_count ile)
- `profileCompletionChange` (profil tamamlanma % değiştiğinde)

**Step 3: Settings screen event'leri**
- `settingsScreenView` (initState)
- `settingsChange` (her ayar değişikliğinde)
- `settingsNotificationToggle`, `settingsDistanceChange`, `settingsAgeRangeChange`
- `settingsLanguageChange`
- `settingsDeleteAccountStart`, `settingsDeleteAccountConfirm`

**Step 4: Commit**

```bash
git add lib/features/profile/ lib/features/settings/
git commit -m "feat: add profile and settings analytics events"
```

---

## Task 15: Feature-by-Feature Event Entegrasyonu — Quiz & Questions

**Files:**
- Modify: `lib/features/quiz/screens/quiz_screen.dart`
- Modify: `lib/features/questions/screens/question_create_screen.dart`
- Modify: `lib/features/questions/screens/question_analytics_screen.dart`
- Modify: `lib/features/profile/screens/questions_screen.dart`

**Step 1: Quiz screen event'leri**
- `quizStart` (quiz başladığında)
- `quizAnswer` (her cevap, question_index ve duration_ms)
- `quizComplete` (quiz bittiğinde, score ve total_duration_ms)
- `quizAbandon` (quiz terk edildiğinde)

**Step 2: Question screens event'leri**
- `questionCreateStart` (oluşturma ekranı açıldığında)
- `questionCreateComplete` (soru oluşturulduğunda)
- `questionCreateAbandon` (geri çıkıldığında)
- `questionDelete`, `questionEdit`
- `questionAnalyticsView` (analytics ekranı görüntülendiğinde)
- `questionSlotLimitHit` (slot limiti dolduğunda)
- `questionListView` (soru listesi görüntülendiğinde)

**Step 3: Commit**

```bash
git add lib/features/quiz/ lib/features/questions/ lib/features/profile/screens/questions_screen.dart
git commit -m "feat: add quiz and questions analytics events"
```

---

## Task 16: Feature-by-Feature Event Entegrasyonu — Onboarding & Passport

**Files:**
- Modify: `lib/features/onboarding/screens/onboarding_screen.dart`
- Modify: `lib/features/passport/screens/passport_screen.dart`
- Modify: `lib/features/passport/screens/map_picker_screen.dart`

**Step 1: Onboarding screen event'leri**
- `onboardingStart` (initState)
- `onboardingStepView` (her step görüntülendiğinde)
- `onboardingStepComplete` / `onboardingStepSkip` (step geçişlerinde, duration_ms ile)
- `onboardingPhotoAdd` / `onboardingPhotoRemove`
- `onboardingGenderSelect`, `onboardingBirthdateSet`, `onboardingLocationPermit`
- `onboardingComplete` (tamamlandığında, total_duration_ms ve photos_count ile)

**Step 2: Passport screen event'leri**
- `passportScreenView` (initState, is_active)
- `passportActivate` / `passportDeactivate`
- `passportCitySelect` (city_name)
- `passportMapInteract` (map etkileşimleri)

**Step 3: Commit**

```bash
git add lib/features/onboarding/ lib/features/passport/
git commit -m "feat: add onboarding and passport analytics events"
```

---

## Task 17: Feature-by-Feature Event Entegrasyonu — Notifications Screen

**Files:**
- Modify: `lib/features/notifications/screens/notifications_screen.dart`

**Step 1: Notifications inbox event'leri**
- `notificationInboxView` (initState, unread_count)

**Step 2: Commit**

```bash
git add lib/features/notifications/
git commit -m "feat: add notification inbox analytics events"
```

---

## Task 18: User Properties Güncelleme Entegrasyonu

**Files:**
- Modify: `lib/providers/auth_provider.dart` (login/checkAuth sonrası tüm properties set)
- Modify: İlgili provider'lar (diamond, subscription, match, vb.)

**Step 1: Auth provider'da login sonrası user properties set**

`checkAuth()` ve `login()` success bloklarında, user data fetch edildikten sonra:
```dart
// User properties güncelle
final user = ref.read(userProvider).user;
if (user != null) {
  AnalyticsManager.instance.updateUserProperties(
    subscriptionTier: 'free', // subscription provider'dan al
    gender: user.gender,
    ageRange: AnalyticsManager.ageRange(user.age),
    city: user.city ?? '',
    onboardingCompleted: 'true',
    photoCount: user.photos.length.toString(),
  );
}
```

**Step 2: Diamond provider'da bakiye değiştiğinde**

```dart
AnalyticsManager.instance.setUserProperty(
  'diamond_balance',
  AnalyticsManager.diamondRange(newBalance),
);
```

**Step 3: Subscription provider'da tier değiştiğinde**

```dart
AnalyticsManager.instance.setUserProperty(
  'subscription_tier',
  newTier,
);
```

**Step 4: Commit**

```bash
git add lib/providers/
git commit -m "feat: add user properties update on auth, diamond, and subscription changes"
```

---

## Task 19: flutter analyze & Doğrulama

**Step 1: Flutter analyze çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze
```

Expected: No errors (warnings OK)

**Step 2: Varsa hataları düzelt ve commit**

```bash
git add -A
git commit -m "fix: resolve flutter analyze issues in analytics integration"
```

---

## Task 20: Final Debug Test & Commit

**Step 1: Debug modda çalıştır ve konsol çıktısını kontrol et**

```bash
flutter run
```

Beklenen konsol çıktısı:
```
[Analytics] app_open
[Analytics] Screen: splash
[Analytics] app_splash_duration | {duration_ms: 2500}
[Analytics] auth_login_success | {method: auto}
[Analytics] Screen: discover
```

**Step 2: Tüm değişikliklerin temiz olduğunu doğrula**

```bash
git status
flutter analyze
```

**Step 3: Final commit (gerekirse)**

```bash
git add -A
git commit -m "chore: analytics integration complete — 148 events, 15 user properties, breadcrumb system"
```
