import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/auth_service.dart';
import 'package:qulo_v2/data/models/auth_model.dart';
import 'package:qulo_v2/data/repositories/auth_repository.dart';

/// Auth repository'si — yetki yolu (CLAUDE.md test önceliği).
///
/// Bu dosyanın en kritik işi bir **alan adı sözleşmesini** dondurmak:
/// `refresh` ve `logout` gövdesinde alan adı **camelCase `refreshToken`**.
/// API'nin geri kalanı snake_case (`gender_pref`, `tos_accepted`) olduğu için
/// biri "tutarlılık olsun" diye `refresh_token` yapabilir — sunucu
/// (`auth.validator.ts:30`) camelCase istiyor ve o değişiklik oturum
/// yenilemeyi sessizce kırar: kullanıcı bir anda logout olur.
class _FakeAuthService implements AuthService {
  _FakeAuthService({this.error});

  final DioException? error;

  Map<String, dynamic>? lastRegister;
  Map<String, dynamic>? lastLogin;
  Map<String, dynamic>? lastRefresh;
  Map<String, dynamic>? lastLogout;
  int resendCalls = 0;
  ResendVerificationResponse resendResponse = const ResendVerificationResponse(sent: true);
  Map<String, dynamic>? lastForgot;
  Map<String, dynamic>? lastReset;
  int loginCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  @override
  Future<RegisterResponse> register(Map<String, dynamic> body) async {
    lastRegister = body;
    if (error != null) throw _err;
    return const RegisterResponse(userId: 'u1', email: 'a@b.test');
  }

  @override
  Future<AuthTokens> login(Map<String, dynamic> body) async {
    loginCallCount++;
    lastLogin = body;
    if (error != null) throw _err;
    return const AuthTokens(accessToken: 'at', refreshToken: 'rt', userId: 'u1');
  }

  @override
  Future<ResendVerificationResponse> resendVerification() async {
    resendCalls++;
    if (error != null) throw _err;
    return resendResponse;
  }

  @override
  Future<RefreshResponse> refresh(Map<String, dynamic> body) async {
    lastRefresh = body;
    if (error != null) throw _err;
    return const RefreshResponse(accessToken: 'at2', refreshToken: 'rt2');
  }

  @override
  Future<void> logout(Map<String, dynamic> body) async {
    lastLogout = body;
    if (error != null) throw _err;
  }

  @override
  Future<void> forgotPassword(Map<String, dynamic> body) async {
    lastForgot = body;
    if (error != null) throw _err;
  }

  @override
  Future<void> resetPassword(Map<String, dynamic> body) async {
    lastReset = body;
    if (error != null) throw _err;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeAuthService.${invocation.memberName}');
}

DioException _dio(DioExceptionType type, {int? status, dynamic body}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: status,
              data: body,
            ),
    );

Future<Result<RegisterResponse>> _register(
  AuthRepository repo, {
  double? lat,
  double? lng,
  String locale = 'tr',
  String? genderPref = 'MAN',
  String? prefConsentStatus,
}) =>
    repo.register(
      email: 'a@b.test',
      password: 'Test1234!',
      name: 'Ada',
      surname: 'L',
      age: 27,
      gender: 'WOMAN',
      genderPref: genderPref,
      prefConsentStatus: prefConsentStatus,
      lat: lat,
      lng: lng,
      locale: locale,
    );

