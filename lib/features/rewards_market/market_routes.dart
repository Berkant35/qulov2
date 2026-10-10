import 'package:qulo_v2/routing/route_names.dart';

/// Banner `app_route` (sunucu `APP_ROUTES`, `page-sections.ts`) → uygulama rotası. Bilinmeyen değer
/// (yeni sunucu, eski uygulama) null → kart dokunmada hiçbir yere gitmez.
String? bannerRouteName(String route) => switch (route) {
      'diamonds' => RouteNames.diamonds,
      'exchange' => RouteNames.exchange,
      'subscription' => RouteNames.subscription,
      'discover' => RouteNames.discover,
      'rewards_redemptions' => RouteNames.rewardsRedemptions,
      _ => null,
    };
