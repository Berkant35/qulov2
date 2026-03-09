# Network Layer Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Network katmanını Result pattern, Retrofit, ayrı interceptor'lar ve LogManager ile yeniden yapılandır.

**Architecture:** Sealed Result<T> + AppFailure ile tip-güvenli error handling. Retrofit ile code-generated API service'ler. NetworkManager singleton ile Dio yönetimi. Repository katmanı Retrofit service'leri Result<T>'ye wrap eder. Provider/screen katmanı pattern matching ile handle eder.

**Tech Stack:** Dart 3 sealed class, Retrofit (retrofit + retrofit_generator), pretty_dio_logger, Riverpod

---

### Task 1: Paket Ekle (pubspec.yaml)

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Paketleri ekle**

`pubspec.yaml`'a ekle:
```yaml
dependencies:
  retrofit: ^4.4.1
  pretty_dio_logger: ^1.4.0

dev_dependencies:
  retrofit_generator: ^9.1.7
  # build_runner zaten var (^2.4.13)
  # json_serializable zaten var (^6.9.0)
```

**Step 2: Paketleri yükle**

Run: `flutter pub get`
Expected: No errors

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add retrofit and pretty_dio_logger packages"
```

---

### Task 2: Result<T> ve AppFailure Sealed Class'ları

**Files:**
- Create: `lib/core/network/result.dart`

**Step 1: Result ve AppFailure yaz**

```dart
import 'package:dio/dio.dart';

// ─── Result ───
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure(:final failure) => failure(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}

// ─── AppFailure ───
sealed class AppFailure {
  final String? message;
  const AppFailure({this.message});
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.message = 'No internet connection'});
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({super.message = 'Request timed out'});
}

final class ServerFailure extends AppFailure {
  final String code;
  final dynamic params;
  final int? statusCode;

  const ServerFailure({
    required this.code,
    this.params,
    this.statusCode,
    super.message,
  });
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({super.message = 'Unauthorized'});
}

final class UnknownFailure extends AppFailure {
  final Object? error;
  const UnknownFailure({this.error, super.message});
}

// ─── DioException → AppFailure extension ───
extension DioExceptionToFailure on DioException {
  AppFailure toAppFailure() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        if (statusCode == 401) {
          return const UnauthorizedFailure();
        }
        final data = response?.data;
        if (data is Map<String, dynamic>) {
          final error = data['error'] as Map<String, dynamic>?;
          if (error != null) {
            return ServerFailure(
              code: error['code'] as String? ?? 'SERVER_ERROR',
              params: error['params'],
              statusCode: statusCode,
              message: error['message'] as String?,
            );
          }
        }
        return ServerFailure(
          code: 'SERVER_ERROR',
          statusCode: statusCode,
        );
      default:
        return UnknownFailure(error: error);
    }
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/network/result.dart
git commit -m "feat: add Result<T> sealed class and AppFailure hierarchy"
```

---

### Task 3: LogManager Singleton

**Files:**
- Create: `lib/core/network/log_manager.dart`

**Step 1: LogManager yaz**

```dart
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:dio/dio.dart';

class LogManager {
  LogManager._();
  static final LogManager instance = LogManager._();

  void logRequest(String method, String url) {
    if (kDebugMode) {
      debugPrint('→ $method $url');
    }
  }

  void logResponse(String method, String url, int? statusCode) {
    if (kDebugMode) {
      debugPrint('← $statusCode $method $url');
    }
  }

  void logError(String method, String url, int? statusCode, String? message) {
    if (kDebugMode) {
      debugPrint('✖ $statusCode $method $url ${message ?? ''}');
    }
  }