void main() {
  group('register', () {
    test('zorunlu alanlar snake_case gonderilir', () async {
      final fake = _FakeAuthService();

      await _register(AuthRepository(fake));

      expect(fake.lastRegister, containsPair('email', 'a@b.test'));
      expect(fake.lastRegister, containsPair('gender_pref', 'MAN'));
      expect(fake.lastRegister, containsPair('age', 27));
      expect(fake.lastRegister, containsPair('locale', 'tr'));
    });

    test('rıza verilmişse pref_consent {status, version} ve tercih gider', () async {
      final fake = _FakeAuthService();
      await _register(AuthRepository(fake), prefConsentStatus: PrefConsent.granted);
      expect(fake.lastRegister, containsPair('gender_pref', 'MAN'));
      expect(fake.lastRegister, containsPair('pref_consent', {'status': 'GRANTED', 'version': PrefConsent.version}));
    });

    test('rıza reddedilmişse tercih GÖNDERİLMEZ, pref_consent DECLINED', () async {
      final fake = _FakeAuthService();
      await _register(AuthRepository(fake), genderPref: null, prefConsentStatus: PrefConsent.declined);
      expect(fake.lastRegister!.containsKey('gender_pref'), isFalse);
      expect(fake.lastRegister, containsPair('pref_consent', {'status': 'DECLINED', 'version': PrefConsent.version}));
    });

    test('tos_accepted her zaman true — gercek kapi arayuzde', () async {
      // Sunucu `z.literal(true)` istiyor (auth.validator.ts:19), yani false
      // gondermenin bir anlami yok: istek 400 alirdi. Onay kapisi arayuzde
      // (register_screen_mixin.dart:116 onaylanmadan ilerletmiyor). Repository'ye
      // parametre eklemek gereksiz karmasiklik olurdu; davranis burada belgeli.
      final fake = _FakeAuthService();

      await _register(AuthRepository(fake));

      expect(fake.lastRegister!['tos_accepted'], true);
    });

    test('konum verilince eklenir, verilmeyince anahtar HIC gonderilmez', () async {
      final withLoc = _FakeAuthService();
      await _register(AuthRepository(withLoc), lat: 41.0, lng: 29.0);
      expect(withLoc.lastRegister!['lat'], 41.0);
      expect(withLoc.lastRegister!['lng'], 29.0);

      final withoutLoc = _FakeAuthService();
      await _register(AuthRepository(withoutLoc));
      expect(withoutLoc.lastRegister!.containsKey('lat'), isFalse);
      expect(withoutLoc.lastRegister!.containsKey('lng'), isFalse);
    });

    test('e-posta zaten kayitliysa ServerFailure kodu tasinir', () async {
      final fake = _FakeAuthService(
        error: _dio(DioExceptionType.badResponse,
            status: 409, body: {'error': {'code': 'EMAIL_ALREADY_EXISTS'}}),
      );

      final result = await _register(AuthRepository(fake));

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'EMAIL_ALREADY_EXISTS');
    });
  });

  group('login', () {
    test('kimlik bilgileri gonderilir ve token modeli sarilir', () async {
      final fake = _FakeAuthService();

      final result = await AuthRepository(fake)
          .login(email: 'a@b.test', password: 'Test1234!');

      expect(fake.lastLogin, {'email': 'a@b.test', 'password': 'Test1234!'});
      expect(result.when(success: (d) => d.accessToken, failure: (_) => null), 'at');
    });

    test('yanlis sifre ServerFailure olur ve servis TAM BIR KEZ cagrilir', () async {
      // Sessiz tekrar, sunucudaki deneme sayaci/rate limit'i bosuna tuketir.
      final fake = _FakeAuthService(
        error: _dio(DioExceptionType.badResponse,
            status: 401, body: {'error': {'code': 'INVALID_CREDENTIALS'}}),
      );

      final result = await AuthRepository(fake).login(email: 'a@b.test', password: 'yanlis');

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'INVALID_CREDENTIALS');
      expect(fake.loginCallCount, 1);
    });
  });

  group('refresh / logout — camelCase sozlesmesi', () {
    test('refresh govdesi camelCase refreshToken kullanir', () async {
      // auth.validator.ts:30 `refreshToken` istiyor. snake_case'e cevrilirse
      // token yenileme kirilir ve kullanici sessizce logout olur.
      final fake = _FakeAuthService();

      await AuthRepository(fake).refresh('rt-1');

      expect(fake.lastRefresh, {'refreshToken': 'rt-1'});
      expect(fake.lastRefresh!.containsKey('refresh_token'), isFalse);
    });

    test('logout token verilince camelCase gonderir', () async {
      final fake = _FakeAuthService();

      await AuthRepository(fake).logout(refreshToken: 'rt-1');

      expect(fake.lastLogout, {'refreshToken': 'rt-1'});
    });

    test('logout token yoksa BOS govde gonderir, null anahtar degil', () async {
      // Sunucu `req.body?.refreshToken` okuyor (auth.controller.ts:61);
      // null bir anahtar gondermek gereksiz, yoklugu anlamli.
      final fake = _FakeAuthService();

      await AuthRepository(fake).logout();

      expect(fake.lastLogout, isEmpty);
    });

    test('refresh gecersiz token hatasi ServerFailure olur', () async {
      final fake = _FakeAuthService(
        error: _dio(DioExceptionType.badResponse,
            status: 401, body: {'error': {'code': 'INVALID_TOKEN'}}),
      );

      final result = await AuthRepository(fake).refresh('bozuk');

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'INVALID_TOKEN');
    });
  });

  group('e-posta dogrulama ve sifre sifirlama', () {
    test('resendVerification yaniti tasinir (gonderildi / zaten dogrulanmis)', () async {
      final fake = _FakeAuthService();

      final sent = await AuthRepository(fake).resendVerification();
      expect(sent.when(success: (r) => r, failure: (_) => null),
          const ResendVerificationResponse(sent: true));

      fake.resendResponse = const ResendVerificationResponse(emailVerified: true);
      final verified = await AuthRepository(fake).resendVerification();
      expect(verified.when(success: (r) => r.emailVerified, failure: (_) => null), isTrue);
      expect(fake.resendCalls, 2);
    });

    test('forgotPassword e-posta gonderir', () async {
      final fake = _FakeAuthService();

      await AuthRepository(fake).forgotPassword('a@b.test');

      expect(fake.lastForgot, {'email': 'a@b.test'});
    });

    test('resetPassword token ve yeni sifreyi gonderir', () async {
      final fake = _FakeAuthService();

      await AuthRepository(fake).resetPassword(token: 'tok-2', password: 'Yeni1234!');

      expect(fake.lastReset, {'token': 'tok-2', 'password': 'Yeni1234!'});
    });

    test('yeniden gonderim hiz sinirina takilirsa (429) RATE_LIMITED tasinir', () async {
      final fake = _FakeAuthService(
        error: _dio(DioExceptionType.badResponse,
            status: 429, body: {'error': {'code': 'RATE_LIMITED'}}),
      );

      final result = await AuthRepository(fake).resendVerification();

      final failure = result.when<AppFailure?>(success: (_) => null, failure: (f) => f);
      expect((failure as ServerFailure).code, 'RATE_LIMITED');
    });
  });
}
