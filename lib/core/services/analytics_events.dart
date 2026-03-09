/// All Firebase Analytics event name constants and parameter key constants.
///
/// Used by [AnalyticsManager] to prevent typos in event names and param keys.
/// Event values use snake_case, field names use camelCase.
/// Parameter fields are prefixed with `param`.
abstract class AnalyticsEvents {
  AnalyticsEvents._();

  // ─── Auth (8) ───────────────────────────────────────────────────────
  static const String authLoginStart = 'auth_login_start';
  static const String authLoginSuccess = 'auth_login_success';
  static const String authLoginFail = 'auth_login_fail';
  static const String authRegisterStart = 'auth_register_start';
  static const String authRegisterSuccess = 'auth_register_success';
  static const String authRegisterFail = 'auth_register_fail';
  static const String authLogout = 'auth_logout';
  static const String authForgotPassword = 'auth_forgot_password';

  // ─── Onboarding (10) ───────────────────────────────────────────────
  static const String onboardingStart = 'onboarding_start';
  static const String onboardingStepView = 'onboarding_step_view';
  static const String onboardingStepComplete = 'onboarding_step_complete';
  static const String onboardingStepSkip = 'onboarding_step_skip';
  static const String onboardingPhotoAdd = 'onboarding_photo_add';
  static const String onboardingPhotoRemove = 'onboarding_photo_remove';
  static const String onboardingGenderSelect = 'onboarding_gender_select';
  static const String onboardingBirthdateSet = 'onboarding_birthdate_set';
  static const String onboardingLocationPermit = 'onboarding_location_permit';
  static const String onboardingComplete = 'onboarding_complete';

  // ─── Discover (15) ─────────────────────────────────────────────────
  static const String discoverScreenView = 'discover_screen_view';
  static const String discoverSwipeRight = 'discover_swipe_right';
  static const String discoverSwipeLeft = 'discover_swipe_left';
  static const String discoverSwipeVelocity = 'discover_swipe_velocity';
  static const String discoverProfileExpand = 'discover_profile_expand';
  static const String discoverPhotoView = 'discover_photo_view';
  static const String discoverPhotoZoom = 'discover_photo_zoom';
  static const String discoverScrollDepth = 'discover_scroll_depth';
  static const String discoverUndo = 'discover_undo';
  static const String discoverLimitReached = 'discover_limit_reached';
  static const String discoverCardsEmpty = 'discover_cards_empty';
  static const String discoverFilterOpen = 'discover_filter_open';
  static const String discoverFilterApply = 'discover_filter_apply';
  static const String discoverSessionStart = 'discover_session_start';
  static const String discoverSessionEnd = 'discover_session_end';

  // ─── Match (6) ─────────────────────────────────────────────────────
  static const String matchNew = 'match_new';
  static const String matchScreenView = 'match_screen_view';
  static const String matchOpenChat = 'match_open_chat';
  static const String matchUnmatch = 'match_unmatch';
  static const String matchListScroll = 'match_list_scroll';
  static const String matchTapProfile = 'match_tap_profile';

  // ─── Chat (14) ─────────────────────────────────────────────────────
  static const String chatOpen = 'chat_open';
  static const String chatClose = 'chat_close';
  static const String chatMessageSend = 'chat_message_send';
  static const String chatMessageReceive = 'chat_message_receive';
  static const String chatImageSend = 'chat_image_send';
  static const String chatImageView = 'chat_image_view';
  static const String chatKeyboardOpen = 'chat_keyboard_open';
  static const String chatKeyboardClose = 'chat_keyboard_close';
  static const String chatScrollToTop = 'chat_scroll_to_top';
  static const String chatTypingStart = 'chat_typing_start';
  static const String chatTypingDuration = 'chat_typing_duration';
  static const String chatRetrySend = 'chat_retry_send';
  static const String chatLinkTap = 'chat_link_tap';
  static const String chatFirstMessage = 'chat_first_message';

