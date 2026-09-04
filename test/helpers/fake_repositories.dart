import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/exchange_repository.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';

/// Provider testleri icin bellek-ici repository'ler. Servis/ag yok; testler
/// gercek notifier kodunu calistirir, yalnizca veri kaynagi sahtedir.
///
/// Stil farki bilincli: `UserRepository` 21 metot → sadece kullanilan yazilir,
/// gerisi `noSuchMethod` ile patlar; `ExchangeRepository` 4 metot → hepsi acik.

class FakeUserRepository implements UserRepository {
  FakeUserRepository(this.user);

  final UserModel user;

  @override
  Future<Result<UserModel>> getMe() async => Success(user);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeUserRepository.${invocation.memberName}');
}

class FakeExchangeRepository implements ExchangeRepository {
  FakeExchangeRepository({this.inventory = const []});

  final List<PowerInventoryItem> inventory;

  @override
  Future<Result<InventoryResponse>> getInventory() async =>
      Success(InventoryResponse(inventory: inventory));

  @override
  Future<Result<RatesResponse>> getRates() async =>
      const Success(RatesResponse(convertRatio: 3, powers: []));

  @override
  Future<Result<ConvertResponse>> convert(int greenAmount) =>
      throw UnimplementedError();

  @override
  Future<Result<BuyPowerResponse>> buyPower(
    String powerName,
    String diamondType,
    int quantity,
  ) =>
      throw UnimplementedError();
}
