# Firebase Analytics & Crashlytics - Kapsamlı Tracking Tasarımı

## Amaç
Kullanıcıların uygulama içindeki tüm davranışlarını Firebase Analytics ile takip etmek, Crashlytics'i breadcrumb ve genişletilmiş non-fatal error tracking ile güçlendirmek.

## Mimari: Singleton AnalyticsManager

### Yeni Dosyalar
- `lib/core/services/analytics_manager.dart` — Singleton manager
- `lib/core/navigation/observers/analytics_observer.dart` — Route tracking observer
- `lib/core/services/analytics_events.dart` — Event name sabitleri
- `lib/core/services/analytics_breadcrumb.dart` — Breadcrumb model & queue

### Temel API

```dart
class AnalyticsManager {
  static final AnalyticsManager instance = AnalyticsManager._();

  Future<void> init();
  void logEvent(String name, {Map<String, Object>? params});
  void logScreenView(String screenName, {String? screenClass});
  void setUserProperties({...});
  void setUserId(String? userId);
  void logNonFatalError(Object error, StackTrace? stack, {String? context, Map<String, String>? extras});
  void logAppOpen();
  void logAppBackground();
  void logAppForeground();
}
```

Her `logEvent()` çağrısı otomatik olarak:
1. Firebase Analytics'e event gönderir
2. Crashlytics'e breadcrumb yazar
3. Son 30 event'i bellekte tutar (crash bağlamı için)

### Provider Erişimi
`analyticsManagerProvider` → `api_provider.dart`'a eklenir.
Feature'lardan: `ref.read(analyticsManagerProvider).logEvent(...)`

---

## Event Kataloğu (~148 event)

### Auth Events (8)
| Event | Parametreler |
|-------|-------------|
| auth_login_start | method |
| auth_login_success | method, duration_ms |
| auth_login_fail | method, error_code |
| auth_register_start | method |
| auth_register_success | method, duration_ms |
| auth_register_fail | method, error_code, step |
| auth_logout | — |
| auth_forgot_password | — |

### Onboarding Events (10)
| Event | Parametreler |
|-------|-------------|
| onboarding_start | — |
| onboarding_step_view | step_name, step_index |
| onboarding_step_complete | step_name, step_index, duration_ms |
| onboarding_step_skip | step_name, step_index |
| onboarding_photo_add | photo_index, source |
| onboarding_photo_remove | photo_index |
| onboarding_gender_select | gender |
| onboarding_birthdate_set | age |
| onboarding_location_permit | granted |
| onboarding_complete | total_duration_ms, photos_count |

### Discover/Swipe Events (15)
| Event | Parametreler |
|-------|-------------|
| discover_screen_view | remaining_swipes |
| discover_swipe_right | target_user_id, swipe_duration_ms, card_index |
| discover_swipe_left | target_user_id, swipe_duration_ms, card_index |
| discover_swipe_velocity | direction, velocity, duration_ms |
| discover_profile_expand | target_user_id |
| discover_photo_view | target_user_id, photo_index |
| discover_photo_zoom | target_user_id, photo_index |
| discover_scroll_depth | target_user_id, depth_percent |
| discover_undo | target_user_id |
| discover_limit_reached | total_swipes_today |
| discover_cards_empty | swipes_count_session |
| discover_filter_open | — |
| discover_filter_apply | age_min, age_max, distance, gender |
| discover_session_start | — |
| discover_session_end | duration_ms, swipes_right, swipes_left, profiles_viewed |

### Match Events (6)
| Event | Parametreler |
|-------|-------------|
| match_new | match_user_id, is_instant |
| match_screen_view | matches_count |
| match_open_chat | match_user_id, time_since_match_ms |
| match_unmatch | match_user_id, reason |
| match_list_scroll | scroll_depth_percent |
| match_tap_profile | match_user_id |

### Chat/Message Events (14)
| Event | Parametreler |
|-------|-------------|
| chat_open | chat_id, match_user_id |
| chat_close | chat_id, duration_ms, messages_sent |
| chat_message_send | chat_id, type, char_count |
| chat_message_receive | chat_id, type |
| chat_image_send | chat_id, source |
| chat_image_view | chat_id, message_id |
| chat_keyboard_open | chat_id |
| chat_keyboard_close | chat_id, duration_ms |
| chat_scroll_to_top | chat_id |
| chat_typing_start | chat_id |
| chat_typing_duration | chat_id, duration_ms |
| chat_retry_send | chat_id, retry_count |
| chat_link_tap | chat_id, url_domain |
| chat_first_message | chat_id, time_since_match_ms |

