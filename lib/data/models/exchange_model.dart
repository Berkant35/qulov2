import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';

part 'exchange_model.g.dart';

@JsonSerializable()
class ConvertResponse extends Equatable {
  @JsonKey(name: 'purple_received')
  final int purpleReceived;
  @JsonKey(name: 'new_balance')
  final DiamondBalance newBalance;

  const ConvertResponse({
    required this.purpleReceived,
    required this.newBalance,
  });

  factory ConvertResponse.fromJson(Map<String, dynamic> json) =>
      _$ConvertResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ConvertResponseToJson(this);

  @override
  List<Object?> get props => [purpleReceived, newBalance];
}

@JsonSerializable()
class BuyPowerResponse extends Equatable {
  @JsonKey(name: 'new_count')
  final int newCount;
  @JsonKey(name: 'new_balance')
  final DiamondBalance newBalance;

  const BuyPowerResponse({
    required this.newCount,
    required this.newBalance,
  });

  factory BuyPowerResponse.fromJson(Map<String, dynamic> json) =>
      _$BuyPowerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BuyPowerResponseToJson(this);

  @override
  List<Object?> get props => [newCount, newBalance];
}

@JsonSerializable()
class PowerInventoryItem extends Equatable {
  @JsonKey(name: 'power_name')
  final String powerName;
  final int count;

  const PowerInventoryItem({
    required this.powerName,
    required this.count,
  });

  factory PowerInventoryItem.fromJson(Map<String, dynamic> json) =>
      _$PowerInventoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$PowerInventoryItemToJson(this);

  @override
  List<Object?> get props => [powerName, count];
}

@JsonSerializable()
class InventoryResponse extends Equatable {
  final List<PowerInventoryItem> inventory;

  const InventoryResponse({required this.inventory});

  factory InventoryResponse.fromJson(Map<String, dynamic> json) =>
      _$InventoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryResponseToJson(this);

  @override
  List<Object?> get props => [inventory];
}

@JsonSerializable()
class ExchangeRatePower extends Equatable {
  final String name;
  @JsonKey(name: 'base_cost')
  final int baseCost;
  @JsonKey(name: 'green_cost')
  final int greenCost;
  @JsonKey(name: 'purple_cost')
  final int purpleCost;
  @JsonKey(name: 'accuracy_rate')
  final double? accuracyRate;

  const ExchangeRatePower({
    required this.name,
    required this.baseCost,
    required this.greenCost,
    required this.purpleCost,
    this.accuracyRate,
  });

  factory ExchangeRatePower.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRatePowerFromJson(json);
  Map<String, dynamic> toJson() => _$ExchangeRatePowerToJson(this);

  @override
  List<Object?> get props => [name];
}

@JsonSerializable()
class RatesResponse extends Equatable {
  @JsonKey(name: 'convert_ratio')
  final int convertRatio;
  final List<ExchangeRatePower> powers;

  const RatesResponse({
    required this.convertRatio,
    required this.powers,
  });

  factory RatesResponse.fromJson(Map<String, dynamic> json) =>
      _$RatesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RatesResponseToJson(this);

  @override
  List<Object?> get props => [convertRatio, powers];
}
