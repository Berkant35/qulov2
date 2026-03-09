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
    switch (this) {
      case Success(:final data):
        return success(data);
      case Failure(failure: final f):
        return failure(f);
    }
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

  @override
  String toString() => message ?? runtimeType.toString();
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

  @override
  String toString() => message ?? code;
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({super.message = 'Unauthorized'});
}

final class UnknownFailure extends AppFailure {
  final Object? error;
  const UnknownFailure({this.error, super.message});

  @override
  String toString() => message ?? error?.toString() ?? 'Unknown error';
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
        final data = response?.data;
        // Her zaman önce body'deki error code'u parse et
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
        if (statusCode == 401) {
          return const UnauthorizedFailure();
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