  void logInfo(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  Interceptor get dioLogInterceptor => PrettyDioLogger(
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: kDebugMode,
        error: kDebugMode,
        compact: true,
        maxWidth: 90,
      );
}
```

**Step 2: Commit**

```bash
git add lib/core/network/log_manager.dart
git commit -m "feat: add LogManager singleton with pretty_dio_logger"
```

---

### Task 4: Interceptor'ları Ayır (Auth + Error + Log)

**Files:**
- Create: `lib/core/network/interceptors/auth_interceptor.dart`
- Create: `lib/core/network/interceptors/error_interceptor.dart`
- Create: `lib/core/network/interceptors/log_interceptor.dart`

**Step 1: AuthInterceptor yaz**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/env.dart';
import '../log_manager.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        _isRefreshing = false;
        return handler.next(err);
      }

      final response = await Dio().post(
        '${Env.apiBaseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess = response.data['accessToken'] as String;
      final newRefresh = response.data['refreshToken'] as String;
      await _storage.write(key: 'access_token', value: newAccess);
      await _storage.write(key: 'refresh_token', value: newRefresh);

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(err.requestOptions);
      _isRefreshing = false;
      return handler.resolve(retryResponse);
    } catch (e) {
      _isRefreshing = false;
      await _storage.deleteAll();
      LogManager.instance.logError(
        err.requestOptions.method,
        err.requestOptions.path,
        401,
        'Token refresh failed',
      );
      return handler.next(err);
    }
  }
}
```

**Step 2: ErrorInterceptor yaz**

```dart
import 'package:dio/dio.dart';
import '../../error/error_manager.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ErrorManager.logError(
      err,
      err.stackTrace,
      'API ${err.requestOptions.method} ${err.requestOptions.path}',
    );
    handler.next(err);
  }
}
```

**Step 3: AppLogInterceptor yaz**

```dart
import 'package:dio/dio.dart';
import '../log_manager.dart';

class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    LogManager.instance.logRequest(options.method, options.path);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    LogManager.instance.logResponse(
      response.requestOptions.method,
      response.requestOptions.path,
      response.statusCode,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LogManager.instance.logError(
      err.requestOptions.method,
      err.requestOptions.path,
      err.response?.statusCode,
      err.message,
    );
    handler.next(err);
  }
}
```

**Step 4: Commit**

```bash
git add lib/core/network/interceptors/
git commit -m "feat: add Auth, Error, and Log interceptors (SRP)"
```

---

### Task 5: NetworkManager Singleton

**Files:**
- Create: `lib/core/network/network_manager.dart`

**Step 1: NetworkManager yaz**

```dart
import 'package:dio/dio.dart';
import '../config/env.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'result.dart';

class NetworkManager {
  NetworkManager._() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(_dio),
      AppLogInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  static final NetworkManager _instance = NetworkManager._();
  static NetworkManager get instance => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  // ─── Manual Methods (Result<T>) ───

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return Success(parser != null ? parser(response.data) : response.data as T);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return Success(parser != null ? parser(response.data) : response.data as T);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return Success(parser != null ? parser(response.data) : response.data as T);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  Future<Result<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return Success(parser != null ? parser(response.data) : response.data as T);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await _dio.delete(path, data: data);
      return Success(parser != null ? parser(response.data) : response.data as T);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  Future<Result<T>> upload<T>(
    String path, {
    required FormData data,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return Success(parser != null ? parser(response.data) : response.data as T);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/network/network_manager.dart
git commit -m "feat: add NetworkManager singleton with Result<T> methods"
```

---

### Task 6: Retrofit Service'ler — Auth, User

**Files:**
- Create: `lib/core/network/services/auth_service.dart`
- Create: `lib/core/network/services/user_service.dart`

**Step 1: AuthService yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/auth_model.dart';

part 'auth_service.g.dart';

@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio) = _AuthService;

  @POST('/auth/register')
  Future<RegisterResponse> register(@Body() Map<String, dynamic> body);

  @POST('/auth/login')
  Future<AuthTokens> login(@Body() Map<String, dynamic> body);

  @POST('/auth/verify-email')
  Future<void> verifyEmail(@Body() Map<String, dynamic> body);

  @POST('/auth/refresh')
  Future<RefreshResponse> refresh(@Body() Map<String, dynamic> body);

  @POST('/auth/logout')
  Future<void> logout(@Body() Map<String, dynamic> body);

  @POST('/auth/forgot-password')
  Future<void> forgotPassword(@Body() Map<String, dynamic> body);

  @POST('/auth/reset-password')
  Future<void> resetPassword(@Body() Map<String, dynamic> body);
}
```

**Step 2: UserService yaz**

Not: `uploadPhoto` ve `deletePhoto` Retrofit'e uygun değil (multipart + dynamic path), bunlar NetworkManager manual metod ile yapılacak — repository'de kalacak.

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/user_details_model.dart';

part 'user_service.g.dart';

@RestApi()
abstract class UserService {
  factory UserService(Dio dio) = _UserService;

  @GET('/users/me')
  Future<UserModel> getMe();

  @PATCH('/users/me')
  Future<UserModel> updateProfile(@Body() Map<String, dynamic> data);

  @PATCH('/users/me/details')
  Future<UserDetailsModel> updateDetails(@Body() Map<String, dynamic> data);

  @PATCH('/users/me/location')
  Future<void> updateLocation(@Body() Map<String, dynamic> data);

  @PATCH('/users/me/push-token')
  Future<void> updatePushToken(@Body() Map<String, dynamic> data);

  @DELETE('/users/me')
  Future<void> deleteAccount();

  @POST('/users/me/boost')
  Future<Map<String, dynamic>> boost();
}
```

