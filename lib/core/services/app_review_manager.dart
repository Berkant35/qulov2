import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/url_launcher_manager.dart';

class AppReviewManager {
  AppReviewManager._();
  static final AppReviewManager instance = AppReviewManager._();

  static const _keyShownCount = 'qulo_app_review_shown_count';
  static const _keyLastShown = 'qulo_app_review_last_shown';
  static const _keyCompleted = 'qulo_app_review_completed';

  static const _maxShownCount = 3;
  static const _cooldownDays = 14;

  static const _iosAppStoreUrl =
      'https://apps.apple.com/app/id<APP_STORE_ID>';
  static const _androidPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.wordpress.calikusuberkant.qulo';

  final InAppReview _inAppReview = InAppReview.instance;

  /// Smart trigger — checks cooldown, count, and platform availability.
  Future<void> tryShowReview({required String trigger}) async {
    try {
      if (!await _shouldShowReview()) return;
      await _requestReview(trigger);
    } catch (e, stack) {
      AnalyticsManager.instance.logNonFatalError(
        e,
        stack,
        context: 'AppReviewManager.tryShowReview',
      );
    }
  }

  /// Settings tap — no cooldown check, with store URL fallback.
  Future<void> requestReviewFromSettings() async {
    try {
      final available = await _inAppReview.isAvailable();
      if (available) {
        await _inAppReview.requestReview();
        AnalyticsManager.instance.logAppReviewPrompted('settings', 0);
      } else {
        await _openStoreUrl();
      }
    } catch (e, stack) {
      await _openStoreUrl();
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

    final available = await _inAppReview.isAvailable();
    if (!available) return false;

    return true;
  }

  Future<void> _requestReview(String trigger) async {
    final prefs = await SharedPreferences.getInstance();
    final shownCount = (prefs.getInt(_keyShownCount) ?? 0) + 1;

    await _inAppReview.requestReview();

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

  Future<void> _openStoreUrl() async {
    final url = Platform.isIOS ? _iosAppStoreUrl : _androidPlayStoreUrl;
    await UrlLauncherManager.instance.launch(url);
  }
}
