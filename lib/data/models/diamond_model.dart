import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'diamond_model.g.dart';

@JsonSerializable()
class DiamondBalance extends Equatable {
  final int green;
  final int purple;

  const DiamondBalance({required this.green, required this.purple});

  factory DiamondBalance.fromJson(Map<String, dynamic> json) =>
      _$DiamondBalanceFromJson(json);
  Map<String, dynamic> toJson() => _$DiamondBalanceToJson(this);

  @override
  List<Object?> get props => [green, purple];
}

@JsonSerializable()
class DiamondTransaction extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String type;
  final int amount;
  final String reason;
  @JsonKey(name: 'reference_id')
  final String? referenceId;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const DiamondTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.reason,
    this.referenceId,
    this.createdAt,
  });

  factory DiamondTransaction.fromJson(Map<String, dynamic> json) =>
      _$DiamondTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$DiamondTransactionToJson(this);

  @override
  List<Object?> get props => [id];
}

@JsonSerializable()
class DiamondHistoryResponse extends Equatable {
  final List<DiamondTransaction> items;
  final int total;
  final int page;
  final int limit;

  const DiamondHistoryResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory DiamondHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$DiamondHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DiamondHistoryResponseToJson(this);

  @override
  List<Object?> get props => [total, page];
}
