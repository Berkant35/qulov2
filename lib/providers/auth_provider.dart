import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qulo_v2/core/error/error_manager.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
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

enum AuthStatus { initial, authenticated, unauthenticated }

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
        // Initialize push notifications on auto-login
        ref.read(notificationProvider.notifier).init();
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
    double? lat,
    double? lng,
    String locale = 'tr',
    String? referralCode,
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
      lat: lat,
      lng: lng,
      locale: locale,
      referralCode: referralCode,
    );
    result.when(
      success: (_) {
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authRegisterSuccess, params: {
          AnalyticsEvents.paramMethod: 'email',
        });
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
        // Fetch user profile + seed location for immediate discover
        await ref.read(userProvider.notifier).fetchMe();
        final user = ref.read(userProvider).value;
        if (user != null) {
          final analytics = AnalyticsManager.instance;
          analytics.updateUserProperties(
            gender: user.gender ?? '',
            ageRange: AnalyticsManager.ageRange(user.age ?? 0),
            city: user.city ?? '',
            photoCount: (user.photos?.length ?? 0).toString(),
          );
          if (user.lat != null && user.lng != null) {
            ref.read(locationProvider.notifier).seedFromProfile(
              lat: user.lat!,
              lng: user.lng!,
              city: user.city,
            );
            // Pre-fetch discover cards while transitioning
            ref.read(discoverProvider.notifier).loadCards();
            // Background GPS update (non-blocking)
            ref.read(locationProvider.notifier).getCurrentLocation();
          }
        }
        // Initialize push notifications after successful login
        ref.read(notificationProvider.notifier).init();
      case Failure(:final failure):
        AnalyticsManager.instance.logEvent(AnalyticsEvents.authLoginFail, params: {
          AnalyticsEvents.paramMethod: 'email',
          AnalyticsEvents.paramErrorCode: failure.message ?? 'unknown',
        });
        state = state.copyWith(isLoading: false, failure: failure);
    }
    return result;
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
    await _clearTokens();

    // Clean up notification listeners before invalidation
    ref.read(notificationManagerProvider).dispose();

    // Invalidate all auth-dependent providers to prevent stale data crashes
    ref.invalidate(userProvider);
    ref.invalidate(discoverProvider);
    ref.invalidate(matchListProvider);
    ref.invalidate(diamondProvider);
    ref.invalidate(powerProvider);
    ref.invalidate(questionProvider);
    ref.invalidate(subscriptionProvider);
    ref.invalidate(notificationProvider);

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

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
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
    try {
      await RevenueCatService.logOut();
    } catch (e) {
      // RevenueCat logout may fail during force logout (e.g., service not initialized)
      // — continue with local cleanup regardless
      debugPrint('[auth] forceLogout: RevenueCat error (ignored): $e');
    }

    ref.read(notificationManagerProvider).dispose();

    ref.invalidate(userProvider);
    ref.invalidate(discoverProvider);
    ref.invalidate(matchListProvider);
    ref.invalidate(diamondProvider);
    ref.invalidate(powerProvider);
    ref.invalidate(questionProvider);
    ref.invalidate(subscriptionProvider);
    ref.invalidate(notificationProvider);

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: tokens.accessToken),
      _storage.write(key: 'refresh_token', value: tokens.refreshToken),
      _storage.write(key: 'user_id', value: tokens.userId),
    ]);
  }

  Future<void> _clearTokens() async {
    await _storage.deleteAll();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