### Quiz/Questions Events (12)
| Event | Parametreler |
|-------|-------------|
| quiz_start | quiz_id, partner_id |
| quiz_answer | quiz_id, question_index, duration_ms |
| quiz_complete | quiz_id, score, total_duration_ms |
| quiz_abandon | quiz_id, question_index, duration_ms |
| question_create_start | — |
| question_create_complete | question_type, duration_ms |
| question_create_abandon | step |
| question_delete | question_id |
| question_edit | question_id |
| question_analytics_view | question_id |
| question_slot_limit_hit | current_slots |
| question_list_view | questions_count |

### Profile Events (14)
| Event | Parametreler |
|-------|-------------|
| profile_view_own | — |
| profile_edit_start | field_name |
| profile_edit_save | field_name, duration_ms |
| profile_edit_cancel | field_name |
| profile_photo_add | photo_index, source |
| profile_photo_remove | photo_index |
| profile_photo_reorder | from_index, to_index |
| profile_completion_change | old_percent, new_percent |
| profile_preview | — |
| profile_settings_open | — |
| profile_share | — |
| profile_bio_edit | char_count |
| profile_screen_duration | duration_ms |
| profile_tab_switch | tab_name |

### Diamond & Monetization Events (18)
| Event | Parametreler |
|-------|-------------|
| diamonds_screen_view | current_balance |
| diamonds_purchase_start | product_id, tier, price |
| diamonds_purchase_success | product_id, tier, price, diamonds_amount |
| diamonds_purchase_fail | product_id, error_code |
| diamonds_purchase_cancel | product_id, tier |
| diamonds_spend | amount, spend_type, remaining_balance |
| diamonds_balance_view | balance |
| subscription_screen_view | current_tier |
| subscription_compare_view | — |
| subscription_purchase_start | tier, price |
| subscription_purchase_success | tier, price |
| subscription_purchase_fail | tier, error_code |
| subscription_cancel | tier, days_subscribed |
| subscription_renew | tier |
| upsell_shown | trigger, upsell_type |
| upsell_tap_cta | trigger, upsell_type |
| upsell_dismiss | trigger, upsell_type, duration_ms |
| upsell_convert | trigger, upsell_type, product_id |

### Passport Events (6)
| Event | Parametreler |
|-------|-------------|
| passport_activate | destination_city |
| passport_deactivate | destination_city, duration_used_ms |
| passport_expire | destination_city |
| passport_city_select | city_name |
| passport_screen_view | is_active |
| passport_map_interact | action |

### Notification Events (10)
| Event | Parametreler |
|-------|-------------|
| notification_permission_ask | — |
| notification_permission_grant | — |
| notification_permission_deny | — |
| notification_receive_foreground | type |
| notification_receive_background | type |
| notification_tap | type, action_url |
| notification_banner_show | type |
| notification_banner_tap | type |
| notification_banner_dismiss | type |
| notification_inbox_view | unread_count |

### App Lifecycle & System Events (15)
| Event | Parametreler |
|-------|-------------|
| app_open | — |
| app_foreground | background_duration_ms |
| app_background | session_duration_ms |
| app_force_update_shown | current_version, required_version |
| app_optional_update_shown | current_version, latest_version |
| app_maintenance_shown | — |
| app_error_screen | error_type, screen |
| app_network_change | status |
| app_network_timeout | endpoint, duration_ms |
| app_api_error | endpoint, status_code, duration_ms |
| app_api_success | endpoint, duration_ms |
| app_deep_link_open | url, source |
| app_splash_duration | duration_ms |
| app_retry_action | action_type, retry_count |
| app_permission_request | permission_type, granted |

### UI Micro-Interaction Events (12)
| Event | Parametreler |
|-------|-------------|
| ui_tab_switch | from_tab, to_tab |
| ui_dialog_show | dialog_type |
| ui_dialog_action | dialog_type, action |
| ui_bottom_sheet_show | sheet_type |
| ui_bottom_sheet_dismiss | sheet_type, duration_ms |
| ui_pull_to_refresh | screen |
| ui_scroll_to_end | screen, list_type |
| ui_input_focus | screen, field_name |
| ui_input_blur | screen, field_name, has_value |
| ui_button_tap | screen, button_id |
| ui_image_load_fail | screen, url |
| ui_animation_complete | screen, animation_type |

### Settings Events (8)
| Event | Parametreler |
|-------|-------------|
| settings_screen_view | — |
| settings_change | setting_name, old_value, new_value |
| settings_notification_toggle | enabled |
| settings_distance_change | old_km, new_km |
| settings_age_range_change | min, max |
| settings_language_change | language |
| settings_delete_account_start | — |
| settings_delete_account_confirm | days_since_register |

---

## Crashlytics Genişletme

