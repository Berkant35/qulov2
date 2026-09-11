import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';
import 'package:qulo_v2/data/repositories/page_message_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/page_messages_provider.dart';

/// Sayfa mesajlari — backoffice'ten sayfaya banner/sheet.
///
/// Kalici frekans (once/daily/until_dismissed) SUNUCUDA; burada sadece
/// oturum-ici tekrar engeli test edilir (`every_visit` haric).
class _FakePageMessageRepository implements PageMessageRepository {
  _FakePageMessageRepository(this.result);

  Result<List<PageMessageModel>> result;
  final events = <String>[];

  @override
  Future<Result<List<PageMessageModel>>> getMessages() async => result;

  @override
  Future<void> trackEvent(String id, String event) async => events.add('$id:$event');
}

PageMessageModel _msg(
  String id, {
  String page = 'discover',
  String frequency = 'once',
  int priority = 0,
}) =>
    PageMessageModel(
      id: id,
      page: page,
      displayType: 'banner',
      content: const {'en': LocaleContent(title: 't', body: 'b')},
      frequency: frequency,
      priority: priority,
    );

Future<(PageMessagesNotifier, _FakePageMessageRepository)> _loaded(
  List<PageMessageModel> messages,
) async {
  final repo = _FakePageMessageRepository(Success(messages));
  final container = ProviderContainer(
    overrides: [pageMessageRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  final notifier = container.read(pageMessagesProvider.notifier);
  await notifier.fetch();
  return (notifier, repo);
}

void main() {
  test('yalnizca istenen sayfanin mesaji doner', () async {
    final (n, _) = await _loaded([_msg('a', page: 'matches'), _msg('b')]);

    expect(n.consumeForPage('discover')?.id, 'b');
    expect(n.consumeForPage('profile'), isNull);
  });

  test('en yuksek priority once gelir', () async {
    final (n, _) = await _loaded([
      _msg('low', priority: 1),
      _msg('high', priority: 5),
      _msg('mid', priority: 3),
    ]);

    expect(n.consumeForPage('discover')?.id, 'high');
  });

  for (final frequency in ['once', 'daily', 'until_dismissed']) {
    test('$frequency: gosterilen mesaj ayni oturumda tekrar donmez, siradaki gelir', () async {
      final (n, _) = await _loaded([
        _msg('first', frequency: frequency, priority: 2),
        _msg('second', frequency: frequency, priority: 1),
      ]);

      n.markShown('first');

      expect(n.consumeForPage('discover')?.id, 'second');
    });
  }

  test('every_visit gosterildikten sonra da doner', () async {
    final (n, _) = await _loaded([_msg('ev', frequency: 'every_visit')]);

    n.markShown('ev');

    expect(n.consumeForPage('discover')?.id, 'ev');
  });

  test('markShown sunucuya shown olayini gonderir', () async {
    final (n, repo) = await _loaded([_msg('a')]);

    n.markShown('a');
    n.trackEvent('a', 'clicked');

    expect(repo.events, ['a:shown', 'a:clicked']);
  });

  test('fetch hatasi sessiz — eldeki mesajlar korunur', () async {
    final (n, repo) = await _loaded([_msg('a')]);
    repo.result = const Failure(NetworkFailure());

    await n.fetch();

    expect(n.consumeForPage('discover')?.id, 'a');
  });

  test('mesaj yoksa null', () async {
    final (n, _) = await _loaded(const []);

    expect(n.consumeForPage('discover'), isNull);
  });
}