  // ─── Quiz (4) ──────────────────────────────────────────────────────
  static const String quizStart = 'quiz_start';
  static const String quizAnswer = 'quiz_answer';
  static const String quizComplete = 'quiz_complete';
  static const String quizAbandon = 'quiz_abandon';

  // ─── Questions (8) ─────────────────────────────────────────────────
  static const String questionCreateStart = 'question_create_start';
  static const String questionCreateComplete = 'question_create_complete';
  static const String questionCreateAbandon = 'question_create_abandon';
  static const String questionDelete = 'question_delete';
  static const String questionEdit = 'question_edit';
  static const String questionAnalyticsView = 'question_analytics_view';
  static const String questionSlotLimitHit = 'question_slot_limit_hit';
  static const String questionListView = 'question_list_view';

  // ─── Profile (14) ──────────────────────────────────────────────────
  static const String profileViewOwn = 'profile_view_own';
  static const String profileEditStart = 'profile_edit_start';
  static const String profileEditSave = 'profile_edit_save';
  static const String profileEditCancel = 'profile_edit_cancel';
  static const String profilePhotoAdd = 'profile_photo_add';
  static const String profilePhotoRemove = 'profile_photo_remove';
  static const String profilePhotoReorder = 'profile_photo_reorder';
  static const String profileCompletionChange = 'profile_completion_change';
  static const String profilePreview = 'profile_preview';
  static const String profileSettingsOpen = 'profile_settings_open';
  static const String profileShare = 'profile_share';
  static const String profileBioEdit = 'profile_bio_edit';
  static const String profileScreenDuration = 'profile_screen_duration';
  static const String profileTabSwitch = 'profile_tab_switch';

  // ─── Diamonds & Monetization (18) ──────────────────────────────────
  static const String diamondsScreenView = 'diamonds_screen_view';
  static const String diamondsPurchaseStart = 'diamonds_purchase_start';
  static const String diamondsPurchaseSuccess = 'diamonds_purchase_success';
  static const String diamondsPurchaseFail = 'diamonds_purchase_fail';
  static const String diamondsPurchaseCancel = 'diamonds_purchase_cancel';
  static const String diamondsSpend = 'diamonds_spend';
  static const String diamondsBalanceView = 'diamonds_balance_view';
  static const String subscriptionScreenView = 'subscription_screen_view';
  static const String subscriptionCompareView = 'subscription_compare_view';
  static const String subscriptionPurchaseStart = 'subscription_purchase_start';
  static const String subscriptionPurchaseSuccess = 'subscription_purchase_success';
  static const String subscriptionPurchaseFail = 'subscription_purchase_fail';
  static const String subscriptionCancel = 'subscription_cancel';
  static const String subscriptionRenew = 'subscription_renew';
  static const String upsellShown = 'upsell_shown';
  static const String upsellTapCta = 'upsell_tap_cta';
  static const String upsellDismiss = 'upsell_dismiss';
  static const String upsellConvert = 'upsell_convert';

  // ─── Passport (6) ──────────────────────────────────────────────────
  static const String passportActivate = 'passport_activate';
  static const String passportDeactivate = 'passport_deactivate';
  static const String passportExpire = 'passport_expire';
  static const String passportCitySelect = 'passport_city_select';
  static const String passportScreenView = 'passport_screen_view';
  static const String passportMapInteract = 'passport_map_interact';

  // ─── Notifications (10) ────────────────────────────────────────────
  static const String notificationPermissionAsk = 'notification_permission_ask';
  static const String notificationPermissionGrant = 'notification_permission_grant';
  static const String notificationPermissionDeny = 'notification_permission_deny';
  static const String notificationReceiveForeground = 'notification_receive_foreground';
  static const String notificationReceiveBackground = 'notification_receive_background';
  static const String notificationTap = 'notification_tap';
  static const String notificationBannerShow = 'notification_banner_show';
  static const String notificationBannerTap = 'notification_banner_tap';
  static const String notificationBannerDismiss = 'notification_banner_dismiss';
  static const String notificationInboxView = 'notification_inbox_view';