### Breadcrumb Sistemi
- Her logEvent() Crashlytics'e `_crashlytics.log()` ile breadcrumb yazar
- Son 30 event bellekte tutulur (Queue)
- Crash anında `breadcrumb_trail` custom key'e son 5 event özeti yazılır

### Non-Fatal Error Kategorileri
| Kategori | Yakalanacak Durumlar | Custom Key'ler |
|----------|---------------------|----------------|
| API Hataları | 4xx, 5xx response | endpoint, status_code, response_time_ms |
| Network | Timeout, no connection | endpoint, timeout_duration, network_type |
| Parse Hataları | JSON decode fail | endpoint, raw_response_preview |
| Auth | Token expired, refresh fail | token_age_ms, retry_count |
| IAP | Purchase/verify fail | product_id, error_code, store |
| Image | Upload/load fail | image_url, file_size |
| Location | Permission denied | last_known_location |
| WebSocket | Connection drop | chat_id, connection_duration |

### Crash Context Custom Keys
| Key | Değer |
|-----|-------|
| last_screen | Son görüntülenen ekran |
| last_action | Son kullanıcı aksiyonu |
| session_duration_ms | Oturum süresi |
| subscription_tier | free/plus/premium |
| network_status | online/offline |
| diamond_balance | Mevcut bakiye |
| app_state | foreground/background |
| breadcrumb_trail | Son 5 event özeti |

---

## User Properties (15)

| Property | Açıklama | Range |
|----------|----------|-------|
| subscription_tier | Abonelik | free/plus/premium |
| diamond_balance | Elmas bakiyesi | 0, 1-100, 100-500, 500+ |
| gender | Cinsiyet | — |
| age_range | Yaş | 18-24, 25-30, 31-40, 40+ |
| city | Şehir | — |
| profile_completion | Profil % | 0-25, 25-50, 50-75, 75-100 |
| total_matches | Match sayısı | 0, 1-5, 6-20, 20+ |
| total_messages_sent | Mesaj sayısı | 0, 1-10, 11-50, 50+ |
| questions_count | Soru sayısı | — |
| days_since_register | Kayıt günü | 1, 2-7, 8-30, 30+ |
| has_passport | Pasaport aktif | true/false |
| notification_enabled | Bildirim izni | true/false |
| app_version | Uygulama versiyonu | — |
| onboarding_completed | Onboarding tamam | true/false |
| photo_count | Fotoğraf sayısı | — |

Güncelleme zamanları: login/register sonrası (tümü), profil düzenleme, satın alma, match/mesaj, app_foreground.

---

## Funnel Tanımları

1. **Kayıt**: auth_register_start → onboarding steps → onboarding_complete → discover_screen_view
2. **İlk Match**: discover_session_start → discover_swipe_right → match_new → match_open_chat → chat_first_message
3. **Monetizasyon**: upsell_shown → upsell_tap_cta → purchase_start → purchase_success
4. **Elmas Satın Alma**: diamonds_screen_view → diamonds_purchase_start → diamonds_purchase_success
5. **Subscription Dönüşüm**: subscription_screen_view → subscription_compare_view → subscription_purchase_start → subscription_purchase_success
6. **Chat Engagement**: match_new → match_open_chat → chat_first_message → chat_message_send(5+) → chat_image_send
7. **Soru Oluşturma**: question_create_start → question_create_complete → question_analytics_view

---

## Değişecek Dosyalar

### Yeni (4)
- `lib/core/services/analytics_manager.dart`
- `lib/core/services/analytics_events.dart`
- `lib/core/services/analytics_breadcrumb.dart`
- `lib/core/navigation/observers/analytics_observer.dart`

### Mevcut (~20)
- `lib/main.dart` — init
- `lib/app.dart` — lifecycle
- `lib/providers/api_provider.dart` — provider
- `lib/core/error/error_manager.dart` — breadcrumb entegrasyonu
- `lib/routing/app_router.dart` — observer ekleme
- `lib/providers/auth_provider.dart` — auth events + user properties
- `lib/features/discover/` — swipe events
- `lib/features/chat/` — message events
- `lib/features/diamonds/` — purchase events
- `lib/features/profile/` — profile events
- `lib/features/quiz/` — quiz events
- `lib/features/questions/` — question events
- `lib/features/onboarding/` — onboarding events
- `lib/features/passport/` — passport events
- `lib/features/notifications/` — notification events
- `lib/features/settings/` — settings events
- `lib/core/services/notification_manager.dart` — FCM events
- `lib/core/services/revenuecat_service.dart` — IAP events
- `lib/core/services/upsell_service.dart` — upsell events
- `lib/core/widgets/in_app_banner.dart` — banner events
- `lib/features/splash/` — splash duration
