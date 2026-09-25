import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/url_launcher_manager.dart';

/// Değerlendirme isteminin tetiklendiği anlar (analytics `trigger` parametresi).
///
/// İstem yalnızca kullanıcının değer gördüğü anlarda sorulur; quiz'i
/// bitiremeyip geri dönen kullanıcıya sorulmaz (2026-09-25'e kadar soruluyordu —
/// 13 iOS puanının hepsi 2022'dendi).
abstract final class AppReviewTrigger {
  /// 2. ve sonraki eşleşme kutlamasından çıkış (ilk eşleşmede paywall var).
  static const String matchCelebration = 'match_celebration';

  /// Kullanıcı toplam [AppReviewManager.chatEngagedThreshold] metin mesajı gönderdi.
  static const String chatEngaged = 'chat_engaged';

  /// İlk eşleşmeden en az [AppReviewManager.returnDelay] sonra Keşfet'te ilk kaydırma.
  static const String returnAfterFirstMatch = 'return_after_first_match';

  /// Ayarlar'daki "Bizi değerlendir" — doğrudan mağaza sayfası.
  static const String settings = 'settings';
}

/// Mağaza değerlendirme istemi istemcisi; testte sahteyle değiştirilir.
abstract interface class ReviewPromptClient {
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing({String? appStoreId});
}

class _InAppReviewClient implements ReviewPromptClient {
  const _InAppReviewClient();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();

  @override
  Future<void> openStoreListing({String? appStoreId}) =>
      InAppReview.instance.openStoreListing(appStoreId: appStoreId);
}

/// Mağaza puan istemi politikası: ömür boyu en çok 3 istek, 14 gün soğuma,
/// platform uygunluğu; artı tetikleyici defteri (mesaj sayacı, bekleyen dönüş).
///
/// Not: iki platformda da API diyaloğun gerçekten çıktığını söylemez (Android
/// kotası sessizce yutar); "gösterildi" = sistem isteği yapıldı.
class AppReviewManager {
  AppReviewManager._(this._client);

  /// Test kancası: sahte istemciyle bağımsız örnek kurar (OverlayQueueService
  /// deseni); üretim yolu her zaman [instance] üzerinden gider.
  @visibleForTesting
  AppReviewManager.withClient(ReviewPromptClient client) : this._(client);

  static final AppReviewManager instance =
      AppReviewManager._(const _InAppReviewClient());

  static const _keyShownCount = 'qulo_app_review_shown_count';
  static const _keyLastShown = 'qulo_app_review_last_shown';
  static const _keyCompleted = 'qulo_app_review_completed';
  static const _keySentMessages = 'qulo_app_review_sent_messages';
  static const _keyChatEngagedDone = 'qulo_app_review_chat_engaged_done';
  static const _keyPendingSince = 'qulo_app_review_pending_since';

  static const _maxShownCount = 3;
  static const _cooldownDays = 14;

  /// Bu kadar metin mesajı gönderen kullanıcı sohbete bağlanmış sayılır.
  static const int chatEngagedThreshold = 5;

  /// İlk eşleşme paywall'ı ile değerlendirme istemi aynı turda açılmasın;
  /// istem en erken bu kadar sonra, Keşfet'teki ilk kaydırmada sorulur.
  static const Duration returnDelay = Duration(hours: 6);

  static const _iosAppStoreId = '1626734572';
  static const _androidPackageName =
      'com.wordpress.calikusuberkant.qulo';

  final ReviewPromptClient _client;

  /// Soğuma, üst sınır ve platform uygunluğunu kontrol edip sistem isteğini
  /// yapar. İstek yapıldıysa `true` döner.
  Future<bool> tryShowReview({required String trigger}) async {
    try {
      if (!await _shouldShowReview()) return false;
      await _requestReview(trigger);
      return true;
    } catch (e, stack) {
      AnalyticsManager.instance.logNonFatalError(
        e,
        stack,
        context: 'AppReviewManager.tryShowReview',
      );
      return false;
    }
  }

