import 'package:equatable/equatable.dart';
import 'package:qulo_v2/data/models/json_read.dart';
import 'package:qulo_v2/data/models/market_item_model.dart';
import 'package:qulo_v2/data/models/page_section_model.dart';

export 'package:qulo_v2/data/models/market_item_model.dart';
export 'package:qulo_v2/data/models/page_section_model.dart';

/// `GET /rewards/market` yanıtı.
class MarketView extends Equatable {
  const MarketView({
    required this.balance,
    required this.items,
    required this.monthlyCap,
    required this.usedThisMonth,
    this.sections = const [],
    this.previewCountries = const [],
  });

  final int balance;
  final List<MarketItem> items;

  /// null = tavan uygulanmaz (test admin).
  final int? monthlyCap;
  final int usedThisMonth;
  final List<PageSectionView> sections;

  /// Yalnız test admin'de dolu (ülke önizleme çipleri).
  final List<String> previewCountries;

  factory MarketView.fromJson(Map<String, dynamic> json) => MarketView(
        balance: jsonInt(json['balance']),
        items: jsonMaps(json['items']).map(MarketItem.tryParse).whereType<MarketItem>().toList(),
        monthlyCap: jsonIntOrNull(json['monthly_cap']),
        usedThisMonth: jsonInt(json['used_this_month']),
        sections: jsonMaps(json['sections']).map(PageSectionView.tryParse).whereType<PageSectionView>().toList(),
        previewCountries: (json['preview_countries'] is List)
            ? (json['preview_countries'] as List).whereType<String>().toList()
            : const [],
      );

  /// İtfa sonrası yerel güncelleme (bakiye + bu ay kullanım); katalog/bölümler aynen kalır.
  MarketView copyWith({int? balance, int? usedThisMonth}) => MarketView(
        balance: balance ?? this.balance,
        items: items,
        monthlyCap: monthlyCap,
        usedThisMonth: usedThisMonth ?? this.usedThisMonth,
        sections: sections,
        previewCountries: previewCountries,
      );

  @override
  List<Object?> get props => [balance, items, monthlyCap, usedThisMonth, sections, previewCountries];
}

enum RedemptionStatus { pending, fulfilled, rejected }

RedemptionStatus _statusOf(Object? value) => switch (value) {
      'FULFILLED' => RedemptionStatus.fulfilled,
      'REJECTED' => RedemptionStatus.rejected,
      _ => RedemptionStatus.pending,
    };

/// Durum → çeviri anahtarı (dinamik anahtar testi bunu kullanır).
String redemptionStatusKey(RedemptionStatus status) => 'redemption_status_${status.name}';

class Redemption extends Equatable {
  const Redemption({
    required this.id,
    required this.status,
    required this.brandKey,
    required this.countryCode,
    required this.currency,
    required this.faceValue,
    required this.rainbowPrice,
    this.deliveryCode,
    this.deliveryUrl,
    this.rejectReason,
    this.createdAt,
    this.decidedAt,
  });

  final String id;
  final RedemptionStatus status;
  final String brandKey;
  final String countryCode;
  final String currency;
  final num faceValue;
  final int rainbowPrice;
  final String? deliveryCode;
  final String? deliveryUrl;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? decidedAt;

  static Redemption? tryParse(Map<String, dynamic> json) {
    final id = jsonText(json['id']);
    if (id == null) return null;
    return Redemption(
      id: id,
      status: _statusOf(json['status']),
      brandKey: jsonText(json['brand_key']) ?? 'OTHER',
      countryCode: jsonText(json['country_code']) ?? '',
      currency: jsonText(json['currency']) ?? '',
      faceValue: jsonNum(json['face_value']),
      rainbowPrice: jsonInt(json['rainbow_price']),
      deliveryCode: jsonText(json['delivery_code']),
      deliveryUrl: jsonText(json['delivery_url']),
      rejectReason: jsonText(json['reject_reason']),
      createdAt: jsonDate(json['created_at']),
      decidedAt: jsonDate(json['decided_at']),
    );
  }

  @override
  List<Object?> get props => [
        id, status, brandKey, countryCode, currency, faceValue, rainbowPrice,
        deliveryCode, deliveryUrl, rejectReason, createdAt, decidedAt,
      ];
}

class RedemptionPage extends Equatable {
  const RedemptionPage({required this.items, required this.total, required this.page, required this.limit});

  final List<Redemption> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory RedemptionPage.fromJson(Map<String, dynamic> json) => RedemptionPage(
        items: jsonMaps(json['items']).map(Redemption.tryParse).whereType<Redemption>().toList(),
        total: jsonInt(json['total']),
        page: jsonInt(json['page'], 1),
        limit: jsonInt(json['limit'], 20),
      );

  @override
  List<Object?> get props => [items, total, page, limit];
}

/// `POST /rewards/redeem` yanıtı; `balance` = işlemden sonraki Rainbow bakiyesi.
class RedeemResult extends Equatable {
  const RedeemResult({required this.redemption, required this.balance});

  final Redemption redemption;
  final int balance;

  factory RedeemResult.fromJson(Map<String, dynamic> json) {
    final redemptionJson = jsonMap(json['redemption']);
    final redemption = redemptionJson == null ? null : Redemption.tryParse(redemptionJson);
    if (redemption == null) throw const FormatException('redeem yanıtında talep yok');
    return RedeemResult(redemption: redemption, balance: jsonInt(json['balance']));
  }

  @override
  List<Object?> get props => [redemption, balance];
}

enum SectionEventType { impression, click }

/// Bölüm kartı olayı (`POST /rewards/events`).
class SectionEvent extends Equatable {
  const SectionEvent(this.itemId, this.type);

  final String itemId;
  final SectionEventType type;

  Map<String, dynamic> toJson() => {'item_id': itemId, 'event': type.name};

  @override
  List<Object?> get props => [itemId, type];
}