  // ─── App Lifecycle (15) ────────────────────────────────────────────
  static const String appOpen = 'app_open';
  static const String appForeground = 'app_foreground';
  static const String appBackground = 'app_background';
  static const String appForceUpdateShown = 'app_force_update_shown';
  static const String appOptionalUpdateShown = 'app_optional_update_shown';
  static const String appMaintenanceShown = 'app_maintenance_shown';
  static const String appErrorScreen = 'app_error_screen';
  static const String appNetworkChange = 'app_network_change';
  static const String appNetworkTimeout = 'app_network_timeout';
  static const String appApiError = 'app_api_error';
  static const String appApiSuccess = 'app_api_success';
  static const String appDeepLinkOpen = 'app_deep_link_open';
  static const String appSplashDuration = 'app_splash_duration';
  static const String appRetryAction = 'app_retry_action';
  static const String appPermissionRequest = 'app_permission_request';

  // ─── UI Micro-Interactions (12) ────────────────────────────────────
  static const String uiTabSwitch = 'ui_tab_switch';
  static const String uiDialogShow = 'ui_dialog_show';
  static const String uiDialogAction = 'ui_dialog_action';
  static const String uiBottomSheetShow = 'ui_bottom_sheet_show';
  static const String uiBottomSheetDismiss = 'ui_bottom_sheet_dismiss';
  static const String uiPullToRefresh = 'ui_pull_to_refresh';
  static const String uiScrollToEnd = 'ui_scroll_to_end';
  static const String uiInputFocus = 'ui_input_focus';
  static const String uiInputBlur = 'ui_input_blur';
  static const String uiButtonTap = 'ui_button_tap';
  static const String uiImageLoadFail = 'ui_image_load_fail';
  static const String uiAnimationComplete = 'ui_animation_complete';

  // ─── Settings (8) ──────────────────────────────────────────────────
  static const String settingsScreenView = 'settings_screen_view';
  static const String settingsChange = 'settings_change';
  static const String settingsNotificationToggle = 'settings_notification_toggle';
  static const String settingsDistanceChange = 'settings_distance_change';
  static const String settingsAgeRangeChange = 'settings_age_range_change';
  static const String settingsLanguageChange = 'settings_language_change';
  static const String settingsDeleteAccountStart = 'settings_delete_account_start';
  static const String settingsDeleteAccountConfirm = 'settings_delete_account_confirm';

  // ═══════════════════════════════════════════════════════════════════
  // Parameter Keys
  // ═══════════════════════════════════════════════════════════════════

