import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/data/models/notification_preferences_model.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/diamond_repository.dart';
import 'package:qulo_v2/data/repositories/exchange_repository.dart';
import 'package:qulo_v2/data/repositories/question_repository.dart';
import 'package:qulo_v2/data/repositories/rewards_repository.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';

/// Provider testleri icin bellek-ici repository'ler. Servis/ag yok; testler
/// gercek notifier kodunu calistirir, yalnizca veri kaynagi sahtedir.
///
/// Stil farki bilincli: `UserRepository` 21 metot → sadece kullanilan yazilir,
/// gerisi `noSuchMethod` ile patlar; `ExchangeRepository` 4 metot → hepsi acik.

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.user, {this.prefsFailure, this.reorderFailure});

  /// Testler getMe'nin sonraki yanıtını değiştirebilsin diye atanabilir.
  UserModel user;
  final AppFailure? prefsFailure;
  final AppFailure? reorderFailure;

  int getMeCallCount = 0;
  int prefsCallCount = 0;
  int reorderPhotosCallCount = 0;
  Map<String, dynamic>? lastPrefsBody;
  AppFailure? prefConsentFailure;
  final List<({String status, String? genderPref})> prefConsentCalls = [];

  @override
  Future<Result<void>> setPrefConsent({required String status, String? genderPref}) async {
    prefConsentCalls.add((status: status, genderPref: genderPref));
    final failure = prefConsentFailure;
    return failure == null ? const Success(null) : Failure(failure);
  }

  IdentityModel identity = IdentityModel.empty;
  AppFailure? identityFailure;
  AppFailure? identityGetFailure;

  /// Doluysa `saveIdentity` bu tamamlanana kadar bekler (kaydederken arayüz durumu testi).
  Completer<void>? identitySaveGate;
  final List<({IdentityModel identity, bool consent})> identityCalls = [];

  /// `getIdentity` çağrı sayısı (maliyet koruması testi) ve doluysa tamamlanana kadar bekletme.
  int identityGetCount = 0;
  Completer<void>? identityGetGate;

  @override
  Future<Result<IdentityModel>> getIdentity() async {
    identityGetCount++;
    await identityGetGate?.future;
    final failure = identityGetFailure;
    return failure != null ? Failure(failure) : Success(identity);
  }

  @override
  Future<Result<IdentityModel>> saveIdentity(IdentityModel next, {required bool consent}) async {
    identityCalls.add((identity: next, consent: consent));
    await identitySaveGate?.future;
    final failure = identityFailure;
    if (failure != null) return Failure(failure);
    identity = next;
    return Success(next);
  }

  @override
  Future<Result<UserModel>> getMe() async {
    getMeCallCount++;
    return Success(user);
  }

  /// Doluysa `reorderPhotos` bu tamamlanana kadar bekler (istek surerken ekran kapanir).
  Completer<void>? reorderGate;

  /// Gercek `PATCH /users/me` yaniti gibi: yalniz profil alanlari doner, getMe'ye
  /// ozel alanlar (`rainbow_diamonds`, `rainbow_enabled`, bakiyeler) YOK.
  @override
  Future<Result<UserModel>> reorderPhotos(List<String> photos) async {
    reorderPhotosCallCount++;
    await reorderGate?.future;
    if (reorderFailure != null) return Failure(reorderFailure!);
    return Success(UserModel(id: user.id, email: user.email, photos: photos));
  }

  /// Fotograf yukleme/silme ve profil kaydi: doluysa kapi tamamlanana kadar
  /// bekler. Sunucu gibi `user` guncellenir; sonraki `getMe` yeni durumu doner.
  Completer<void>? photoUploadGate;
  Completer<void>? photoDeleteGate;
  Completer<void>? profileSaveGate;
  int uploadPhotoCount = 0;
  final List<int> deletedPhotoIndexes = [];

  @override
  Future<Result<Map<String, dynamic>>> uploadPhoto(Uint8List bytes, String mimeType) async {
    uploadPhotoCount++;
    await photoUploadGate?.future;
    user = _patched({'photos': [...?user.photos, 'https://cdn.test/new-$uploadPhotoCount.jpg']});
    return const Success({});
  }

  @override
  Future<Result<Map<String, dynamic>>> deletePhoto(int index) async {
    deletedPhotoIndexes.add(index);
    await photoDeleteGate?.future;
    user = _patched({'photos': [...?user.photos]..removeAt(index)});
    return const Success({});
  }

  @override
  Future<Result<UserModel>> updateProfile(Map<String, dynamic> data) async {
    await profileSaveGate?.future;
    user = _patched(data);
    return Success(user);
  }

  /// `updateLocation` cagrilari (lat, lng); sunucu gibi `user.city` [locationCity] olur.
  final List<(double, double)> locationUpdates = [];
  String? locationCity;

  @override
  Future<Result<void>> updateLocation({
    required double lat,
    required double lng,
    String? city,
    String? country,
  }) async {
    locationUpdates.add((lat, lng));
    if (locationCity != null) user = _patched({'city': locationCity});
    return const Success(null);
  }

  @override
  Future<Result<UserDetailsModel>> updateDetails(Map<String, dynamic> data) async =>
      Success(user.details ?? const UserDetailsModel());

  /// JSON round-trip ile alan yamasi (`UserModel`'de elle copyWith yok).
  UserModel _patched(Map<String, dynamic> patch) {
    final json = jsonDecode(jsonEncode(user)) as Map<String, dynamic>;
    return UserModel.fromJson(json..addAll(patch));
  }

  @override
  Future<Result<NotificationPreferencesModel>> updateNotificationPreferences(
    Map<String, dynamic> body,
  ) async {
    prefsCallCount++;
    lastPrefsBody = body;
    if (prefsFailure != null) return Failure(prefsFailure!);
    return const Success(NotificationPreferencesModel());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeUserRepository.${invocation.memberName}');
}

