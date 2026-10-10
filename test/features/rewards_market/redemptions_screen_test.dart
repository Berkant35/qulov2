import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/mixins/redemptions_screen_mixin.dart';
import 'package:qulo_v2/features/rewards_market/providers/redemptions_provider.dart';
import 'package:qulo_v2/features/rewards_market/screens/redemptions_screen.dart';
import 'package:qulo_v2/features/rewards_market/widgets/redemption_tile.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../helpers/fake_repositories.dart';

Redemption _r(String id, RedemptionStatus status, {String? code, String? reason}) => Redemption(
      id: id, status: status, brandKey: 'GRAB', countryCode: 'TH', currency: 'THB', faceValue: 50,
      rainbowPrice: 51, deliveryCode: code, rejectReason: reason, createdAt: DateTime.utc(2026, 9, 29),
    );

Future<void> _pump(WidgetTester tester, FakeRewardsRepository repo) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [rewardsRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: const RedemptionsScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => FormatManager.instance.configure(const Locale('en', 'US')));

  testWidgets('durum çipleri; teslimde kod + kopyala; retle not + ham sebep', (tester) async {
    await _pump(tester, FakeRewardsRepository(redemptionPages: {
      1: RedemptionPage(items: [
        _r('a', RedemptionStatus.pending),
        _r('b', RedemptionStatus.fulfilled, code: 'GRAB-123'),
        _r('c', RedemptionStatus.rejected, reason: 'out of stock'),
      ], total: 3, page: 1, limit: 20),
    }));
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('GRAB-123'), findsOneWidget);
    expect(find.text('Copy code'), findsOneWidget);
    expect(find.text('Your request was rejected and your Rainbow was refunded.'), findsOneWidget);
    expect(find.text('Reason: out of stock'), findsOneWidget);
  });

  testWidgets('boş liste mesajı', (tester) async {
    await _pump(tester, FakeRewardsRepository());
    expect(find.text('You have no gift card requests yet'), findsOneWidget);
  });

  testWidgets('refresh sürerken ve başarısız olduğunda kartlar görünür kalır (tam sayfa yükleyici/hata yok)',
      (tester) async {
    final repo = FakeRewardsRepository(redemptionPages: {
      1: RedemptionPage(items: [_r('a', RedemptionStatus.pending)], total: 1, page: 1, limit: 20),
    });
    await _pump(tester, repo);
    expect(find.byType(RedemptionTile), findsOneWidget);

    final gate = Completer<void>();
    repo.redemptionsGate = gate;
    repo.redemptionsFailure = const NetworkFailure();

    final mixinState = tester.state<RedemptionsScreenMixin>(find.byType(RedemptionsScreen));
    final refreshFuture = mixinState.refresh();
    await tester.pump();

    // Yüklenirken: önceki durum korunuyor — tam sayfa yükleyici/hata görünümüne düşmez, kart ekranda kalır.
    expect(find.byType(AppLoadingWidget), findsNothing);
    expect(find.text("Couldn't load your requests"), findsNothing);
    expect(find.byType(RedemptionTile), findsOneWidget);

    gate.complete();
    await refreshFuture;
    await tester.pump();

    // Refresh başarısız oldu ama önceki liste görünür kalmalı (tam sayfa hataya düşmez);
    // kullanıcı yenilemenin olmadığını snackbar'dan öğrenir.
    expect(find.byType(RedemptionTile), findsOneWidget);
    expect(find.text("Couldn't load your requests"), findsNothing);
    expect(find.text('No internet connection. Please try again.'), findsOneWidget);
  });

  testWidgets('yenileme hatası (sunucu): snackbar yedek metni', (tester) async {
    final repo = FakeRewardsRepository(redemptionPages: {
      1: RedemptionPage(items: [_r('a', RedemptionStatus.pending)], total: 1, page: 1, limit: 20),
    });
    await _pump(tester, repo);
    repo.redemptionsFailure = const ServerFailure(code: 'SERVER_ERROR', statusCode: 500);

    await tester.state<RedemptionsScreenMixin>(find.byType(RedemptionsScreen)).refresh();
    await tester.pump();

    expect(find.byType(RedemptionTile), findsOneWidget);
    expect(find.descendant(of: find.byType(SnackBar), matching: find.text("Couldn't load your requests")),
        findsOneWidget);
  });

  testWidgets('sonraki sayfa hatası: liste sonunda hata + Yeniden dene; dokununca aynı sayfa tekrar istenir',
      (tester) async {
    final repo = FakeRewardsRepository(redemptionPages: {
      1: RedemptionPage(items: [_r('a', RedemptionStatus.pending)], total: 2, page: 1, limit: 1),
      2: RedemptionPage(items: [_r('b', RedemptionStatus.pending)], total: 2, page: 2, limit: 1),
    });
    await _pump(tester, repo);
    repo.redemptionsFailure = const NetworkFailure();

    await ProviderScope.containerOf(tester.element(find.byType(RedemptionsScreen)))
        .read(redemptionsProvider.notifier)
        .loadMore();
    await tester.pumpAndSettle();

    expect(find.byType(RedemptionTile), findsOneWidget, reason: 'mevcut liste korunur');
    expect(find.text("Couldn't load your requests"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    repo.redemptionsFailure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repo.redemptionPagesRequested, [1, 2, 2]);
    expect(find.byType(RedemptionTile), findsNWidgets(2));
    expect(find.text('Retry'), findsNothing);
  });
}
