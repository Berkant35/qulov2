# Network Layer Refactor Design

## Problem
- ApiClient minimal wrapper, repository'ler `_client.dio.post()` ile doğrudan Dio kullanıyor
- Either/Result pattern yok — her yerde try-catch
- Retrofit yok — 36 endpoint manual yazılmış
- TokenInterceptor SRP'ye aykırı (token + refresh + error parsing tek class'ta)
- LogManager yok, debug logları dağınık

## Çözüm

### Mimari

```
lib/core/network/
├── result.dart                  # Sealed Result<T> + AppFailure
├── network_manager.dart         # Singleton Dio factory + manual metodlar
├── log_manager.dart             # Singleton, debug-only, kritik loglar
├── interceptors/
│   ├── auth_interceptor.dart    # Token ekleme + 401 refresh
│   ├── error_interceptor.dart   # DioException → AppFailure dönüşümü
│   └── log_interceptor.dart     # LogManager üzerinden pretty log
├── services/                    # Retrofit @RestApi interfaces
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── question_service.dart
│   ├── match_service.dart
│   ├── quiz_service.dart
│   ├── chat_service.dart
│   ├── diamond_service.dart
│   ├── power_service.dart
│   ├── passport_service.dart
│   └── report_service.dart
└── (api_endpoints.dart kaldırılacak)

lib/data/repositories/           # Retrofit service → Result<T> wrapping
```

### 1. Result & AppFailure

```dart
sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}
class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}

sealed class AppFailure {
  final String? message;
  const AppFailure({this.message});
}
class NetworkFailure extends AppFailure { ... }
class TimeoutFailure extends AppFailure { ... }
class ServerFailure extends AppFailure {
  final String code;
  final dynamic params;
  final int? statusCode;
}
class UnauthorizedFailure extends AppFailure { ... }
class UnknownFailure extends AppFailure { ... }
```

### 2. LogManager (Singleton)

- Debug mode only (kDebugMode)
- Kritik loglar: request method+url, error'lar, info
- PrettyDioLogger wrapper (minimal config — sadece request method, url, status code)
- Production'da hiçbir şey loglamaz

### 3. NetworkManager (Singleton)

- Dio instance oluşturma + BaseOptions
- Interceptor sırası: Auth → Log → Error
- Retrofit service'lere Dio instance verir
- Manual metodlar: `get`, `post`, `put`, `patch`, `delete`, `upload`
- Tüm manual metodlar `Result<T>` döner

### 4. Interceptor'lar (Ayrı Sorumluluklar)

| Interceptor | Sorumluluk |
|---|---|
| AuthInterceptor | onRequest: Bearer token ekle. onError: 401 → refresh → retry |
| LogInterceptor | onRequest/onResponse/onError: LogManager üzerinden log |
| ErrorInterceptor | onError: DioException → ApiException parse, attach |

### 5. Retrofit Service'ler

- Her service bir `@RestApi()` abstract class
- Endpoint'ler annotation ile tanımlı (@POST, @GET, vb.)
- Request/Response modelleri @JsonSerializable
- Code generation: retrofit_generator + build_runner

### 6. Repository Katmanı

- Retrofit service inject edilir
- Her metod `Result<T>` döner
- try-catch ile DioException → AppFailure dönüşümü
- Multipart upload gibi edge case'ler NetworkManager manual metodları ile

### 7. Provider Katmanı

- Pattern matching ile Result handle edilir
- `switch (result) { case Success → ..., case Failure → ... }`

### 8. Yeni Paketler

```yaml
dependencies:
  retrofit: ^4.4.1
  pretty_dio_logger: ^1.4.0

dev_dependencies:
  retrofit_generator: ^9.1.7
```

### 9. Kaldırılacaklar

- `lib/core/network/api_client.dart` → NetworkManager ile değiştirilecek
- `lib/core/network/api_endpoints.dart` → Retrofit annotation'larına taşınacak
- `lib/core/network/token_interceptor.dart` → AuthInterceptor + ErrorInterceptor'a bölünecek