/// Hata alanlari degistirilebilir: once basarili yukleyip sonra hataya gecerek
/// "hata onceki veriyi silmez" davranisi sinanir. Cagri sayaclari satin alma
/// sonrasi tazelemenin YALNIZCA basarida yapildigini dogrular.
class FakeExchangeRepository implements ExchangeRepository {
  FakeExchangeRepository({
    this.inventory = const [],
    this.rates = const RatesResponse(convertRatio: 3, powers: []),
    this.inventoryFailure,
    this.ratesFailure,
    this.convertFailure,
    this.buyPowerFailure,
    this.buyPowerBalance = const DiamondBalance(green: 0, purple: 0),
  });

  List<PowerInventoryItem> inventory;
  RatesResponse rates;
  AppFailure? inventoryFailure;
  AppFailure? ratesFailure;
  final AppFailure? convertFailure;
  final AppFailure? buyPowerFailure;
  final DiamondBalance buyPowerBalance;

  int getInventoryCallCount = 0;
  int convertCallCount = 0;
  int buyPowerCallCount = 0;
  String? lastBuyDiamondType;

  @override
  Future<Result<InventoryResponse>> getInventory() async {
    getInventoryCallCount++;
    if (inventoryFailure != null) return Failure(inventoryFailure!);
    return Success(InventoryResponse(inventory: inventory));
  }

  @override
  Future<Result<RatesResponse>> getRates() async {
    if (ratesFailure != null) return Failure(ratesFailure!);
    return Success(rates);
  }

  @override
  Future<Result<ConvertResponse>> convert(int greenAmount) async {
    convertCallCount++;
    if (convertFailure != null) return Failure(convertFailure!);
    final purple = greenAmount ~/ rates.convertRatio;
    return Success(ConvertResponse(
      purpleReceived: purple,
      newBalance: DiamondBalance(green: 0, purple: purple),
    ));
  }

