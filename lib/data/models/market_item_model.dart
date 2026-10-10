import 'package:equatable/equatable.dart';
import 'package:qulo_v2/data/models/json_read.dart';

/// Market ürünü (sunucu `MarketItem`, `rewards-catalog-cache.ts`).
class MarketItem extends Equatable {
  const MarketItem({
    required this.id,
    required this.brandKey,
    required this.countryCode,
    required this.currency,
    required this.faceValue,
    required this.rainbowPrice,
    this.logoUrl,
  });

  final String id;
  final String brandKey;
  final String countryCode;
  final String currency;
  final num faceValue;
  final int rainbowPrice;
  final String? logoUrl;

  /// Kimliksiz satır atlanır (null).
  static MarketItem? tryParse(Map<String, dynamic> json) {
    final id = jsonText(json['id']);
    if (id == null) return null;
    return MarketItem(
      id: id,
      brandKey: jsonText(json['brand_key']) ?? 'OTHER',
      countryCode: jsonText(json['country_code']) ?? '',
      currency: jsonText(json['currency']) ?? '',
      faceValue: jsonNum(json['face_value']),
      rainbowPrice: jsonInt(json['rainbow_price']),
      logoUrl: jsonText(json['logo_url']),
    );
  }

  @override
  List<Object?> get props => [id, brandKey, countryCode, currency, faceValue, rainbowPrice, logoUrl];
}