  static const String paramMethod = 'method';
  static const String paramDurationMs = 'duration_ms';
  static const String paramErrorCode = 'error_code';
  static const String paramStep = 'step';
  static const String paramStepName = 'step_name';
  static const String paramStepIndex = 'step_index';
  static const String paramPhotoIndex = 'photo_index';
  static const String paramSource = 'source';
  static const String paramGender = 'gender';
  static const String paramAge = 'age';
  static const String paramGranted = 'granted';
  static const String paramPhotosCount = 'photos_count';
  static const String paramTargetUserId = 'target_user_id';
  static const String paramSwipeDurationMs = 'swipe_duration_ms';
  static const String paramCardIndex = 'card_index';
  static const String paramDirection = 'direction';
  static const String paramVelocity = 'velocity';
  static const String paramDepthPercent = 'depth_percent';
  static const String paramTotalSwipesToday = 'total_swipes_today';
  static const String paramSwipesCountSession = 'swipes_count_session';
  static const String paramAgeMin = 'age_min';
  static const String paramAgeMax = 'age_max';
  static const String paramDistance = 'distance';
  static const String paramSwipesRight = 'swipes_right';
  static const String paramSwipesLeft = 'swipes_left';
  static const String paramProfilesViewed = 'profiles_viewed';
  static const String paramRemainingSwipes = 'remaining_swipes';
  static const String paramMatchUserId = 'match_user_id';
  static const String paramIsInstant = 'is_instant';
  static const String paramMatchesCount = 'matches_count';
  static const String paramTimeSinceMatchMs = 'time_since_match_ms';
  static const String paramReason = 'reason';
  static const String paramScrollDepthPercent = 'scroll_depth_percent';
  static const String paramChatId = 'chat_id';
  static const String paramType = 'type';
  static const String paramCharCount = 'char_count';
  static const String paramMessageId = 'message_id';
  static const String paramMessagesSent = 'messages_sent';
  static const String paramRetryCount = 'retry_count';
  static const String paramUrlDomain = 'url_domain';
  static const String paramQuizId = 'quiz_id';
  static const String paramPartnerId = 'partner_id';
  static const String paramQuestionIndex = 'question_index';
  static const String paramScore = 'score';
  static const String paramTotalDurationMs = 'total_duration_ms';
  static const String paramQuestionType = 'question_type';
  static const String paramQuestionId = 'question_id';
  static const String paramCurrentSlots = 'current_slots';
  static const String paramQuestionsCount = 'questions_count';
  static const String paramFieldName = 'field_name';
  static const String paramFromIndex = 'from_index';
  static const String paramToIndex = 'to_index';
  static const String paramOldPercent = 'old_percent';
  static const String paramNewPercent = 'new_percent';
  static const String paramTabName = 'tab_name';
  static const String paramProductId = 'product_id';
  static const String paramTier = 'tier';
  static const String paramPrice = 'price';
  static const String paramDiamondsAmount = 'diamonds_amount';
  static const String paramSpendType = 'spend_type';
  static const String paramRemainingBalance = 'remaining_balance';
  static const String paramBalance = 'balance';
  static const String paramCurrentTier = 'current_tier';
  static const String paramDaysSubscribed = 'days_subscribed';
  static const String paramTrigger = 'trigger';
  static const String paramUpsellType = 'upsell_type';
  static const String paramDestinationCity = 'destination_city';
  static const String paramDurationUsedMs = 'duration_used_ms';
  static const String paramCityName = 'city_name';
  static const String paramIsActive = 'is_active';
  static const String paramAction = 'action';
  static const String paramActionUrl = 'action_url';
  static const String paramUnreadCount = 'unread_count';
  static const String paramBackgroundDurationMs = 'background_duration_ms';
  static const String paramSessionDurationMs = 'session_duration_ms';
  static const String paramCurrentVersion = 'current_version';
  static const String paramRequiredVersion = 'required_version';
  static const String paramLatestVersion = 'latest_version';
  static const String paramErrorType = 'error_type';
  static const String paramScreen = 'screen';
  static const String paramStatus = 'status';
  static const String paramEndpoint = 'endpoint';
  static const String paramStatusCode = 'status_code';
  static const String paramUrl = 'url';
  static const String paramActionType = 'action_type';
  static const String paramPermissionType = 'permission_type';
  static const String paramFromTab = 'from_tab';
  static const String paramToTab = 'to_tab';
  static const String paramDialogType = 'dialog_type';
  static const String paramSheetType = 'sheet_type';
  static const String paramListType = 'list_type';
  static const String paramHasValue = 'has_value';
  static const String paramButtonId = 'button_id';
  static const String paramAnimationType = 'animation_type';
  static const String paramSettingName = 'setting_name';
  static const String paramOldValue = 'old_value';
  static const String paramNewValue = 'new_value';
  static const String paramEnabled = 'enabled';
  static const String paramOldKm = 'old_km';
  static const String paramNewKm = 'new_km';
  static const String paramMin = 'min';
  static const String paramMax = 'max';
  static const String paramLanguage = 'language';
  static const String paramDaysSinceRegister = 'days_since_register';
  static const String paramCurrentBalance = 'current_balance';
}
