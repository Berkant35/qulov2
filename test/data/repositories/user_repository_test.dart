import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/user_service.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';

/// Kullanıcı repository'si — 21 metot; CLAUDE.md önceliğine göre `getMe`,
/// `deleteAccount` ve konum/profil güncelleme test edildi.
///
/// `deleteAccount` özel: **geri alınamaz** ve silme geri bildirimi taşıyor.
/// Bu veri ürün kararlarını besliyor (silme sebeplerinin %40'ı `few_matches`),
/// o yüzden payload'ın temizliği önemli — boşluktan ibaret bir `reason_text`
/// analizde gürültü olurdu.
///
/// `getUserLanguages`/`setUserLanguages` burada YOK: onlar Retrofit yerine
/// singleton `NetworkManager` üzerinden gidiyor ve fake'lenemiyor.
class _FakeUserService implements UserService {
  _FakeUserService({this.error, this.user});

  final DioException? error;
  final UserModel? user;

  Map<String, dynamic>? lastDeleteBody;
  Map<String, dynamic>? lastLocation;
  Map<String, dynamic>? lastProfile;
  int deleteCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  @override
  Future<UserModel> getMe() async {
    if (error != null) throw _err;
    return user ?? const UserModel(id: 'u1', email: 'a@b.test');
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    lastProfile = data;
    if (error != null) throw _err;
    return user ?? const UserModel(id: 'u1', email: 'a@b.test');
  }

  @override
  Future<void> updateLocation(Map<String, dynamic> data) async {
    lastLocation = data;
    if (error != null) throw _err;
  }

  @override
  Future<void> deleteAccount(Map<String, dynamic> body) async {
    deleteCallCount++;
    lastDeleteBody = body;
    if (error != null) throw _err;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeUserService.${invocation.memberName}');
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

/// `NetworkManager` yalnızca dil uçlarında kullanılıyor; burada test edilen
/// metotların hiçbiri ona dokunmuyor.
UserRepository _repo(UserService service) =>
    UserRepository(service, NetworkManager.instance);

void main() {
  group('getMe', () {
    test('kullanici modeli sarilir', () async {
      final fake = _FakeUserService(
        user: const UserModel(id: 'u9', email: 'ada@qulo.test', questionCount: 4),
      );

      final result = await _repo(fake).getMe();

      expect(result.when(success: (d) => d.id, failure: (_) => null), 'u9');
      expect(result.when(success: (d) => d.questionCount, failure: (_) => -1), 4);
    });

    test('401 ServerFailure olarak tasinir', () async {
      // Interceptor 401'i once yakaliyor; buraya dusen 401 govdeli oldugu icin
      // ServerFailure olur (bkz. result_test.dart'taki surpriz).
      final fake = _FakeUserService(
        error: _dio(DioExceptionType.badResponse,
            status: 401, body: {'error': {'code': 'TOKEN_EXPIRED'}}),
      );

      final result = await _repo(fake).getMe();

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'TOKEN_EXPIRED');
    });
  });

  group('deleteAccount — geri alinamaz, geri bildirim tasir', () {
    test('tum alanlar verilince payload tam gider', () async {
      final fake = _FakeUserService();

      await _repo(fake).deleteAccount(
        reasonCode: 'few_matches',
        reasonText: 'Kimseyle eslesemedim',
        appVersion: '2.0.10',
        platform: 'ios',
        locale: 'tr',
      );

      expect(fake.lastDeleteBody, {
        'reason_code': 'few_matches',
        'reason_text': 'Kimseyle eslesemedim',
        'app_version': '2.0.10',
        'platform': 'ios',
        'locale': 'tr',
      });
    });

    test('BOSLUKTAN IBARET reason_text HIC gonderilmez', () async {
      // Silme sebepleri urun kararlarini besliyor; bosluk-only metin analizde
      // "kullanici bir sey yazdi" gibi gorunur ve gurultu yapardi.
      final fake = _FakeUserService();

      await _repo(fake).deleteAccount(reasonCode: 'other', reasonText: '   ');

      expect(fake.lastDeleteBody!.containsKey('reason_text'), isFalse);
      expect(fake.lastDeleteBody!['reason_code'], 'other');
    });

    test('reason_text bastan/sondan kirpilir', () async {
      final fake = _FakeUserService();

      await _repo(fake).deleteAccount(reasonText: '  cok az eslesme  ');

      expect(fake.lastDeleteBody!['reason_text'], 'cok az eslesme');
    });

    test('bos reason_text de gonderilmez', () async {
      final fake = _FakeUserService();

      await _repo(fake).deleteAccount(reasonCode: 'other', reasonText: '');

      expect(fake.lastDeleteBody!.containsKey('reason_text'), isFalse);
    });

    test('hicbir alan verilmezse BOS govde gider — null anahtar yok', () async {
      // Sunucu tarafinda tum alanlar optional (user.validator.ts:45-46);
      // null anahtar gondermek gereksiz.
      final fake = _FakeUserService();

      await _repo(fake).deleteAccount();

      expect(fake.lastDeleteBody, isEmpty);
    });

    test('hata durumunda servis TAM BIR KEZ cagrilir', () async {
      // Geri alinamaz bir islemde sessiz tekrar, ikinci bir silme geri bildirimi
      // satiri yazabilir ve istatistigi bozardi.
      final fake = _FakeUserService(error: _dio(DioExceptionType.receiveTimeout));

      final result = await _repo(fake).deleteAccount(reasonCode: 'other');

      expect(result.when<AppFailure?>(success: (_) => null, failure: (f) => f),
          isA<TimeoutFailure>());
      expect(fake.deleteCallCount, 1);
    });
  });

  group('updateLocation', () {
    test('lat/lng gonderilir, sehir verilmezse anahtar YOK', () async {
      final fake = _FakeUserService();

      await _repo(fake).updateLocation(lat: 41.0, lng: 29.0);

      expect(fake.lastLocation, {'lat': 41.0, 'lng': 29.0});
    });

    test('sehir verilince eklenir', () async {
      final fake = _FakeUserService();

      await _repo(fake).updateLocation(lat: 41.0, lng: 29.0, city: 'Istanbul');

      expect(fake.lastLocation!['city'], 'Istanbul');
    });

    test('ag hatasi Failure olur — konum sessizce guncellenmis sayilmasin', () async {
      final fake = _FakeUserService(error: _dio(DioExceptionType.connectionError));

      final result = await _repo(fake).updateLocation(lat: 41.0, lng: 29.0);

      expect(result.when<AppFailure?>(success: (_) => null, failure: (f) => f),
          isA<NetworkFailure>());
    });
  });

  group('updateProfile', () {
    test('verilen map oldugu gibi iletilir', () async {
      final fake = _FakeUserService();
      final data = {'name': 'Ada', 'bio': 'merhaba', 'preferred_languages': ['tr', 'en']};

      await _repo(fake).updateProfile(data);

      expect(fake.lastProfile, data);
    });

    test('dogrulama hatasi ServerFailure kodunu tasir', () async {
      final fake = _FakeUserService(
        error: _dio(DioExceptionType.badResponse,
            status: 400, body: {'error': {'code': 'VALIDATION_ERROR'}}),
      );

      final result = await _repo(fake).updateProfile(const {'age': 12});

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'VALIDATION_ERROR');
    });
  });
}
