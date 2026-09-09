import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/block_service.dart';
import 'package:qulo_v2/data/repositories/block_repository.dart';

/// Engelleme repository'si — güvenlik yolu, şikayetle aynı ekranlardan
/// tetikleniyor. Asimetrik: engelleme gövdeyle (`{blocked_id}`), kaldırma
/// yol parametresiyle gidiyor.
class _FakeBlockService implements BlockService {
  _FakeBlockService({this.error, this.blocked});

  final DioException? error;
  final List<Map<String, dynamic>>? blocked;

  Map<String, dynamic>? lastBlockPayload;
  String? lastUnblockId;
  int blockCallCount = 0;

  @override
  Future<void> blockUser(Map<String, dynamic> data) async {
    blockCallCount++;
    lastBlockPayload = data;
    if (error != null) throw error!;
  }

  @override
  Future<void> unblockUser(String blockedId) async {
    lastUnblockId = blockedId;
    if (error != null) throw error!;
  }

  @override
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    if (error != null) throw error!;
    return blocked ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeBlockService.${invocation.memberName}');
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

void main() {
  test('blockUser govdede blocked_id gonderir', () async {
    final fake = _FakeBlockService();

    final result = await BlockRepository(fake).blockUser('u2');

    expect(fake.lastBlockPayload, {'blocked_id': 'u2'});
    expect(result.isSuccess, isTrue);
  });

  test('unblockUser kimligi YOL parametresi olarak gonderir — govde yok', () async {
    // Asimetri bilincli; engelleme POST govdeyle, kaldirma DELETE yolla.
    final fake = _FakeBlockService();

    await BlockRepository(fake).unblockUser('u2');

    expect(fake.lastUnblockId, 'u2');
  });

  test('bos engelli listesi basarili yanittir', () async {
    final result = await BlockRepository(_FakeBlockService()).getBlockedUsers();

    expect(result.isSuccess, isTrue);
    expect(result.when(success: (d) => d, failure: (_) => null), isEmpty);
  });

  test('engelli listesi oldugu gibi tasinir', () async {
    final fake = _FakeBlockService(blocked: const [
      {'blocked_id': 'u2', 'name': 'Ada'},
    ]);

    final result = await BlockRepository(fake).getBlockedUsers();

    expect(result.when(success: (d) => d.single['name'], failure: (_) => null), 'Ada');
  });

  test('zaten engellenmisse ServerFailure ve servis TAM BIR KEZ cagrilir', () async {
    // Guvenlik yolunda sessiz tekrar, mukerrer engelleme kaydi demek.
    final fake = _FakeBlockService(
      error: _dio(DioExceptionType.badResponse,
          status: 409, body: {'error': {'code': 'ALREADY_BLOCKED'}}),
    );

    final result = await BlockRepository(fake).blockUser('u2');

    final failure = result.when<AppFailure?>(success: (_) => null, failure: (f) => f);
    expect((failure as ServerFailure).code, 'ALREADY_BLOCKED');
    expect(fake.blockCallCount, 1);
  });

  test('ag hatasi Failure olur — engelledi sanilmasin', () async {
    final fake = _FakeBlockService(error: _dio(DioExceptionType.connectionError));

    final result = await BlockRepository(fake).blockUser('u2');

    expect(result.when<AppFailure?>(success: (_) => null, failure: (f) => f),
        isA<NetworkFailure>());
  });
}
