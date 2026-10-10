import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/rewards_market/market_routes.dart';
import 'package:qulo_v2/routing/route_names.dart';

void main() {
  test('sunucu APP_ROUTES → uygulama rotaları; bilinmeyen null', () {
    expect(bannerRouteName('diamonds'), RouteNames.diamonds);
    expect(bannerRouteName('exchange'), RouteNames.exchange);
    expect(bannerRouteName('subscription'), RouteNames.subscription);
    expect(bannerRouteName('discover'), RouteNames.discover);
    expect(bannerRouteName('rewards_redemptions'), RouteNames.rewardsRedemptions);
    expect(bannerRouteName('casino'), isNull);
  });
}
