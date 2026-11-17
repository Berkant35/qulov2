import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/app_review_manager.dart';

// Diskteki sözleşme: sessiz bir yeniden adlandırma kullanıcı sayaçlarını
// sıfırlar, testin bunu yakalaması istenir — bilerek ham string.
const _kShownCount = 'qulo_app_review_shown_count';
const _kLastShown = 'qulo_app_review_last_shown';
const _kCompleted = 'qulo_app_review_completed';
const _kSentMessages = 'qulo_app_review_sent_messages';
const _kPendingSince = 'qulo_app_review_pending_since';
const _kFirstActiveDay = 'qulo_app_review_first_active_day';
const _kQuizCompleted = 'qulo_app_review_quiz_completed';
const _kSecondDayDone = 'qulo_app_review_second_day_done';

class _FakeReviewClient implements ReviewPromptClient {
  bool available = true;
  bool throwOnRequest = false;
  int requests = 0;
  String? openedAppStoreId;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    if (throwOnRequest) throw StateError('unavailable');
    requests++;
  }

  @override
  Future<void> openStoreListing({String? appStoreId}) async =>
      openedAppStoreId = appStoreId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeReviewClient client;
  late AppReviewManager manager;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = _FakeReviewClient();
    manager = AppReviewManager.withClient(client);
  });

  String isoAgo(Duration d) => DateTime.now().subtract(d).toIso8601String();
  String isoPastDue() =>
      isoAgo(AppReviewManager.returnDelay + const Duration(minutes: 1));

  Future<void> sendMessages(int n) async {
    for (var i = 0; i < n; i++) {
      await manager.onMessageSent();
    }
  }

  group('chat_engaged', () {
    test('eşik altı mesaj istem açmaz, eşikte tam bir kez açar', () async {
      await sendMessages(AppReviewManager.chatEngagedThreshold - 1);
      expect(client.requests, 0);

      await sendMessages(1);
      expect(client.requests, 1);
    });

    test('gösterildikten sonra soğuma kalksa da tekrar tetiklemez', () async {
      await sendMessages(AppReviewManager.chatEngagedThreshold);
      expect(client.requests, 1);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastShown);
      await sendMessages(3);
      expect(client.requests, 1, reason: 'bitti bayrağı korur, soğuma değil');
    });

    test('eşikte soğuma engellediyse sonraki mesajda yeniden denenir',
        () async {
      SharedPreferences.setMockInitialValues({
        _kLastShown: isoAgo(const Duration(days: 1)),
        _kShownCount: 1,
      });
      await sendMessages(AppReviewManager.chatEngagedThreshold);
      expect(client.requests, 0);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastShown);
      await sendMessages(1);
      expect(client.requests, 1);
    });

    test('sayaç kalıcıdır — uygulama yeniden açılsa da eşik bir kez sayılır',
        () async {
      SharedPreferences.setMockInitialValues({
        _kSentMessages: AppReviewManager.chatEngagedThreshold - 1,
      });
      await sendMessages(1);
      expect(client.requests, 1);
    });

    test('platform istem sunamıyorsa hiç açmaz ama sayaç ilerler', () async {
      client.available = false;
      await sendMessages(AppReviewManager.chatEngagedThreshold);
      expect(client.requests, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(_kSentMessages),
        AppReviewManager.chatEngagedThreshold,
      );
    });
  });

  group('return_after_first_match', () {
    test('ilk eşleşme anında işaretlenir ama süre dolmadan sorulmaz',
        () async {
      await manager.markPendingReturnReview();
      expect(await manager.isReturnReviewDue(), isFalse);
      await manager.tryShowPendingReturnReview();
      expect(client.requests, 0);
    });

    test('süre dolunca sorulur ve bekleyen kayıt silinir', () async {
      SharedPreferences.setMockInitialValues({_kPendingSince: isoPastDue()});
      expect(await manager.isReturnReviewDue(), isTrue);

      await manager.tryShowPendingReturnReview();
      expect(client.requests, 1);
      expect(await manager.isReturnReviewDue(), isFalse);

      await manager.tryShowPendingReturnReview();
      expect(client.requests, 1, reason: 'ikinci çağrı tekrar sormaz');
    });

    test('soğuma engellediyse bekleyen kayıt korunur, sonra sorulur', () async {
      SharedPreferences.setMockInitialValues({
        _kPendingSince: isoPastDue(),
        _kLastShown: isoAgo(const Duration(days: 1)),
        _kShownCount: 1,
      });
      await manager.tryShowPendingReturnReview();
      expect(client.requests, 0);
      expect(await manager.isReturnReviewDue(), isTrue,
          reason: 'sorulmadıysa kayıt silinmez');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastShown);
      await manager.tryShowPendingReturnReview();
      expect(client.requests, 1);
      expect(await manager.isReturnReviewDue(), isFalse);
    });

    test('üst sınıra ulaşıldıysa bekleyen kayıt sorulmadan silinir', () async {
      SharedPreferences.setMockInitialValues({
        _kPendingSince: isoPastDue(),
        _kShownCount: 3,
      });
      await manager.tryShowPendingReturnReview();
      expect(client.requests, 0);
      expect(await manager.isReturnReviewDue(), isFalse,
          reason: 'kalıcı kapalı halde her kaydırmada denenmesin');
    });

    test('bekleyen kayıt varken tekrar işaretlemek süreyi sıfırlamaz',
        () async {
      final old = isoPastDue();
      SharedPreferences.setMockInitialValues({_kPendingSince: old});
      await manager.markPendingReturnReview();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_kPendingSince), old);
    });
  });

  group('second_day_return', () {
    String dayKey(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    String yesterday() =>
        dayKey(DateTime.now().subtract(const Duration(days: 1)));

    test('noteActiveDay bugünü yazar, ikinci çağrıda günü değiştirmez',
        () async {
      await manager.noteActiveDay();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_kFirstActiveDay), dayKey(DateTime.now()));

      await prefs.setString(_kFirstActiveDay, '2020-01-01');
      await manager.noteActiveDay();
      expect(prefs.getString(_kFirstActiveDay), '2020-01-01');
    });

    test('noteQuizCompleted kalıcı işaret yazar', () async {
      await manager.noteQuizCompleted();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_kQuizCompleted), isTrue);
    });

    test('noteQuizCompleted ilk aktif günü de yazar, var olanı değiştirmez',
        () async {
      await manager.noteQuizCompleted();
      final prefs = await SharedPreferences.getInstance();
      final today = prefs.getString(_kFirstActiveDay);
      expect(today, isNotNull);
      expect(await manager.isSecondDayReviewDue(), isFalse);

      await prefs.setString(_kFirstActiveDay, '2000-01-01');
      await manager.noteQuizCompleted();
      expect(prefs.getString(_kFirstActiveDay), '2000-01-01');
      expect(await manager.isSecondDayReviewDue(), isTrue);
    });

    test('aynı gün (quiz tamamlanmış olsa da) due değil, istek yok', () async {
      await manager.noteActiveDay();
      await manager.noteQuizCompleted();
      expect(await manager.isSecondDayReviewDue(), isFalse);
      await manager.tryShowSecondDayReview();
      expect(client.requests, 0);
    });

    test('ilk aktif gün kayıtlı değilse due değil', () async {
      SharedPreferences.setMockInitialValues({_kQuizCompleted: true});
      expect(await manager.isSecondDayReviewDue(), isFalse);
    });

    test('ertesi gün + quiz tamamlanmış: due, istek yapılır, bir kez sorulur',
        () async {
      SharedPreferences.setMockInitialValues({
        _kFirstActiveDay: yesterday(),
        _kQuizCompleted: true,
      });
      expect(await manager.isSecondDayReviewDue(), isTrue);

      await manager.tryShowSecondDayReview();
      expect(client.requests, 1);
      expect(await manager.isSecondDayReviewDue(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastShown);
      await manager.tryShowSecondDayReview();
      expect(client.requests, 1, reason: 'yapıldı işareti tekrarı engeller');
    });

    test('ertesi gün ama quiz tamamlanmamış: istek yok', () async {
      SharedPreferences.setMockInitialValues({_kFirstActiveDay: yesterday()});
      expect(await manager.isSecondDayReviewDue(), isFalse);
      await manager.tryShowSecondDayReview();
      expect(client.requests, 0);
    });

    test('soğuma engellediyse işaret yazılmaz, soğuma bitince sorulur',
        () async {
      SharedPreferences.setMockInitialValues({
        _kFirstActiveDay: yesterday(),
        _kQuizCompleted: true,
        _kLastShown: isoAgo(const Duration(days: 1)),
        _kShownCount: 1,
      });
      await manager.tryShowSecondDayReview();
      expect(client.requests, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_kSecondDayDone), isNull);
      expect(await manager.isSecondDayReviewDue(), isTrue);

      await prefs.remove(_kLastShown);
      await manager.tryShowSecondDayReview();
      expect(client.requests, 1);
      expect(await manager.isSecondDayReviewDue(), isFalse);
    });

    test('ömür boyu sınır dolmuşsa sorulmaz, kalıcı kapanır', () async {
      SharedPreferences.setMockInitialValues({
        _kFirstActiveDay: yesterday(),
        _kQuizCompleted: true,
        _kShownCount: 3,
      });
      await manager.tryShowSecondDayReview();
      expect(client.requests, 0);
      expect(await manager.isSecondDayReviewDue(), isFalse,
          reason: 'kalıcı kapalı halde her ekranda denenmesin');
    });

    test('sistem isteği fırlatırsa hak ve işaret yazılmaz', () async {
      SharedPreferences.setMockInitialValues({
        _kFirstActiveDay: yesterday(),
        _kQuizCompleted: true,
      });
      client.throwOnRequest = true;
      await manager.tryShowSecondDayReview();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_kShownCount), isNull);
      expect(await manager.isSecondDayReviewDue(), isTrue);
    });
  });

  group('soğuma ve üst sınır', () {
    test('14 gün içinde ikinci tetikleyici sorulmaz', () async {
      expect(await manager.tryShowReview(trigger: 'a'), isTrue);
      expect(await manager.tryShowReview(trigger: 'b'), isFalse);
      expect(client.requests, 1);
    });

    test('14 gün geçince tekrar sorulur', () async {
      SharedPreferences.setMockInitialValues({
        _kLastShown: isoAgo(const Duration(days: 15)),
        _kShownCount: 1,
      });
      expect(await manager.tryShowReview(trigger: 'a'), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_kShownCount), 2);
    });

    test('üç istemden sonra tamamlandı sayılır, bir daha sorulmaz', () async {
      SharedPreferences.setMockInitialValues({_kShownCount: 3});
      expect(await manager.tryShowReview(trigger: 'a'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_kCompleted), isTrue);
      expect(client.requests, 0);
    });

    test('sistem isteği fırlatırsa hak yanmaz: sayaç, soğuma ve bekleyen kayıt kalır',
        () async {
      SharedPreferences.setMockInitialValues({_kPendingSince: isoPastDue()});
      client.throwOnRequest = true;

      expect(await manager.tryShowReview(trigger: 'a'), isFalse);
      await manager.tryShowPendingReturnReview();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_kShownCount), isNull);
      expect(prefs.getString(_kLastShown), isNull);
      expect(await manager.isReturnReviewDue(), isTrue);
    });
  });

  test('Ayarlar isteği doğrudan mağaza sayfasını açar', () async {
    await manager.requestReviewFromSettings();
    expect(client.openedAppStoreId, '1626734572');
    expect(client.requests, 0);
  });
}
