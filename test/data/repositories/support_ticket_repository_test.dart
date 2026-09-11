import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/support_ticket_service.dart';
import 'package:qulo_v2/data/repositories/support_ticket_repository.dart';

/// Destek talepleri — kullanicinin sorun bildirdigi tek kanal.
///
/// Sunucu sozlesmesi (qulo-server `support-ticket.validator.ts` /
/// `support-ticket.service.ts`): istek `subject` (5-200) + `message` (10-2000)
/// + `category` enum; yanit snake_case satir (`created_at`, `admin_reply`,
/// `replied_at`), liste duz dizi.
class _FakeSupportTicketService implements SupportTicketService {
  _FakeSupportTicketService({this.created, this.list = const [], this.error});

  final Map<String, dynamic>? created;
  final List<Map<String, dynamic>> list;
  final DioException? error;

  Map<String, dynamic>? lastPayload;
  int createCalls = 0;

  @override
  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> data) async {
    createCalls++;
    lastPayload = data;
    if (error != null) throw error!;
    return created ?? const <String, dynamic>{};
  }

  @override
  Future<List<Map<String, dynamic>>> getMyTickets() async {
    if (error != null) throw error!;
    return list;
  }

  @override
  Future<Map<String, dynamic>> getTicket(String id) async {
    if (error != null) throw error!;
    return list.firstWhere((t) => t['id'] == id, orElse: () => const <String, dynamic>{});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeSupportTicketService.${invocation.memberName}');
}

Map<String, dynamic> _row(String id, {String? reply}) => {
      'id': id,
      'subject': 'Odeme sorunu',
      'message': 'Elmaslar hesabima gecmedi',
      'category': 'BILLING',
      'status': reply == null ? 'open' : 'answered',
      'admin_reply': reply,
      'replied_at': reply == null ? null : '2026-09-10T12:00:00Z',
      'created_at': '2026-09-09T08:30:00Z',
    };

T? _data<T>(Result<T> r) => r.when(success: (d) => d, failure: (_) => null);
AppFailure? _failure<T>(Result<T> r) => r.when(success: (_) => null, failure: (f) => f);

void main() {
  test('talep payload\'i yalnizca sozlesmedeki uc alani tasir, yanit modele parse edilir', () async {
    final service = _FakeSupportTicketService(created: _row('t1'));

    final result = await SupportTicketRepository(service).createTicket(
      subject: 'Odeme sorunu',
      message: 'Elmaslar hesabima gecmedi',
      category: 'BILLING',
    );

    expect(service.lastPayload, {
      'subject': 'Odeme sorunu',
      'message': 'Elmaslar hesabima gecmedi',
      'category': 'BILLING',
    });
    expect(_data(result)?.id, 't1');
    expect(_data(result)?.createdAt, DateTime.utc(2026, 9, 9, 8, 30));
  });

  test('dogrulama hatasi kodu ile doner, servis tam bir kez cagrilir', () async {
    // Mukerrer talep destek kuyrugunda ikinci satir demek.
    final service = _FakeSupportTicketService(
      error: DioException(
        requestOptions: RequestOptions(path: '/support-tickets'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/support-tickets'),
          statusCode: 400,
          data: {'error': {'code': 'VALIDATION_ERROR'}},
        ),
      ),
    );

    final result = await SupportTicketRepository(service)
        .createTicket(subject: 'Kisa', message: 'Mesaj metni burada', category: 'OTHER');

    expect((_failure(result) as ServerFailure).code, 'VALIDATION_ERROR');
    expect(service.createCalls, 1);
  });

  test('listede yonetici yaniti ve tarihi tasinir, yanitlanmamista null', () async {
    final service = _FakeSupportTicketService(list: [_row('t1', reply: 'Hesabiniza eklendi'), _row('t2')]);

    final tickets = _data(await SupportTicketRepository(service).getMyTickets())!;

    expect(tickets.map((t) => t.id), ['t1', 't2']);
    expect(tickets[0].adminReply, 'Hesabiniza eklendi');
    expect(tickets[0].repliedAt, DateTime.utc(2026, 9, 10, 12));
    expect(tickets[1].adminReply, isNull);
    expect(tickets[1].repliedAt, isNull);
  });

  test('talep yoksa bos liste basarili yanittir', () async {
    final result = await SupportTicketRepository(_FakeSupportTicketService()).getMyTickets();

    expect(_data(result), isEmpty);
  });

  test('tek talep id ile getirilir', () async {
    final service = _FakeSupportTicketService(list: [_row('t1'), _row('t2', reply: 'Tamam')]);

    final ticket = _data(await SupportTicketRepository(service).getTicket('t2'));

    expect(ticket?.adminReply, 'Tamam');
  });

  test('bos/bozuk govde Result sozlesmesini bozmaz — UnknownFailure, throw yok', () async {
    // Servis govde yoksa `{}` donduruyor; fromJson zorunlu alanlarda
    // TypeError atar. Eskiden yalnizca DioException yakalaniyordu.
    final result = await SupportTicketRepository(_FakeSupportTicketService())
        .createTicket(subject: 'Odeme sorunu', message: 'Elmaslar gecmedi', category: 'BILLING');

    expect(_failure(result), isA<UnknownFailure>());
  });

  test('ag hatasi NetworkFailure', () async {
    final service = _FakeSupportTicketService(
      error: DioException(
        requestOptions: RequestOptions(path: '/support-tickets'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(_failure(await SupportTicketRepository(service).getMyTickets()), isA<NetworkFailure>());
  });
}