**Step 3: Commit**

```bash
git add lib/core/network/services/auth_service.dart lib/core/network/services/user_service.dart
git commit -m "feat: add AuthService and UserService Retrofit interfaces"
```

---

### Task 7: Retrofit Service'ler — Question, Match, Quiz

**Files:**
- Create: `lib/core/network/services/question_service.dart`
- Create: `lib/core/network/services/match_service.dart`
- Create: `lib/core/network/services/quiz_service.dart`

**Step 1: QuestionService yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/question_model.dart';

part 'question_service.g.dart';

@RestApi()
abstract class QuestionService {
  factory QuestionService(Dio dio) = _QuestionService;

  @GET('/questions/me')
  Future<List<QuestionModel>> getMyQuestions();

  @POST('/questions/me')
  Future<QuestionModel> createQuestion(@Body() Map<String, dynamic> data);

  @PATCH('/questions/me/{orderNum}')
  Future<QuestionModel> updateQuestion(
    @Path('orderNum') int orderNum,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/questions/me/{orderNum}')
  Future<void> deleteQuestion(@Path('orderNum') int orderNum);

  @GET('/questions/count/me')
  Future<Map<String, dynamic>> getQuestionCount();
}
```

**Step 2: MatchService yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/discover_model.dart';
import '../../../data/models/match_model.dart';

part 'match_service.g.dart';

@RestApi()
abstract class MatchService {
  factory MatchService(Dio dio) = _MatchService;

  @GET('/match/discover')
  Future<DiscoverResponse> discover(@Query('page') int page);

  @POST('/match/swipe')
  Future<SwipeResponse> swipe(@Body() Map<String, dynamic> data);

  @GET('/match/list')
  Future<List<MatchModel>> getMatches();

  @DELETE('/match/{matchId}')
  Future<void> unmatch(@Path('matchId') String matchId);
}
```

**Step 3: QuizService yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/quiz_model.dart';

part 'quiz_service.g.dart';

@RestApi()
abstract class QuizService {
  factory QuizService(Dio dio) = _QuizService;

  @POST('/quiz/start')
  Future<QuizStartResponse> startSession(@Body() Map<String, dynamic> data);

  @GET('/quiz/{sessionId}')
  Future<QuizQuestionModel> getCurrentQuestion(
    @Path('sessionId') String sessionId,
  );

  @POST('/quiz/{sessionId}/answer')
  Future<QuizAnswerResponse> answerQuestion(
    @Path('sessionId') String sessionId,
    @Body() Map<String, dynamic> data,
  );

  @GET('/quiz/{sessionId}/result')
  Future<QuizResultModel> getSessionResult(
    @Path('sessionId') String sessionId,
  );
}
```

**Step 4: Commit**

```bash
git add lib/core/network/services/question_service.dart lib/core/network/services/match_service.dart lib/core/network/services/quiz_service.dart
git commit -m "feat: add Question, Match, Quiz Retrofit services"
```

---

### Task 8: Retrofit Service'ler — Chat, Diamond, Power, Passport, Report

**Files:**
- Create: `lib/core/network/services/chat_service.dart`
- Create: `lib/core/network/services/diamond_service.dart`
- Create: `lib/core/network/services/power_service.dart`
- Create: `lib/core/network/services/passport_service.dart`
- Create: `lib/core/network/services/report_service.dart`

**Step 1: ChatService yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/message_model.dart';

part 'chat_service.g.dart';

@RestApi()
abstract class ChatService {
  factory ChatService(Dio dio) = _ChatService;

  @GET('/chat/{matchId}/messages')
  Future<MessagesResponse> getMessages(
    @Path('matchId') String matchId,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST('/chat/{matchId}/messages')
  Future<MessageModel> sendMessage(
    @Path('matchId') String matchId,
    @Body() Map<String, dynamic> data,
  );

  @POST('/chat/{matchId}/read')
  Future<void> markAsRead(@Path('matchId') String matchId);
}
```

**Step 2: DiamondService yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/diamond_model.dart';

part 'diamond_service.g.dart';

@RestApi()
abstract class DiamondService {
  factory DiamondService(Dio dio) = _DiamondService;

