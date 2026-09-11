import 'dart:async';

import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/models/notification_preferences_model.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/diamond_repository.dart';
import 'package:qulo_v2/data/repositories/exchange_repository.dart';
import 'package:qulo_v2/data/repositories/question_repository.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';

/// Provider testleri icin bellek-ici repository'ler. Servis/ag yok; testler
/// gercek notifier kodunu calistirir, yalnizca veri kaynagi sahtedir.
///
/// Stil farki bilincli: `UserRepository` 21 metot → sadece kullanilan yazilir,
/// gerisi `noSuchMethod` ile patlar; `ExchangeRepository` 4 metot → hepsi acik.

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.user, {this.prefsFailure});

  final UserModel user;
  final AppFailure? prefsFailure;

  int getMeCallCount = 0;
  int prefsCallCount = 0;
  Map<String, dynamic>? lastPrefsBody;

  @override
  Future<Result<UserModel>> getMe() async {
    getMeCallCount++;
    return Success(user);
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
  });

  List<PowerInventoryItem> inventory;
  RatesResponse rates;
  AppFailure? inventoryFailure;
  AppFailure? ratesFailure;
  final AppFailure? convertFailure;
  final AppFailure? buyPowerFailure;

  int getInventoryCallCount = 0;
  int convertCallCount = 0;
  int buyPowerCallCount = 0;

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
    if (buyPowerFailure != null) return Failure(buyPowerFailure!);
    return Success(BuyPowerResponse(
      newCount: quantity,
      newBalance: const DiamondBalance(green: 0, purple: 0),
    ));
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

/// Soru repository'si — 9 metot; yalnizca `getMyQuestions` ve
/// `reorderQuestions` acik (UserRepository stili, gerisi noSuchMethod ile patlar).
///
/// `reorderCompleter` verilirse `reorderQuestions` onu bekler: iyimser
/// guncellemenin sunucu cevabindan ONCE gorundugunu test edebilmek icin.
class FakeQuestionRepository implements QuestionRepository {
  FakeQuestionRepository({
    this.questions = const [],
    this.listFailure,
    this.reorderFailure,
    this.reorderResponse,
    this.reorderCompleter,
    this.aiResponse = const {},
    this.aiFailure,
  });

  final List<QuestionModel> questions;
  final AppFailure? listFailure;
  final AppFailure? reorderFailure;
  final List<QuestionModel>? reorderResponse;
  final Completer<void>? reorderCompleter;
  final Map<String, dynamic> aiResponse;
  final AppFailure? aiFailure;

  int reorderCallCount = 0;
  List<String>? lastOrderedIds;
  Map<String, dynamic>? lastAiBody;

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
