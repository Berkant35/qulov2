import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/purchase_analytics.dart';
import 'package:qulo_v2/core/services/purchase_outcome.dart';

/// Abonelik olcumu (2.0.18 P0-4): 15 abonelik baslatma ile 1 basari arasindaki
/// kayip gorunmuyordu — abonelik basarisi `diamonds_purchase_success`'e,
/// vazgecme gercek hataya karisiyordu, `error_code` `e.toString()` idi.
void main() {
  late List<Map<String, Object?>> events;

  setUp(() {
    events = [];
    AnalyticsManager.debugEventSink = (name, params) => events.add({'event': name, ...?params});
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  PlatformException rcError(PurchasesErrorCode code) =>
      PlatformException(code: '${code.index}', message: 'native message ${code.name}');

  group('basari', () {
    test('abonelik → subscription_purchase_success (elmas olayi DEGIL)', () {
      PurchaseAnalytics.logSuccess('quloplusmonthly2', isSubscription: true);

      expect(events.single, {
        'event': AnalyticsEvents.subscriptionPurchaseSuccess,
        AnalyticsEvents.paramProductId: 'quloplusmonthly2',
      });
    });

    test('elmas → diamonds_purchase_success', () {
      PurchaseAnalytics.logSuccess('qulopurple150', isSubscription: false);

      expect(events.single['event'], AnalyticsEvents.diamondsPurchaseSuccess);
    });
  });

  group('vazgecme hata degil', () {
    test('abonelikte vazgecme → subscription_purchase_cancel, fail atilmaz', () {
      PurchaseAnalytics.logFailure(
        'qulopremiummonthly',
        rcError(PurchasesErrorCode.purchaseCancelledError),
        isSubscription: true,
      );

      expect(events.single, {
        'event': AnalyticsEvents.subscriptionPurchaseCancel,
        AnalyticsEvents.paramProductId: 'qulopremiummonthly',
      });
    });

    test('elmasta vazgecme → diamonds_purchase_cancel', () {
      PurchaseAnalytics.logFailure(
        'qulopurple50',
        rcError(PurchasesErrorCode.purchaseCancelledError),
        isSubscription: false,
      );

      expect(events.single['event'], AnalyticsEvents.diamondsPurchaseCancel);
    });
  });

  group('gercek hata', () {
    test('abonelik hatasi → subscription_purchase_fail, error_code kod adi', () {
      PurchaseAnalytics.logFailure(
        'quloplusmonthly2',
        rcError(PurchasesErrorCode.storeProblemError),
        isSubscription: true,
      );

      expect(events.single, {
        'event': AnalyticsEvents.subscriptionPurchaseFail,
        AnalyticsEvents.paramProductId: 'quloplusmonthly2',
        AnalyticsEvents.paramErrorCode: 'storeProblemError',
      });
    });

    test('elmas hatasi → diamonds_purchase_fail', () {
      PurchaseAnalytics.logFailure(
        'qulopurple400',
        rcError(PurchasesErrorCode.paymentPendingError),
        isSubscription: false,
      );

      expect(events.single['event'], AnalyticsEvents.diamondsPurchaseFail);
      expect(events.single[AnalyticsEvents.paramErrorCode], 'paymentPendingError');
    });
  });

  group('errorCodeOf', () {
    test('magazada urun yok → product_not_found', () {
      expect(
        PurchaseAnalytics.errorCodeOf(const PurchaseProductNotFoundException('x')),
        PurchaseAnalytics.codeProductNotFound,
      );
    });

    test('sayisal olmayan platform kodu / bilinmeyen istisna → unknown (metin sizmaz)', () {
      expect(PurchaseAnalytics.errorCodeOf(PlatformException(code: 'abc')), PurchaseAnalytics.codeUnknown);
      expect(PurchaseAnalytics.errorCodeOf(StateError('uzun metin')), PurchaseAnalytics.codeUnknown);
    });

    test('kapsam disi sayisal kod → unknownError', () {
      expect(PurchaseAnalytics.errorCodeOf(PlatformException(code: '9999')), 'unknownError');
    });
  });

  /// 2.0.18: abonelikten vazgeçen "satın alma başarısız" görüyordu. Sonuç tipi
  /// vazgeçmeyi gerçek hatadan ayırır; ekranlar yalnız `failed`'da mesaj gösterir.
  group('PurchaseOutcome.fromError', () {
    test('vazgeçme → cancelled', () {
      expect(PurchaseOutcome.fromError(rcError(PurchasesErrorCode.purchaseCancelledError)),
          PurchaseOutcome.cancelled);
    });

    for (final code in [
      PurchasesErrorCode.storeProblemError,
      PurchasesErrorCode.networkError,
      PurchasesErrorCode.paymentPendingError,
    ]) {
      test('${code.name} → failed', () {
        expect(PurchaseOutcome.fromError(rcError(code)), PurchaseOutcome.failed);
      });
    }

    test('ürün bulunamadı / bilinmeyen hata → failed', () {
      expect(PurchaseOutcome.fromError(const PurchaseProductNotFoundException('x')), PurchaseOutcome.failed);
      expect(PurchaseOutcome.fromError(StateError('x')), PurchaseOutcome.failed);
    });
  });
}
