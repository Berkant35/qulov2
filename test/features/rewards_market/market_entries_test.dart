import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/rainbow_balance_chip.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/profile/widgets/profile_menu_list.dart';
import 'package:qulo_v2/features/rewards_market/widgets/rainbow_market_button.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

import '../../helpers/fixed_user_notifier.dart';

/// Üst çubuk girişinin `push` mu `go` mu çağırdığını kaydeder (gerçek servis router ister).
class _RecordingNavigationService implements NavigationService {
  final pushed = <String>[];
  final went = <String>[];

  @override
  Future<T?> push<T extends Object?>(String name, {Map<String, String>? params, Object? extra}) async {
    pushed.add(name);
    return null;
  }

  @override
  void go(String name, {Map<String, String>? params, Object? extra}) => went.add(name);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_RecordingNavigationService.${invocation.memberName}');
}

// NOT: RainbowBalanceChip (üst çubuk) ve ProfileMenuList'teki DiamondIcon.purple
// (her zaman görünen "Elmaslar" satırı) kendi parlama animasyonunu sonsuz
// `repeat()` ile çalıştırır (bkz. test/features/rewards_market/market_screen_test.dart) —
// bu yüzden `pumpAndSettle()` hiçbir zaman "sakinleşmez" ve timeout atar.
// Sınırlı `pump()` ile aynı niyeti (widget ağacının kurulmasını beklemek) koruyoruz.
Future<void> _pump(WidgetTester tester, UserModel user, {NavigationService? nav}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      userProvider.overrideWith(() => FixedUserNotifier(user)),
      if (nav != null) navigationServiceProvider.overrideWithValue(nav),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        appBar: AppBar(actions: const [RainbowMarketButton()]),
        body: SingleChildScrollView(
          child: ProfileMenuList(
            questionCount: 5,
            onEditProfile: () {}, onQuestions: () {}, onDiamonds: () {}, onSubscription: () {},
            onPerformance: () {}, onPassport: () {}, onTerms: () {}, onPrivacy: () {},
            onRainbowMarket: () {}, onGiftCards: () {},
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('Rainbow kapalı + talep yok: hiçbir giriş yok', (tester) async {
    await _pump(tester, UserModel(id: 'u1', email: 'e@qulo.test'));
    expect(find.byType(RainbowBalanceChip), findsNothing);
    expect(find.text('Rainbow Market'), findsNothing);
    expect(find.text('My gift cards'), findsNothing);
  });

  testWidgets('Rainbow kapalı ama talebi var: yalnız Hediye kartlarım', (tester) async {
    await _pump(tester, UserModel(id: 'u1', email: 'e@qulo.test', hasRewardRedemptions: true));
    expect(find.byType(RainbowBalanceChip), findsNothing);
    expect(find.text('Rainbow Market'), findsNothing);
    expect(find.text('My gift cards'), findsOneWidget);
  });

  testWidgets('Rainbow açık: üst çubuk bakiyesi + iki menü satırı', (tester) async {
    await _pump(tester, UserModel(id: 'u1', email: 'e@qulo.test', rainbowEnabled: true, rainbowDiamonds: 1000));
    expect(find.byType(RainbowBalanceChip), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
    expect(find.text('Rainbow Market'), findsOneWidget);
    expect(find.text('My gift cards'), findsOneWidget);
  });

  // Keşfet üst çubuğundan açılan market geri tuşunda Keşfet'e dönmeli: `go` Profil sekmesine
  // atlıyordu. Deep link `/profile/market` ayrı yoldan (`navigateDeepLink`, go) — bkz.
  // deep_link_parser_test.dart.
  testWidgets('üst çubuk bakiyesine dokununca market push ile açılır (go değil)', (tester) async {
    final nav = _RecordingNavigationService();
    await _pump(tester, UserModel(id: 'u1', email: 'e@qulo.test', rainbowEnabled: true, rainbowDiamonds: 5), nav: nav);

    await tester.tap(find.byType(RainbowBalanceChip));
    await tester.pump();

    expect(nav.pushed, [RouteNames.rewardsMarket]);
    expect(nav.went, isEmpty);
  });
}
