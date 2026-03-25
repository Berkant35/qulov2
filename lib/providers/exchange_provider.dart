import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';

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