  @GET('/diamonds/balance')
  Future<DiamondBalance> getBalance();

  @GET('/diamonds/history')
  Future<DiamondHistoryResponse> getHistory(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST('/diamonds/purchase')
  Future<void> purchase(@Body() Map<String, dynamic> data);
}
```

**Step 3: PowerService yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/power_model.dart';

part 'power_service.g.dart';

@RestApi()
abstract class PowerService {
  factory PowerService(Dio dio) = _PowerService;

  @GET('/powers')
  Future<List<PowerModel>> getPowers();
}
```

**Step 4: PassportService yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'passport_service.g.dart';

@RestApi()
abstract class PassportService {
  factory PassportService(Dio dio) = _PassportService;

  @POST('/passport/activate')
  Future<Map<String, dynamic>> activate(@Body() Map<String, dynamic> data);

  @POST('/passport/deactivate')
  Future<void> deactivate();
}
```

**Step 5: ReportService yaz**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'report_service.g.dart';

@RestApi()
abstract class ReportService {
  factory ReportService(Dio dio) = _ReportService;

  @POST('/reports')
  Future<void> createReport(@Body() Map<String, dynamic> data);
}
```

**Step 6: Commit**

```bash
git add lib/core/network/services/
git commit -m "feat: add Chat, Diamond, Power, Passport, Report Retrofit services"
```

---

### Task 9: Code Generation — build_runner

**Step 1: Build runner çalıştır**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

Expected: 10 adet `.g.dart` dosyası oluşur (`lib/core/network/services/` altında)

**Step 2: Hataları düzelt (varsa)**

Model class'larda `fromJson` factory'si eksik veya Retrofit uyumsuzlukları olabilir. Hataları düzelt ve tekrar build et.

**Step 3: Commit**

```bash
git add lib/core/network/services/*.g.dart
git commit -m "chore: generate Retrofit service implementations"
```

---

### Task 10: Repository'leri Refactor Et — Auth, User

**Files:**
- Modify: `lib/data/repositories/auth_repository.dart`
- Modify: `lib/data/repositories/user_repository.dart`

**Step 1: AuthRepository refactor**

```dart
import 'package:dio/dio.dart';
import '../../core/network/network_manager.dart';
import '../../core/network/result.dart';
import '../../core/network/services/auth_service.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final AuthService _service;

  AuthRepository(AuthService service) : _service = service;

  Future<Result<RegisterResponse>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required int age,
    required String gender,
    String locale = 'tr',
  }) async {
    try {
      final response = await _service.register({
        'email': email,
        'password': password,
        'name': name,
        'surname': surname,
        'age': age,
        'gender': gender,
        'locale': locale,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _service.login({
        'email': email,
        'password': password,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> verifyEmail(String token) async {
    try {
      await _service.verifyEmail({'token': token});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<RefreshResponse>> refresh(String refreshToken) async {
    try {
      final response = await _service.refresh({'refreshToken': refreshToken});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> logout({String? refreshToken}) async {
    try {
      await _service.logout({
        if (refreshToken != null) 'refreshToken': refreshToken,
      });
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> forgotPassword(String email) async {
    try {
      await _service.forgotPassword({'email': email});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _service.resetPassword({'token': token, 'password': password});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 2: UserRepository refactor**

```dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/network/network_manager.dart';
import '../../core/network/result.dart';
import '../../core/network/services/user_service.dart';
import '../models/user_model.dart';
import '../models/user_details_model.dart';

class UserRepository {
  final UserService _service;
  final NetworkManager _network;

  UserRepository(UserService service, NetworkManager network)
      : _service = service,
        _network = network;