  /// Başarıyla gönderilen her metin mesajında çağrılır. Sayaç
  /// [chatEngagedThreshold]'a ulaşınca istem denenir; soğuma/uygunluk o an
  /// engellerse sonraki mesajlarda yeniden denenir, gösterilince bir daha
  /// denenmez (dönüş tetikleyicisiyle simetrik).
  Future<void> onMessageSent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_keySentMessages) ?? 0) + 1;
      await prefs.setInt(_keySentMessages, count);
      if (count < chatEngagedThreshold) return;
      if (prefs.getBool(_keyChatEngagedDone) ?? false) return;
      final shown = await tryShowReview(trigger: AppReviewTrigger.chatEngaged);
      if (shown) await prefs.setBool(_keyChatEngagedDone, true);
    } catch (e, stack) {
      AnalyticsManager.instance.logNonFatalError(
        e,
        stack,
        context: 'AppReviewManager.onMessageSent',
      );
    }
  }

  /// İlk eşleşme anında çağrılır: istemi [returnDelay] sonrasına bırakır.
  /// Zaten bekleyen bir kayıt varsa üzerine yazmaz (süre sıfırlanmasın).
  Future<void> markPendingReturnReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_keyPendingSince)) return;
      await prefs.setString(
        _keyPendingSince,
        DateTime.now().toIso8601String(),
      );
    } catch (e, stack) {
      AnalyticsManager.instance.logNonFatalError(
        e,
        stack,
        context: 'AppReviewManager.markPendingReturnReview',
      );
    }
  }

  /// Bekleyen dönüş istemi var ve [returnDelay] dolduysa `true`.
  Future<bool> isReturnReviewDue() async {
    final prefs = await SharedPreferences.getInstance();
    final since = DateTime.tryParse(prefs.getString(_keyPendingSince) ?? '');
    if (since == null) return false;
    return DateTime.now().difference(since) >= returnDelay;
  }

  /// Süresi dolmuş dönüş istemini dener. Kayıt, istek yapılınca ya da istem
  /// kalıcı olarak kapandıysa (üst sınır) silinir; soğuma engellediyse kalır
  /// ve sonraki kaydırmada tekrar denenir.
  Future<void> tryShowPendingReturnReview() async {
    if (!await isReturnReviewDue()) return;
    final shown = await tryShowReview(
      trigger: AppReviewTrigger.returnAfterFirstMatch,
    );
    final prefs = await SharedPreferences.getInstance();
    if (shown || (prefs.getBool(_keyCompleted) ?? false)) {
      await prefs.remove(_keyPendingSince);
    }
  }

  /// Ayarlar'daki buton — kullanıcı açıkça istedi, doğrudan mağaza sayfası.
  Future<void> requestReviewFromSettings() async {
    try {
      await _client.openStoreListing(appStoreId: _iosAppStoreId);
      AnalyticsManager.instance
          .logAppReviewPrompted(AppReviewTrigger.settings, 0);
    } catch (e, stack) {
      // Fallback: Android Play Store URL
      if (Platform.isAndroid) {
        await UrlLauncherManager.instance.launch(
          'https://play.google.com/store/apps/details?id=$_androidPackageName',
        );
      }
      AnalyticsManager.instance.logNonFatalError(
        e,
        stack,
        context: 'AppReviewManager.requestReviewFromSettings',
      );
    }
  }

  Future<bool> _shouldShowReview() async {
    final prefs = await SharedPreferences.getInstance();

    final completed = prefs.getBool(_keyCompleted) ?? false;
    if (completed) return false;

    final shownCount = prefs.getInt(_keyShownCount) ?? 0;
    if (shownCount >= _maxShownCount) {
      await prefs.setBool(_keyCompleted, true);
      return false;
    }

    final lastShownStr = prefs.getString(_keyLastShown);
    if (lastShownStr != null) {
      final lastShown = DateTime.tryParse(lastShownStr);
      if (lastShown != null) {
        final daysSince = DateTime.now().difference(lastShown).inDays;
        if (daysSince < _cooldownDays) return false;
      }
    }

    final available = await _client.isAvailable();
    if (!available) return false;

    return true;
  }

  Future<void> _requestReview(String trigger) async {
    final prefs = await SharedPreferences.getInstance();
    final shownCount = (prefs.getInt(_keyShownCount) ?? 0) + 1;

    // İstek fırlatırsa sayaç ve soğuma yazılmaz — hak yanmaz.
    await _client.requestReview();

    await prefs.setInt(_keyShownCount, shownCount);
    await prefs.setString(_keyLastShown, DateTime.now().toIso8601String());

    if (shownCount >= _maxShownCount) {
      await prefs.setBool(_keyCompleted, true);
    }

    AnalyticsManager.instance.logAppReviewPrompted(trigger, shownCount);

    if (kDebugMode) {
      debugPrint('[AppReviewManager] Review prompted (trigger: $trigger, count: $shownCount)');
    }
  }
}
