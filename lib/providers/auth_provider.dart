import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qulo_v2/core/error/error_manager.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/meta_events_manager.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/core/services/social_auth_service.dart';
import 'package:qulo_v2/data/models/auth_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/power_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/providers/notification_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/user_languages_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/referral_provider.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/providers/deep_link_provider.dart';
import 'package:qulo_v2/providers/notification_preferences_provider.dart';

enum AuthStatus { initial, authenticated, unauthenticated, banned }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final bool isLoading;
  final AppFailure? failure;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.isLoading = false,
    this.failure,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    bool? isLoading,
    AppFailure? failure,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> checkAuth() async {
    try {
      final token = await _storage.read(key: 'access_token');
      final userId = await _storage.read(key: 'user_id');

      if (token == null || userId == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // Check JWT expiry locally first
      if (_isTokenExpired(token)) {
        final refreshed = await _tryRefreshToken();
        if (!refreshed) {
          await _clearTokens();
          state = state.copyWith(status: AuthStatus.unauthenticated);
          return;
        }
      }

      // Token not expired (or refreshed) — validate with server
      try {
        await ref.read(userProvider.notifier).fetchMe();

        // Check if fetchMe resulted in a ban error
        final userState = ref.read(userProvider);
        if (userState is AsyncError) {
          final failure = userState.error;
          if (failure is ServerFailure && failure.code == 'ACCOUNT_BANNED') {
            await _clearTokens();
            state = state.copyWith(status: AuthStatus.banned);
            return;
          }
          await _clearTokens();
          state = state.copyWith(status: AuthStatus.unauthenticated);
          return;
        }

        ErrorManager.setUser(userId);
        AnalyticsManager.instance.setUserId(userId);
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authLoginSuccess, params: {
          AnalyticsEvents.paramMethod: 'auto',
        });
        try {
          await RevenueCatService.init(userId);
          await RevenueCatService.logIn(userId);
        } catch (_) {
          // RevenueCat init failure shouldn't block auto-login
        }
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userId: userId,
        );
        // Update user properties for analytics
        final user = ref.read(userProvider).value;
        if (user != null) {
          final analytics = AnalyticsManager.instance;
          analytics.updateUserProperties(
            gender: user.gender ?? '',
            ageRange: AnalyticsManager.ageRange(user.age ?? 0),
            city: user.city ?? '',
            photoCount: (user.photos?.length ?? 0).toString(),
            questionsCount: user.questionCount.toString(),
          );
        }
        // Seed location from user profile so discover works immediately
        if (user != null && user.lat != null && user.lng != null) {
          ref.read(locationProvider.notifier).seedFromProfile(
            lat: user.lat!,
            lng: user.lng!,
            city: user.city,
          );
          // Pre-fetch discover cards while splash is still showing
          ref.read(discoverProvider.notifier).loadCards();
          // Background GPS update (non-blocking)
          ref.read(locationProvider.notifier).getCurrentLocation();
        }
        // Sync passport state from user profile
        if (user != null) {
          ref.read(passportProvider.notifier).syncFromUser(
            user.passportCity,
            user.passportLat,
            user.passportLng,
          );
        }
        // Initialize push notifications on auto-login
        ref.read(notificationProvider.notifier).init();
        // Sync user language preferences from user profile
        ref.read(userLanguagesProvider.notifier).syncFromUser();
        // Start presence heartbeat
        ref.read(presenceManagerProvider).start();
      } catch (_) {
        if (state.status == AuthStatus.initial) {
          await _clearTokens();
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<Result<RegisterResponse>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required int age,
    required String gender,
    required String genderPref,
    double? lat,
    double? lng,
    String locale = 'tr',
  }) async {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.authRegisterStart, params: {
      AnalyticsEvents.paramMethod: 'email',
    });
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(authRepositoryProvider).register(
      email: email,
      password: password,
      name: name,
      surname: surname,
      age: age,
      gender: gender,
      genderPref: genderPref,
      lat: lat,
      lng: lng,
      locale: locale,
    );
    result.when(
      success: (_) {
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authRegisterSuccess, params: {
          AnalyticsEvents.paramMethod: 'email',
        });
        MetaEventsManager.instance.logCompleteRegistration(method: 'email');
        state = state.copyWith(isLoading: false);
      },
      failure: (f) {
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authRegisterFail, params: {
          AnalyticsEvents.paramMethod: 'email',
          AnalyticsEvents.paramErrorCode: f.message ?? 'unknown',
        });
        state = state.copyWith(isLoading: false, failure: f);
      },
    );
    return result;
  }

  Future<Result<AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(authRepositoryProvider).login(
      email: email,
      password: password,
    );
    switch (result) {
      case Success(:final data):
        await _saveTokens(data);
        ErrorManager.setUser(data.userId);
        AnalyticsManager.instance.setUserId(data.userId);
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authLoginSuccess, params: {
          AnalyticsEvents.paramMethod: 'email',
        });
        try {
          await RevenueCatService.init(data.userId);
          await RevenueCatService.logIn(data.userId);
        } catch (_) {
          // RevenueCat init failure shouldn't block login
        }
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userId: data.userId,
          isLoading: false,
        );
        await _postLoginInit();
      case Failure(:final failure):
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authLoginFail, params: {
          AnalyticsEvents.paramMethod: 'email',
          AnalyticsEvents.paramErrorCode: failure.message ?? 'unknown',
        });
        if (failure is ServerFailure && failure.code == 'ACCOUNT_BANNED') {
          state = state.copyWith(isLoading: false, status: AuthStatus.banned, failure: failure);
        } else {
          state = state.copyWith(isLoading: false, failure: failure);
        }
    }
    return result;
  }

  Future<void> _postLoginInit() async {
    await ref.read(userProvider.notifier).fetchMe();
    final user = ref.read(userProvider).value;
    if (user != null) {
      final analytics = AnalyticsManager.instance;
      analytics.updateUserProperties(
        gender: user.gender ?? '',
        ageRange: AnalyticsManager.ageRange(user.age ?? 0),
        city: user.city ?? '',
        photoCount: (user.photos?.length ?? 0).toString(),
        questionsCount: user.questionCount.toString(),
      );
      if (user.lat != null && user.lng != null) {
        ref.read(locationProvider.notifier).seedFromProfile(
          lat: user.lat!,
          lng: user.lng!,
          city: user.city,
        );
        ref.read(discoverProvider.notifier).loadCards();
        ref.read(locationProvider.notifier).getCurrentLocation();
      }
      ref.read(passportProvider.notifier).syncFromUser(
        user.passportCity,
        user.passportLat,
        user.passportLng,
      );
    }
    ref.read(notificationProvider.notifier).init();
    ref.read(userLanguagesProvider.notifier).syncFromUser();
    ref.read(presenceManagerProvider).start();
  }

  /// Called after social login profile completion.
  /// Re-emits auth state to trigger GoRouter redirect (profile-completion → discover).
  Future<void> onProfileCompleted() async {
    // Social signup'ta kayıt burada tamamlanır (profil tamamlama adımı sonu)
    MetaEventsManager.instance.logCompleteRegistration(method: 'social');
    await _postLoginInit();
    // Re-emit authenticated state so GoRouter re-evaluates redirect
    // (user.age is now non-null → profile-completion guard passes)
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  Future<Result<SocialLoginResponse>> socialLogin(String provider) async {
    state = state.copyWith(isLoading: true, failure: null);

    try {
      final socialService = ref.read(socialAuthServiceProvider);
      final SocialSignInResult signInResult;

      try {
        if (provider == 'google') {
          signInResult = await socialService.signInWithGoogle();
        } else {
          signInResult = await socialService.signInWithApple();
        }
      } catch (e, st) {
        debugPrint('[SocialAuth] Sign-in error: $e');
        debugPrint('[SocialAuth] Stack: $st');
        state = state.copyWith(isLoading: false);
        return Failure(UnknownFailure(message: e.toString()));
      }

      final authService = ref.read(authServiceProvider);
      final response = await authService.socialLogin({
        'provider': signInResult.provider,
        'id_token': signInResult.idToken,
        if (signInResult.name != null) 'name': signInResult.name,
        if (signInResult.surname != null) 'surname': signInResult.surname,
        if (signInResult.nonce != null) 'nonce': signInResult.nonce,
      });

      await _saveTokens(AuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.userId,
      ));

      ErrorManager.setUser(response.userId);
      AnalyticsManager.instance.setUserId(response.userId);
      AnalyticsManager.instance.logEvent(AnalyticsEvents.authLoginSuccess, params: {
        AnalyticsEvents.paramMethod: provider,
      });

      try {
        await RevenueCatService.init(response.userId);
        await RevenueCatService.logIn(response.userId);
      } catch (_) {}

      // Load user BEFORE flipping auth state — router only listens to authProvider, so the
      // refresh fires once when status becomes authenticated. If user is still null at that
      // moment, the redirect skips /profile-completion and lands on /discover (App Store Guideline 4).
      await ref.read(userProvider.notifier).fetchMe();

      state = state.copyWith(
        status: AuthStatus.authenticated,
        userId: response.userId,
        isLoading: false,
      );

      if (!response.profileIncomplete) {
        await _postLoginInit();
      }

      return Success(response);
    } on DioException catch (e) {
      final failure = e.toAppFailure();
      if (failure is ServerFailure && failure.code == 'ACCOUNT_BANNED') {
        state = state.copyWith(isLoading: false, status: AuthStatus.banned, failure: failure);
      } else {
        state = state.copyWith(isLoading: false, failure: failure);
      }
      return Failure(failure);
    } catch (e) {
      final failure = UnknownFailure(message: e.toString());
      state = state.copyWith(isLoading: false, failure: failure);
      return Failure(failure);
    }
  }

  Future<void> logout() async {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.authLogout);
    AnalyticsManager.instance.setUserId(null);
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      await ref.read(authRepositoryProvider).logout(refreshToken: refreshToken);
    } catch (_) {
      // API call may fail (expired token etc.) — still clear local state
    }
    try {
      await RevenueCatService.logOut();
    } catch (_) {
      // RevenueCat logout failure shouldn't block logout
    }
    // Stop presence heartbeat + send offline
    await ref.read(presenceManagerProvider).stop();
    await _clearTokens();

    // Clean up notification listeners before invalidation
    ref.read(notificationManagerProvider).dispose();

    _invalidateAllProviders();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<Result<void>> forgotPassword(String email) async {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.authForgotPassword);
    return ref.read(authRepositoryProvider).forgotPassword(email);
  }

  Future<Result<void>> resetPassword({
    required String token,
    required String password,
  }) async {
    return ref.read(authRepositoryProvider).resetPassword(
      token: token,
      password: password,
    );
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = map['exp'] as int?;
      if (exp == null) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      return DateTime.now().toUtc().isAfter(expiry.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final refreshDio = NetworkManager.createRefreshDio();
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess = response.data['accessToken'] as String;
      final newRefresh = response.data['refreshToken'] as String;
      await _storage.write(key: 'access_token', value: newAccess);
      await _storage.write(key: 'refresh_token', value: newRefresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> forceLogout() async {
    // Idempotent: ilk force-logout sonrası storage boş kalan in-flight 401'ler
    // bizi tekrar tetikliyor — cascade'i kırmak için zaten unauthenticated ise çık.
    if (state.status == AuthStatus.unauthenticated) {
      debugPrint('[auth] forceLogout: already unauthenticated, skip');
      return;
    }

    try {
      await RevenueCatService.logOut();
    } catch (e) {
      debugPrint('[auth] forceLogout: RevenueCat error (ignored): $e');
    }

    // Stop presence heartbeat — pause instead of stop to skip offline API call
    // (token is already invalid during force logout)
    ref.read(presenceManagerProvider).pause();

    ref.read(notificationManagerProvider).dispose();

    _invalidateAllProviders();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Invalidate all auth-dependent providers to prevent stale data crashes
  void _invalidateAllProviders() {
    ref.invalidate(userProvider);
    ref.invalidate(discoverProvider);
    ref.invalidate(matchListProvider);
    ref.invalidate(diamondProvider);
    ref.invalidate(powerProvider);
    ref.invalidate(questionProvider);
    ref.invalidate(subscriptionProvider);
    ref.invalidate(notificationProvider);
    ref.invalidate(userLanguagesProvider);
    ref.invalidate(passportProvider);
    ref.invalidate(locationProvider);
    ref.invalidate(exchangeProvider);
    ref.invalidate(referralProvider);
    ref.invalidate(quizProvider);
    ref.invalidate(notificationPreferencesProvider);
    ref.read(pendingDeepLinkProvider.notifier).state = null;
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: tokens.accessToken),
      _storage.write(key: 'refresh_token', value: tokens.refreshToken),
      _storage.write(key: 'user_id', value: tokens.userId),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'refresh_token'),
      _storage.delete(key: 'user_id'),
    ]);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