  @override
  Future<Result<BuyPowerResponse>> buyPower(
    String powerName,
    String diamondType,
    int quantity,
  ) async {
    buyPowerCallCount++;
    lastBuyDiamondType = diamondType;
    if (buyPowerFailure != null) return Failure(buyPowerFailure!);
    return Success(BuyPowerResponse(newCount: quantity, newBalance: buyPowerBalance));
  }
}

/// Elmas repository'si — 3 metot, hepsi acik yazildi (ExchangeRepository stili).
///
/// Cagri sayaclari var: para yolunda "kac kere cagrildi" bir davranis
/// sorusudur, bakiye tazeleme yalnizca basarili satin almadan sonra olmali.
class FakeDiamondRepository implements DiamondRepository {
  FakeDiamondRepository({
    DiamondBalance? balance,
    this.balanceFailure,
    this.purchaseFailure,
  }) : balance = balance ?? const DiamondBalance(green: 0, purple: 0);

  DiamondBalance balance;
  final AppFailure? balanceFailure;
  final AppFailure? purchaseFailure;

  int getBalanceCallCount = 0;
  int purchaseCallCount = 0;
  String? lastPurchasedProductId;
  String? lastTransactionId;

  @override
  Future<Result<DiamondBalance>> getBalance() async {
    getBalanceCallCount++;
    if (balanceFailure != null) return Failure(balanceFailure!);
    return Success(balance);
  }

  @override
  Future<Result<DiamondHistoryResponse>> getHistory({int page = 1, int limit = 20}) async =>
      Success(DiamondHistoryResponse(items: const [], total: 0, page: page, limit: limit));

  @override
  Future<Result<void>> purchase(String iapProductId, {String? transactionId}) async {
    purchaseCallCount++;
    lastPurchasedProductId = iapProductId;
    lastTransactionId = transactionId;
    if (purchaseFailure != null) return Failure(purchaseFailure!);
    return const Success(null);
  }
}

/// Soru repository'si — 9 metot; yalnizca `getMyQuestions`, `reorderQuestions`,
/// `getAiSuggestions` ve `createQuestion` acik (UserRepository stili, gerisi
/// noSuchMethod ile patlar).
///
/// `reorderCompleter` verilirse `reorderQuestions` onu bekler: iyimser
/// guncellemenin sunucu cevabindan ONCE gorundugunu test edebilmek icin.
/// `createFailures`: 0 tabanli cagri sirasi → o cagrida donecek hata.
class FakeQuestionRepository implements QuestionRepository {
  FakeQuestionRepository({
    this.questions = const [],
    this.listFailure,
    this.reorderFailure,
    this.reorderResponse,
    this.reorderCompleter,
    this.aiResponse = const {},
    this.aiFailure,
    this.createFailures = const {},
  });

  final List<QuestionModel> questions;
  final AppFailure? listFailure;
  final AppFailure? reorderFailure;
  final List<QuestionModel>? reorderResponse;
  final Completer<void>? reorderCompleter;
  final Map<String, dynamic> aiResponse;
  final AppFailure? aiFailure;
  final Map<int, AppFailure> createFailures;

  int reorderCallCount = 0;
  List<String>? lastOrderedIds;
  Map<String, dynamic>? lastAiBody;
  int createCallCount = 0;

  /// Basariyla kaydedilen soru govdeleri, cagri sirasiyla.
  final List<Map<String, dynamic>> createdBodies = [];

  /// Doluysa `createQuestion` bu tamamlanana kadar bekler (kayit surerken ekran kapanir).
  Completer<void>? createGate;
  final List<int> deletedOrderNums = [];

  @override
  Future<Result<void>> deleteQuestion(int orderNum) async {
    deletedOrderNums.add(orderNum);
    return const Success(null);
  }

  @override
  Future<Result<QuestionModel>> createQuestion(Map<String, dynamic> data) async {
    final call = createCallCount++;
    await createGate?.future;
    final failure = createFailures[call];
    if (failure != null) return Failure(failure);
    createdBodies.add(data);
    return Success(QuestionModel(
      id: 'created_$call',
      userId: 'u1',
      orderNum: data['order_num'] as int,
      questionText: data['question_text'] as String,
      correctAnswer: data['correct_answer'] as int,
      answer1: data['answer_1'] as String,
      answer2: data['answer_2'] as String,
      answer3: data['answer_3'] as String,
      answer4: data['answer_4'] as String,
    ));
  }