  Future<Result<UserModel>> getMe() async {
    try {
      final response = await _service.getMe();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<UserModel>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _service.updateProfile(data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<UserDetailsModel>> updateDetails(Map<String, dynamic> data) async {
    try {
      final response = await _service.updateDetails(data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> updateLocation({required double lat, required double lng}) async {
    try {
      await _service.updateLocation({'lat': lat, 'lng': lng});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> updatePushToken(String token) async {
    try {
      await _service.updatePushToken({'push_token': token});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<Map<String, dynamic>>> uploadPhoto(Uint8List bytes, String mimeType) async {
    final ext = mimeType == 'image/png' ? 'png' : 'jpg';
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(
        bytes,
        filename: 'photo.$ext',
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    return _network.upload('/users/me/photos', data: formData);
  }

  Future<Result<Map<String, dynamic>>> deletePhoto(int index) async {
    return _network.delete('/users/me/photos/$index');
  }

  Future<Result<void>> deleteAccount() async {
    try {
      await _service.deleteAccount();
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<Map<String, dynamic>>> boost() async {
    try {
      final response = await _service.boost();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 3: Commit**

```bash
git add lib/data/repositories/auth_repository.dart lib/data/repositories/user_repository.dart
git commit -m "refactor: migrate Auth and User repositories to Retrofit + Result<T>"
```

---

### Task 11: Repository'leri Refactor Et — Question, Match, Quiz

**Files:**
- Modify: `lib/data/repositories/question_repository.dart`
- Modify: `lib/data/repositories/match_repository.dart`
- Modify: `lib/data/repositories/quiz_repository.dart`

**Step 1: QuestionRepository refactor**

```dart
import 'package:dio/dio.dart';
import '../../core/network/result.dart';
import '../../core/network/services/question_service.dart';
import '../models/question_model.dart';

class QuestionRepository {
  final QuestionService _service;

  QuestionRepository(QuestionService service) : _service = service;

  Future<Result<List<QuestionModel>>> getMyQuestions() async {
    try {
      final response = await _service.getMyQuestions();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<QuestionModel>> createQuestion(Map<String, dynamic> data) async {
    try {
      final response = await _service.createQuestion(data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<QuestionModel>> updateQuestion(int orderNum, Map<String, dynamic> data) async {
    try {
      final response = await _service.updateQuestion(orderNum, data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> deleteQuestion(int orderNum) async {
    try {
      await _service.deleteQuestion(orderNum);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<int>> getQuestionCount() async {
    try {
      final response = await _service.getQuestionCount();
      return Success(response['count'] as int);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 2: MatchRepository refactor**

```dart
import 'package:dio/dio.dart';
import '../../core/network/result.dart';
import '../../core/network/services/match_service.dart';
import '../models/discover_model.dart';
import '../models/match_model.dart';

class MatchRepository {
  final MatchService _service;

  MatchRepository(MatchService service) : _service = service;

  Future<Result<DiscoverResponse>> discover({int page = 1}) async {
    try {
      final response = await _service.discover(page);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<SwipeResponse>> swipe({required String targetId, required String action}) async {
    try {
      final response = await _service.swipe({
        'target_id': targetId,
        'action': action,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<List<MatchModel>>> getMatches() async {
    try {
      final response = await _service.getMatches();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> unmatch(String matchId) async {
    try {
      await _service.unmatch(matchId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 3: QuizRepository refactor**

```dart
import 'package:dio/dio.dart';
import '../../core/network/result.dart';
import '../../core/network/services/quiz_service.dart';
import '../models/quiz_model.dart';

class QuizRepository {
  final QuizService _service;

  QuizRepository(QuizService service) : _service = service;

  Future<Result<QuizStartResponse>> startSession(String targetId) async {
    try {
      final response = await _service.startSession({'target_id': targetId});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<QuizQuestionModel>> getCurrentQuestion(String sessionId) async {
    try {
      final response = await _service.getCurrentQuestion(sessionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<QuizAnswerResponse>> answerQuestion(
    String sessionId, {
    required int selectedAnswer,
    String? powerUsed,
  }) async {
    try {
      final response = await _service.answerQuestion(sessionId, {
        'selected_answer': selectedAnswer,
        if (powerUsed != null) 'power_used': powerUsed,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<QuizResultModel>> getSessionResult(String sessionId) async {
    try {
      final response = await _service.getSessionResult(sessionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 4: Commit**

```bash
git add lib/data/repositories/question_repository.dart lib/data/repositories/match_repository.dart lib/data/repositories/quiz_repository.dart
git commit -m "refactor: migrate Question, Match, Quiz repositories to Retrofit + Result<T>"
```

---

### Task 12: Repository'leri Refactor Et — Chat, Diamond, Power, Passport, Report

**Files:**
- Modify: `lib/data/repositories/chat_repository.dart`
- Modify: `lib/data/repositories/diamond_repository.dart`
- Modify: `lib/data/repositories/power_repository.dart`
- Modify: `lib/data/repositories/passport_repository.dart`
- Modify: `lib/data/repositories/report_repository.dart`

**Step 1: ChatRepository refactor**

```dart
import 'package:dio/dio.dart';
import '../../core/network/result.dart';
import '../../core/network/services/chat_service.dart';
import '../models/message_model.dart';

class ChatRepository {
  final ChatService _service;

  ChatRepository(ChatService service) : _service = service;

  Future<Result<MessagesResponse>> getMessages(String matchId, {int page = 1, int limit = 30}) async {
    try {
      final response = await _service.getMessages(matchId, page, limit);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<MessageModel>> sendMessage(String matchId, {required String content, bool isImage = false}) async {
    try {
      final response = await _service.sendMessage(matchId, {
        'content': content,
        'is_image': isImage,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> markAsRead(String matchId) async {
    try {
      await _service.markAsRead(matchId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 2: DiamondRepository refactor**

```dart
import 'package:dio/dio.dart';
import '../../core/network/result.dart';
import '../../core/network/services/diamond_service.dart';
import '../models/diamond_model.dart';

class DiamondRepository {
  final DiamondService _service;

  DiamondRepository(DiamondService service) : _service = service;

  Future<Result<DiamondBalance>> getBalance() async {
    try {
      final response = await _service.getBalance();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<DiamondHistoryResponse>> getHistory({int page = 1, int limit = 20}) async {
    try {
      final response = await _service.getHistory(page, limit);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> purchase(String iapProductId) async {
    try {
      await _service.purchase({'product_id': iapProductId});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 3: PowerRepository refactor**

```dart
import 'package:dio/dio.dart';
import '../../core/network/result.dart';
import '../../core/network/services/power_service.dart';
import '../models/power_model.dart';

class PowerRepository {
  final PowerService _service;

  PowerRepository(PowerService service) : _service = service;

  Future<Result<List<PowerModel>>> getPowers() async {
    try {
      final response = await _service.getPowers();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 4: PassportRepository refactor**

```dart
import 'package:dio/dio.dart';
import '../../core/network/result.dart';
import '../../core/network/services/passport_service.dart';

class PassportRepository {
  final PassportService _service;

  PassportRepository(PassportService service) : _service = service;

  Future<Result<Map<String, dynamic>>> activate({
    required String city,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _service.activate({
        'city': city,
        'lat': lat,
        'lng': lng,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> deactivate() async {
    try {
      await _service.deactivate();
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 5: ReportRepository refactor**

```dart
import 'package:dio/dio.dart';
import '../../core/network/result.dart';
import '../../core/network/services/report_service.dart';

class ReportRepository {
  final ReportService _service;

  ReportRepository(ReportService service) : _service = service;

  Future<Result<void>> createReport({
    required String reportedId,
    required String reason,
    String? description,
  }) async {
    try {
      await _service.createReport({
        'reported_id': reportedId,
        'reason': reason,
        if (description != null) 'description': description,
      });
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 6: Commit**

```bash
git add lib/data/repositories/
git commit -m "refactor: migrate remaining repositories to Retrofit + Result<T>"
```

---

### Task 13: Provider Katmanını Güncelle — api_provider.dart

**Files:**
- Modify: `lib/providers/api_provider.dart`

**Step 1: api_provider refactor**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/network_manager.dart';
import '../core/network/services/auth_service.dart';
import '../core/network/services/user_service.dart';
import '../core/network/services/question_service.dart';
import '../core/network/services/match_service.dart';
import '../core/network/services/quiz_service.dart';
import '../core/network/services/chat_service.dart';
import '../core/network/services/diamond_service.dart';
import '../core/network/services/power_service.dart';
import '../core/network/services/passport_service.dart';
import '../core/network/services/report_service.dart';
import '../data/repositories/repositories.dart';

// ─── NetworkManager ───
final networkManagerProvider = Provider<NetworkManager>(
  (_) => NetworkManager.instance,
);

// ─── Retrofit Services ───
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(networkManagerProvider).dio),
);
final userServiceProvider = Provider<UserService>(
  (ref) => UserService(ref.read(networkManagerProvider).dio),
);
final questionServiceProvider = Provider<QuestionService>(
  (ref) => QuestionService(ref.read(networkManagerProvider).dio),
);
final matchServiceProvider = Provider<MatchService>(
  (ref) => MatchService(ref.read(networkManagerProvider).dio),
);
final quizServiceProvider = Provider<QuizService>(
  (ref) => QuizService(ref.read(networkManagerProvider).dio),
);
final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(ref.read(networkManagerProvider).dio),
);
final diamondServiceProvider = Provider<DiamondService>(
  (ref) => DiamondService(ref.read(networkManagerProvider).dio),
);
final powerServiceProvider = Provider<PowerService>(
  (ref) => PowerService(ref.read(networkManagerProvider).dio),
);
final passportServiceProvider = Provider<PassportService>(
  (ref) => PassportService(ref.read(networkManagerProvider).dio),
);
final reportServiceProvider = Provider<ReportService>(
  (ref) => ReportService(ref.read(networkManagerProvider).dio),
);

// ─── Repositories ───
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(authServiceProvider)),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(
    ref.read(userServiceProvider),
    ref.read(networkManagerProvider),
  ),
);
final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(ref.read(questionServiceProvider)),
);
final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.read(matchServiceProvider)),
);
final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.read(quizServiceProvider)),
);
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.read(chatServiceProvider)),
);
final diamondRepositoryProvider = Provider<DiamondRepository>(
  (ref) => DiamondRepository(ref.read(diamondServiceProvider)),
);
final powerRepositoryProvider = Provider<PowerRepository>(
  (ref) => PowerRepository(ref.read(powerServiceProvider)),
);
final passportRepositoryProvider = Provider<PassportRepository>(
  (ref) => PassportRepository(ref.read(passportServiceProvider)),
);
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.read(reportServiceProvider)),
);
```

**Step 2: Commit**

```bash
git add lib/providers/api_provider.dart
git commit -m "refactor: update api_provider with NetworkManager, Retrofit services"
```

---

### Task 14: Provider'ları Result<T> Uyumlu Yap — auth_provider

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**Step 1: AuthNotifier Result pattern ile güncelle**

Tüm `try-catch` → `result.when()` pattern'ine çevir:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/error/error_manager.dart';
import '../core/network/result.dart';
import '../data/models/auth_model.dart';
import 'api_provider.dart';

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
    _checkAuth();
    return const AuthState();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await _storage.read(key: 'access_token');
      final userId = await _storage.read(key: 'user_id');
      if (token != null && userId != null) {
        ErrorManager.setUser(userId);
        state = state.copyWith(status: AuthStatus.authenticated, userId: userId);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
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
    String locale = 'tr',
  }) async {
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(authRepositoryProvider).register(
      email: email,
      password: password,
      name: name,
      surname: surname,
      age: age,
      gender: gender,
      locale: locale,
    );
    state = result.when(
      success: (_) => state.copyWith(isLoading: false),
      failure: (f) => state.copyWith(isLoading: false, failure: f),
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
    result.when(
      success: (tokens) async {
        await _saveTokens(tokens);
        ErrorManager.setUser(tokens.userId);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userId: tokens.userId,
          isLoading: false,
        );
      },
      failure: (f) {
        state = state.copyWith(isLoading: false, failure: f);
      },
    );
    return result;
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    await ref.read(authRepositoryProvider).logout(refreshToken: refreshToken);
    await _clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<Result<void>> forgotPassword(String email) async {
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

  Future<void> _saveTokens(AuthTokens tokens) async {
    await _storage.write(key: 'access_token', value: tokens.accessToken);
    await _storage.write(key: 'refresh_token', value: tokens.refreshToken);
    await _storage.write(key: 'user_id', value: tokens.userId);
  }

  Future<void> _clearTokens() async {
    await _storage.deleteAll();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

**Step 2: Commit**

```bash
git add lib/providers/auth_provider.dart
git commit -m "refactor: update AuthNotifier with Result<T> pattern"
```

---

### Task 15: Kalan Provider'ları Result<T> Uyumlu Yap

**Files:**
- Modify: `lib/providers/user_provider.dart`
- Modify: `lib/providers/question_provider.dart`
- Modify: `lib/providers/match_provider.dart`
- Modify: `lib/providers/quiz_provider.dart`
- Modify: `lib/providers/chat_provider.dart`
- Modify: `lib/providers/diamond_provider.dart`
- Modify: `lib/providers/power_provider.dart`
- Modify: `lib/providers/passport_provider.dart`

**Step 1: Her provider'ı oku ve güncelle**

Her provider dosyasında:
1. `import '../../core/network/result.dart';` ekle
2. `try-catch` bloklarını `result.when()` veya `switch` ile değiştir
3. `AsyncValue.guard()` kullanan yerlerde: guard içindeki repository çağrısı artık `Result<T>` dönüyor, buna göre güncelle
4. `error: String?` → `failure: AppFailure?` olarak güncelle (state class'larda)

**Pattern:**
```dart
// Eski:
state = await AsyncValue.guard(() => ref.read(matchRepositoryProvider).getMatches());

// Yeni:
final result = await ref.read(matchRepositoryProvider).getMatches();
state = result.when(
  success: (data) => AsyncData(data),
  failure: (f) => AsyncError(f, StackTrace.current),
);
```

**Step 2: Commit**

```bash
git add lib/providers/
git commit -m "refactor: update all providers with Result<T> pattern matching"
```

---

### Task 16: Screen'leri Result<T> Uyumlu Yap

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart`
- Modify: `lib/features/auth/screens/register_screen.dart`
- Modify: `lib/features/quiz/screens/quiz_screen.dart`

**Step 1: LoginScreen güncelle**

```dart
// Eski:
try {
  await ref.read(authProvider.notifier).login(...);
} on DioException catch (e) { ... }

// Yeni:
final result = await ref.read(authProvider.notifier).login(...);
result.when(
  success: (_) {}, // router otomatik yönlendirir
  failure: (f) {
    final errorCode = switch (f) {
      ServerFailure(:final code) => code,
      NetworkFailure() => 'NETWORK_ERROR',
      TimeoutFailure() => 'TIMEOUT',
      _ => 'UNKNOWN',
    };
    setState(() => _loginError = context.l10n.errorMessage(errorCode));
  },
);
```

Artık `import 'package:dio/dio.dart';` ve `import '../../../core/error/api_exception.dart';` kaldırılabilir. Yerine `import '../../../core/network/result.dart';` eklenir.

**Step 2: register_screen ve quiz_screen için aynı pattern'i uygula**

**Step 3: Commit**

```bash
git add lib/features/
git commit -m "refactor: update screens with Result<T> pattern matching"
```

---

### Task 17: Eski Dosyaları Temizle

**Files:**
- Delete: `lib/core/network/api_client.dart`
- Delete: `lib/core/network/api_endpoints.dart`
- Delete: `lib/core/network/token_interceptor.dart`
- Keep (update): `lib/core/error/api_exception.dart` — bağımlılık kontrolü yap, kullanılmıyorsa sil

**Step 1: api_exception.dart bağımlılık kontrolü**

Run: `grep -r "ApiException" lib/ --include="*.dart"`

Eğer hiçbir yerde kullanılmıyorsa sil. Login/register screen'lerde kaldırıldıysa muhtemelen temiz.

**Step 2: Eski dosyaları sil**

```bash
rm lib/core/network/api_client.dart
rm lib/core/network/api_endpoints.dart
rm lib/core/network/token_interceptor.dart
```

**Step 3: Grep ile eski import'ları kontrol et**

Run: `grep -r "api_client.dart\|api_endpoints.dart\|token_interceptor.dart\|ApiClient\|ApiEndpoints" lib/ --include="*.dart"`

Bulgu varsa ilgili import'ları düzelt.

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove old ApiClient, ApiEndpoints, TokenInterceptor"
```

---

### Task 18: Build & Analiz

**Step 1: Build runner çalıştır (son kez)**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: No errors

**Step 2: Flutter analyze**

Run: `flutter analyze`
Expected: No errors (warning kabul edilebilir)

**Step 3: Hataları düzelt (varsa)**

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: fix analyze issues after network layer refactor"
```

---

## Özet

| Task | İçerik | Dosya Sayısı |
|------|--------|-------------|
| 1 | Paket ekle | 1 |
| 2 | Result + AppFailure | 1 (yeni) |
| 3 | LogManager | 1 (yeni) |
| 4 | 3 Interceptor | 3 (yeni) |
| 5 | NetworkManager | 1 (yeni) |
| 6-8 | 10 Retrofit Service | 10 (yeni) |
| 9 | Code generation | .g.dart'lar |
| 10-12 | 10 Repository refactor | 10 (modify) |
| 13 | api_provider refactor | 1 (modify) |
| 14-15 | Provider'lar refactor | 9 (modify) |
| 16 | Screen'ler refactor | 3 (modify) |
| 17 | Eski dosyalar temizle | 3 (delete) |
| 18 | Build & analiz | - |

**Toplam: 18 task, ~30 dosya değişikliği**
