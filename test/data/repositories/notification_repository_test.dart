import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/notification_service.dart';
import 'package:qulo_v2/data/repositories/notification_repository.dart';

/// Bildirim kutusu. Sunucu sozlesmesi (qulo-server
/// `notification-api.service.ts` / `notification.controller.ts`):
/// liste `{notifications, total}`, okunmamis sayisi **camelCase**
/// `{unreadCount}` (istek/satir alanlari snake_case).
class _FakeNotificationService implements NotificationRetrofitService {
  _FakeNotificationService({this.listResponse, this.unreadResponse, this.error});

  final dynamic listResponse;
  final dynamic unreadResponse;
  final DioException? error;

  (int, int)? lastPage;
  final calls = <String>[];

  @override
  Future<dynamic> getNotifications(int page, int limit) async {
    lastPage = (page, limit);
    if (error != null) throw error!;
    return listResponse;
  }

  @override
  Future<dynamic> getUnreadCount() async {
    if (error != null) throw error!;
    return unreadResponse;
  }

  @override
  Future<void> markAsRead(String id) async {
    calls.add('read:$id');
    if (error != null) throw error!;
  }

  @override
  Future<void> markAllAsRead() async {
    calls.add('readAll');
    if (error != null) throw error!;
  }

  @override
  Future<void> trackClick(String id) async {
    calls.add('click:$id');
    if (error != null) throw error!;
  }
}

Map<String, dynamic> _raw(String id, {bool? isRead}) => {
      'id': id,
      'user_id': 'u1',
      'type': 'new_match',
      'title': 'Yeni eslesme',
      'body': 'Ayse ile eslestin',
      'action_url': '/matches',
      if (isRead != null) 'is_read': isRead,
      'created_at': '2026-09-10T12:00:00Z',
    };

DioException _offline() => DioException(
      requestOptions: RequestOptions(path: '/notifications'),
      type: DioExceptionType.connectionError,
    );

T? _data<T>(Result<T> r) => r.when(success: (d) => d, failure: (_) => null);
AppFailure? _failure<T>(Result<T> r) => r.when(success: (_) => null, failure: (f) => f);

void main() {
  group('getNotifications', () {
    test('sayfalama servise gider, liste modele parse edilir', () async {
      final service = _FakeNotificationService(listResponse: {
        'notifications': [_raw('n1', isRead: true), _raw('n2')],
        'total': 2,
      });

      final list = _data(await NotificationRepository(service).getNotifications(2, 20))!;

      expect(service.lastPage, (2, 20));
      expect(list.map((n) => n.id), ['n1', 'n2']);
      expect(list.first.actionUrl, '/matches');
      expect(list.first.isRead, isTrue);
    });

    test('is_read yoksa okunmamis sayilir', () async {
      final service = _FakeNotificationService(listResponse: {'notifications': [_raw('n1')]});

      final list = _data(await NotificationRepository(service).getNotifications(1, 20))!;

      expect(list.single.isRead, isFalse);
    });

    for (final response in <dynamic>[{}, {'notifications': null}, {'notifications': {}}]) {
      test('notifications liste degilse bos basarili yanit: $response', () async {
        final result =
            await NotificationRepository(_FakeNotificationService(listResponse: response)).getNotifications(1, 20);

        expect(_data(result), isEmpty);
      });
    }

    test('Map olmayan ogeler atlanir', () async {
      final service = _FakeNotificationService(listResponse: {
        'notifications': ['x', null, _raw('n1')],
      });

      final list = _data(await NotificationRepository(service).getNotifications(1, 20))!;

      expect(list.map((n) => n.id), ['n1']);
    });

    test('bozuk oge Result sozlesmesini bozmaz — UnknownFailure, throw yok', () async {
      // Zorunlu `title` eksik → fromJson TypeError. Eskiden yalnizca
      // DioException yakalaniyordu; hata cagirana sizardi.
      final broken = _raw('n1')..remove('title');
      final service = _FakeNotificationService(listResponse: {'notifications': [broken]});

      final result = await NotificationRepository(service).getNotifications(1, 20);

      expect(_failure(result), isA<UnknownFailure>());
    });

    test('ag hatasi NetworkFailure', () async {
      final result =
          await NotificationRepository(_FakeNotificationService(error: _offline())).getNotifications(1, 20);

      expect(_failure(result), isA<NetworkFailure>());
    });
  });

  group('getUnreadCount', () {
    test('camelCase unreadCount okunur', () async {
      final result = await NotificationRepository(
        _FakeNotificationService(unreadResponse: {'unreadCount': 7}),
      ).getUnreadCount();

      expect(_data(result), 7);
    });

    test('sayi ondalikli gelse de tam sayiya cevrilir', () async {
      final result = await NotificationRepository(
        _FakeNotificationService(unreadResponse: {'unreadCount': 3.0}),
      ).getUnreadCount();

      expect(_data(result), 3);
    });

    test('alan yoksa 0 — snake_case anahtar sessizce 0 okunur (sozlesme camelCase)', () async {
      final result = await NotificationRepository(
        _FakeNotificationService(unreadResponse: {'unread_count': 5}),
      ).getUnreadCount();

      expect(_data(result), 0);
    });

    test('govde Map degilse UnknownFailure, throw yok', () async {
      final result =
          await NotificationRepository(_FakeNotificationService(unreadResponse: null)).getUnreadCount();

      expect(_failure(result), isA<UnknownFailure>());
    });
  });

  group('okundu / tiklama', () {
    test('dogru bildirim kimligiyle gider', () async {
      final service = _FakeNotificationService();
      final repo = NotificationRepository(service);

      await repo.markAsRead('n1');
      await repo.markAllAsRead();
      await repo.trackClick('n2');

      expect(service.calls, ['read:n1', 'readAll', 'click:n2']);
    });

    test('ag hatasi Failure olur', () async {
      final repo = NotificationRepository(_FakeNotificationService(error: _offline()));

      expect((await repo.markAsRead('n1')).isFailure, isTrue);
      expect((await repo.markAllAsRead()).isFailure, isTrue);
      expect((await repo.trackClick('n1')).isFailure, isTrue);
    });
  });
}
