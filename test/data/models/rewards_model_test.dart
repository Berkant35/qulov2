import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';

Map<String, dynamic> _item([String id = 'i1']) => {
      'id': id, 'brand_key': 'GRAB', 'country_code': 'TH', 'currency': 'THB',
      'face_value': 50, 'rainbow_price': 51, 'logo_url': null,
    };

void main() {
  group('MarketView.fromJson', () {
    test('tam yanıt: bölümler, aksiyonlar, önizleme ülkeleri', () {
      final view = MarketView.fromJson({
        'balance': 1000,
        'items': [_item()],
        'monthly_cap': null,
        'used_this_month': 0,
        'preview_countries': ['TH', 'ID', 'MY'],
        'sections': [
          {
            'id': 's1', 'type': 'banner_carousel', 'heading': null, 'is_draft': true, 'autoplay_seconds': 5,
            'items': [
              {'id': 'b1', 'image_url': 'https://x/b1.jpg', 'title': 'T', 'subtitle': null, 'cta_label': 'Go',
               'action': {'type': 'catalog_item', 'catalog_item': _item()}},
              {'id': 'b2', 'image_url': 'https://x/b2.jpg', 'title': 'R', 'action': {'type': 'app_route', 'route': 'diamonds'}},
              {'id': 'b3', 'image_url': 'https://x/b3.jpg', 'title': 'N', 'action': {'type': 'none'}},
            ],
          },
          {'id': 's2', 'type': 'featured_items', 'heading': 'Featured', 'is_draft': false,
           'items': [{'id': 'f1', 'catalog_item': _item()}]},
        ],
      });

      expect(view.balance, 1000);
      expect(view.monthlyCap, isNull);
      expect(view.previewCountries, ['TH', 'ID', 'MY']);
      final carousel = view.sections[0] as BannerCarouselSectionView;
      expect(carousel.isDraft, isTrue);
      expect(carousel.items[0].action, BannerCatalogAction(MarketItem.tryParse(_item())!));
      expect(carousel.items[1].action, const BannerRouteAction('diamonds'));
      expect(carousel.items[2].action, const BannerNoAction());
      expect(carousel.items[0].ctaLabel, 'Go');
      final featured = view.sections[1] as FeaturedItemsSectionView;
      expect(featured.heading, 'Featured');
      expect(featured.items.single.item.rainbowPrice, 51);
    });

    test('bilinmeyen bölüm türü ve kartsız bölüm atlanır; bozuk kart düşer', () {
      final view = MarketView.fromJson({
        'balance': 5, 'items': [], 'monthly_cap': 150, 'used_this_month': 20,
        'sections': [
          {'id': 's1', 'type': 'brand_strip', 'items': [{'id': 'x'}]},
          {'id': 's2', 'type': 'featured_items', 'items': []},
          {'id': 's3', 'type': 'banner_carousel', 'items': [
            {'id': 'b1', 'title': 'görselsiz'},
            {'id': 'b2', 'image_url': 'https://x/b.jpg', 'title': 'ok', 'action': {'type': 'catalog_item'}},
          ]},
        ],
      });
      expect(view.monthlyCap, 150);
      expect(view.previewCountries, isEmpty);
      expect(view.sections, hasLength(1));
      final carousel = view.sections.single as BannerCarouselSectionView;
      expect(carousel.items.single.id, 'b2');
      expect(carousel.items.single.action, const BannerNoAction(), reason: 'ürünsüz catalog_item aksiyonu düşer');
    });

    test('eksik alanlar varsayılana düşer, kimliksiz ürün atlanır', () {
      final view = MarketView.fromJson({'items': [{'brand_key': 'GRAB'}, _item('ok')]});
      expect(view.balance, 0);
      expect(view.usedThisMonth, 0);
      expect(view.items.map((i) => i.id), ['ok']);
      expect(view.sections, isEmpty);
    });
  });

  group('Redemption', () {
    test('durum eşlemesi + teslim alanları + tarih', () {
      final page = RedemptionPage.fromJson({
        'items': [
          {'id': 'r1', 'status': 'FULFILLED', 'brand_key': 'GRAB', 'country_code': 'TH', 'currency': 'THB',
           'face_value': 50, 'rainbow_price': 51, 'delivery_code': 'ABC', 'delivery_url': null,
           'reject_reason': null, 'created_at': '2026-09-29T10:00:00Z', 'decided_at': null},
          {'id': 'r2', 'status': 'REJECTED', 'reject_reason': 'out of stock'},
          {'id': 'r3', 'status': 'WHATEVER'},
        ],
        'total': 45, 'page': 2, 'limit': 20,
      });
      expect(page.items.map((r) => r.status),
          [RedemptionStatus.fulfilled, RedemptionStatus.rejected, RedemptionStatus.pending]);
      expect(page.items[0].deliveryCode, 'ABC');
      expect(page.items[0].createdAt, DateTime.utc(2026, 9, 29, 10));
      expect(page.items[1].rejectReason, 'out of stock');
      expect(page.hasMore, isTrue);
      expect(RedemptionPage.fromJson({'items': [], 'total': 40, 'page': 2, 'limit': 20}).hasMore, isFalse);
    });

    test('RedeemResult talepsiz yanıtta FormatException', () {
      expect(() => RedeemResult.fromJson({'balance': 3}), throwsFormatException);
      final ok = RedeemResult.fromJson({'redemption': {'id': 'r1', 'status': 'PENDING'}, 'balance': 949});
      expect(ok.balance, 949);
      expect(ok.redemption.status, RedemptionStatus.pending);
    });
  });

  test('SectionEvent sunucu gövdesi', () {
    expect(const SectionEvent('i1', SectionEventType.click).toJson(), {'item_id': 'i1', 'event': 'click'});
  });
}
