import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class ExchangeState {
  final List<PowerInventoryItem> inventory;
  final RatesResponse? rates;
  final bool isLoading;

  const ExchangeState({
    this.inventory = const [],
    this.rates,
    this.isLoading = false,
  });

  ExchangeState copyWith({
    List<PowerInventoryItem>? inventory,
    RatesResponse? rates,
    bool? isLoading,
  }) {
    return ExchangeState(
      inventory: inventory ?? this.inventory,
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int getCount(String powerName) {
    return inventory
        .where((i) => i.powerName == powerName)
        .fold(0, (sum, i) => sum + i.count);
  }
}

class ExchangeNotifier extends Notifier<ExchangeState> {
  @override
  ExchangeState build() => const ExchangeState();

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true);
    final results = await Future.wait([
      ref.read(exchangeRepositoryProvider).getInventory(),
      ref.read(exchangeRepositoryProvider).getRates(),
    ]);

    final invResult = results[0] as Result<InventoryResponse>;
    final ratesResult = results[1] as Result<RatesResponse>;

    final newInventory = invResult is Success<InventoryResponse>
        ? invResult.data.inventory
        : state.inventory;
    state = state.copyWith(
      inventory: newInventory,
      rates: ratesResult is Success<RatesResponse>
          ? ratesResult.data
          : state.rates,
      isLoading: false,
    );
  }

  /// Basarili guc kullanimindan sonra bakiyeyi YEREL duser — sunucu round-trip'i yok.
  /// Oncelik sunucudakiyle ayni: envanterde hak varsa oradan (`tryUseInventory`),
  /// yoksa mor elmastan (`spendPurple`). Sunucu ucreti zaten aldi; burasi aynadir.
  /// Bayat envanter (baska cihaz) kozmetik sapma yaratir, sonraki fetch'te duzelir.
  ///
  /// Doner: envanterden dustuyse true — analytics de bu tek karari kullanir.
  bool settlePowerSpend(String powerName, int purpleCost) {
    final inventory = List.of(state.inventory);
    final i = inventory.indexWhere((it) => it.powerName == powerName && it.count > 0);
    if (i >= 0) {
      inventory[i] = PowerInventoryItem(powerName: powerName, count: inventory[i].count - 1);
      state = state.copyWith(inventory: inventory);
      return true;
    }
    ref.read(userProvider.notifier).spendPurpleLocally(purpleCost);
    return false;
  }

  Future<bool> convert(int greenAmount) async {
    final result = await ref.read(exchangeRepositoryProvider).convert(greenAmount);
    if (result is Success<ConvertResponse>) {
      await ref.read(diamondProvider.notifier).fetchBalance();
      return true;
    }
    return false;
  }

  Future<Result<BuyPowerResponse>> buyPower(String powerName, String diamondType, int quantity) async {
    final result = await ref.read(exchangeRepositoryProvider).buyPower(
      powerName,
      diamondType,
      quantity,
    );
    if (result is Success<BuyPowerResponse>) {
      await fetchAll();
      await ref.read(diamondProvider.notifier).fetchBalance();
    }
    return result;
  }
}

final exchangeProvider = NotifierProvider<ExchangeNotifier, ExchangeState>(
  ExchangeNotifier.new,
);
