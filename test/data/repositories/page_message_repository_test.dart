import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/page_message_service.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';
import 'package:qulo_v2/data/repositories/page_message_repository.dart';

/// Sayfa mesaji repository'si. Sozlesme: yanit `{messages: [...]}`, olay
/// takibi best-effort (hata UI akisini kesmez).
class _FakePageMessageService implements PageMessageRetrofitService {
  _FakePageMessageService({this.response, this.error});

  final dynamic response;
  final DioException? error;

  String? lastEventId;
  Map<String, dynamic>? lastEventBody;

  @override
  Future<dynamic> getMessages() async {
    if (error != null) throw error!;
    return response;
  }

  @override
  Future<void> trackEvent(String id, Map<String, dynamic> body) async {
    lastEventId = id;
    lastEventBody = body;
    if (error != null) throw error!;
  }
}

Map<String, dynamic> _raw(String id) => {
      'id': id,
      'page': 'discover',
      'display_type': 'banner',
      'content': {
        'en': {'title': 'Hello', 'body': 'Body', 'cta_label': 'Go'},
      },
      'action_url': '/discover',
      'frequency': 'once',
      'priority': 2,
    };

void main() {
  test('liste modele parse edilir', () async {
    final repo = PageMessageRepository(
      _FakePageMessageService(response: {'messages': [_raw('m1')]}),
    );

    final list = (await repo.getMessages())
        .when(success: (l) => l, failure: (_) => <PageMessageModel>[]);

    expect(list.single.id, 'm1');
    expect(list.single.actionUrl, '/discover');
    expect(list.single.priority, 2);
    expect(list.single.localized('en').ctaLabel, 'Go');
  });

  for (final response in <dynamic>[{}, {'messages': null}, {'messages': {}}]) {
    test('messages liste degilse bos basarili yanit: $response', () async {
      final result =
          await PageMessageRepository(_FakePageMessageService(response: response)).getMessages();

      expect(result.when(success: (l) => l, failure: (_) => null), isEmpty);
    });
  }

  test('Map olmayan ogeler atlanir', () async {
    final repo = PageMessageRepository(
      _FakePageMessageService(response: {'messages': ['x', 3, _raw('m1')]}),
    );

    final result = await repo.getMessages();

    expect(result.when(success: (l) => l.map((m) => m.id), failure: (_) => null), ['m1']);
  });

  test('bozuk oge Result sozlesmesini bozmaz — UnknownFailure, throw yok', () async {
    // Zorunlu `page` alani eksik → fromJson TypeError. Eskiden yalnizca
    // DioException yakalaniyordu; hata `fetch()`'ten yukari sizardi.
    final broken = _raw('m1')..remove('page');
    final repo = PageMessageRepository(
      _FakePageMessageService(response: {'messages': [broken]}),
    );

    final result = await repo.getMessages();

    expect(result.when(success: (_) => null, failure: (f) => f), isA<UnknownFailure>());
  });

  test('ag hatasi NetworkFailure', () async {
    final repo = PageMessageRepository(_FakePageMessageService(
      error: DioException(
        requestOptions: RequestOptions(path: '/page-messages'),
        type: DioExceptionType.connectionError,
      ),
    ));

    final result = await repo.getMessages();

    expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
  });

  test('trackEvent govdesi {event} ve id ile gider', () async {
    final service = _FakePageMessageService();

    await PageMessageRepository(service).trackEvent('m1', 'clicked');

    expect(service.lastEventId, 'm1');
    expect(service.lastEventBody, {'event': 'clicked'});
  });

  test('trackEvent ag hatasini yutar — banner/sheet akisi kesilmez', () async {
    final service = _FakePageMessageService(
      error: DioException(
        requestOptions: RequestOptions(path: '/page-messages/m1/event'),
        type: DioExceptionType.connectionError,
      ),
    );

    await expectLater(PageMessageRepository(service).trackEvent('m1', 'shown'), completes);
  });
}
