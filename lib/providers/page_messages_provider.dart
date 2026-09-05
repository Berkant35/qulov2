import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class PageMessagesState {
  final List<PageMessageModel> messages;
  final Set<String> shownThisSession;
  const PageMessagesState({this.messages = const [], this.shownThisSession = const {}});

  PageMessagesState copyWith({List<PageMessageModel>? messages, Set<String>? shownThisSession}) =>
      PageMessagesState(
        messages: messages ?? this.messages,
        shownThisSession: shownThisSession ?? this.shownThisSession,
      );
}

class PageMessagesNotifier extends Notifier<PageMessagesState> {
  @override
  PageMessagesState build() => const PageMessagesState();

  Future<void> fetch() async {
    final result = await ref.read(pageMessageRepositoryProvider).getMessages();
    result.when(
      success: (list) => state = state.copyWith(messages: list),
      failure: (_) {}, // sessiz
    );
  }

  /// O sayfa için gösterilmeye uygun en yüksek priority mesaj (oturum-içi tekrar engeli).
  ///
  /// NOT — Frekans yönetimi iki katmanda:
  ///   • Kalıcı (once / daily / until_dismissed): SERVER tarafında `page_message_events`
  ///     tablosu + `passesFrequency()` servisi kontrol eder; zaten uygun olmayan mesajlar
  ///     API'den gelmez.
  ///   • Oturum-içi (`shownThisSession`): Aynı oturumda tekrar gösterimi engeller.
  ///     Bu yalnızca `every_visit` dışındaki mesajlar için geçerlidir.
  ///   Dolayısıyla `shownThisSession`'ın dolu olması "once kalıcı olarak kaydedildi" anlamına
  ///   GELMEZ — sadece bu oturumda zaten gösterildi demektir.
  PageMessageModel? consumeForPage(String page) {
    final candidates = state.messages.where((m) {
      if (m.page != page) return false;
      if (m.frequency != 'every_visit' && state.shownThisSession.contains(m.id)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return candidates.isEmpty ? null : candidates.first;
  }

  void markShown(String id) {
    state = state.copyWith(shownThisSession: {...state.shownThisSession, id});
    trackEvent(id, 'shown');
  }

  void trackEvent(String id, String event) {
    ref.read(pageMessageRepositoryProvider).trackEvent(id, event);
  }
}

final pageMessagesProvider =
    NotifierProvider<PageMessagesNotifier, PageMessagesState>(PageMessagesNotifier.new);