  @override
  Future<Result<Map<String, dynamic>>> getAiSuggestions(Map<String, dynamic> body) async {
    lastAiBody = body;
    if (aiFailure != null) return Failure(aiFailure!);
    return Success(aiResponse);
  }

  @override
  Future<Result<List<QuestionModel>>> getMyQuestions() async {
    if (listFailure != null) return Failure(listFailure!);
    return Success(questions);
  }

  @override
  Future<Result<List<QuestionModel>>> reorderQuestions(List<String> orderedIds) async {
    reorderCallCount++;
    lastOrderedIds = orderedIds;
    if (reorderCompleter != null) await reorderCompleter!.future;
    if (reorderFailure != null) return Failure(reorderFailure!);
    final byId = {for (final q in questions) q.id: q};
    return Success(reorderResponse ?? [for (final id in orderedIds) if (byId[id] != null) byId[id]!]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeQuestionRepository.${invocation.memberName}');
}

/// Market sahte repository'si: sonuçlar kurucudan, çağrılar sayaçlarda.
class FakeRewardsRepository implements RewardsRepository {
  FakeRewardsRepository({
    this.market,
    this.marketFailure,
    this.redeemResult,
    this.redeemFailure,
    this.redemptionPages = const {},
    this.redemptionsFailure,
    this.eventsFailure,
  });

  MarketView? market;
  AppFailure? marketFailure;
  RedeemResult? redeemResult;
  AppFailure? redeemFailure;
  Map<int, RedemptionPage> redemptionPages;
  AppFailure? redemptionsFailure;
  AppFailure? eventsFailure;

  final marketCountries = <String?>[];
  final redeemCalls = <({String itemId, String idempotencyKey, String? sourceItemId})>[];
  final redemptionPagesRequested = <int>[];
  final sentEventBatches = <List<SectionEvent>>[];

  /// Doluysa redeem bu tamamlanana kadar bekler (tek uçuş testi).
  Completer<void>? redeemGate;

  /// Doluysa getMarket bu tamamlanana kadar bekler (ekran kapanırken yükleme sürüyor testi).
  Completer<void>? marketGate;

  /// Doluysa getRedemptions bu tamamlanana kadar bekler (refresh sırasında önceki liste korunuyor testi).
  Completer<void>? redemptionsGate;

  @override
  Future<Result<MarketView>> getMarket({String? country}) async {
    marketCountries.add(country);
    if (marketGate != null) await marketGate!.future;
    if (marketFailure != null) return Failure(marketFailure!);
    return Success(market ?? const MarketView(balance: 0, items: [], monthlyCap: null, usedThisMonth: 0));
  }

  @override
  Future<Result<RedeemResult>> redeem({
    required String itemId,
    required String idempotencyKey,
    String? sourceItemId,
  }) async {
    redeemCalls.add((itemId: itemId, idempotencyKey: idempotencyKey, sourceItemId: sourceItemId));
    if (redeemGate != null) await redeemGate!.future;
    if (redeemFailure != null) return Failure(redeemFailure!);
    return Success(redeemResult!);
  }

  @override
  Future<Result<RedemptionPage>> getRedemptions({int page = 1, int limit = 20}) async {
    redemptionPagesRequested.add(page);
    if (redemptionsGate != null) await redemptionsGate!.future;
    if (redemptionsFailure != null) return Failure(redemptionsFailure!);
    return Success(redemptionPages[page] ?? RedemptionPage(items: const [], total: 0, page: page, limit: limit));
  }

  @override
  Future<Result<void>> sendEvents(List<SectionEvent> events) async {
    sentEventBatches.add(List.of(events));
    if (eventsFailure != null) return Failure(eventsFailure!);
    return const Success(null);
  }
}
