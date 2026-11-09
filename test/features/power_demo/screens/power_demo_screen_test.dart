import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_screen.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/power_demo_driver.dart';

/// `power-demo` route sarmalayıcısı: gömülü görünümü SafeArea içinde açar, çıkışta yalnız
/// sayfayı kapatır (`pop`) — başka route'a gitmez. Demo kuralları `power_demo_view_test`'te.
void main() {
  final skip = AppLocalizations(const Locale('en')).get('skip');
  late FakeNavigationService nav;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnalyticsManager.debugEventSink = (_, __) {};
    AnalyticsForwarder.instance.setEnabled(false);
    HapticManager.instance.setEnabled(false);
    nav = FakeNavigationService();
  });

  tearDown(() {
    AnalyticsManager.debugEventSink = null;
    AnalyticsForwarder.instance.setEnabled(true);
    HapticManager.instance.setEnabled(true);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    PowerDemoEntryPoint entryPoint = PowerDemoEntryPoint.market,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [navigationServiceProvider.overrideWithValue(nav)],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: padding),
            child: child!,
          ),
          home: PowerDemoScreen(entryPoint: entryPoint),
        ),
      ),
    );
    await tester.pump(); // AppLocalizationsDelegate.load asenkron
    await tester.pump();
  }

  testWidgets('Atla → sayfa tek kez kapanır (pop), başka route açılmaz', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text(skip));
    await tester.pump();

    expect(nav.pops, 1);
    expect(
      nav.pushes,
      isEmpty,
      reason: 'matches/chat/quiz route\'una gidilmez',
    );
  });

  testWidgets('giriş noktası görünüme iletilir', (tester) async {
    await pumpScreen(tester, entryPoint: PowerDemoEntryPoint.quizIntro);

    expect(
      tester.widget<PowerDemoView>(find.byType(PowerDemoView)).entryPoint,
      PowerDemoEntryPoint.quizIntro,
    );
  });

  // Market ▶ / quiz öncesi giriş, iPhone SE (durum çubuğu 20): şık seçilince Cevapla kaydırma
  // alanının dışında, ekranda ve kaydırmadan dokunulabilir — ipucu adımı (en uzun içerik) dahil.
  testWidgets(
    '375×667: her cevap adımında Cevapla kaydırmadan ekranda ve dokunulabilir',
    (tester) async {
      await pumpScreen(tester, padding: const EdgeInsets.only(top: 20));
      final demo = PowerDemoDriver(
        tester,
        entryPoint: PowerDemoEntryPoint.market,
      );
      final checked = <DemoPower?>[];

      await demo.playUntil(
        (p) => p.phase == PowerDemoPhase.finale,
        onAnswerReady: (q) {
          demo.expectAnswerReachable(
            const Rect.fromLTRB(0, 20, 375, 667),
            reason: 'adım ${q.id}',
          );
          checked.add(q.power);
        },
      );

      expect(
        checked,
        containsAll([
          DemoPower.timeExtend,
          DemoPower.oracle,
          DemoPower.half,
          DemoPower.hint,
        ]),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('çentik/durum çubuğunun altından başlar (SafeArea), taşma yok', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      padding: const EdgeInsets.only(top: 50, bottom: 34),
    );

    expect(tester.getTopLeft(find.text(skip)).dy, greaterThanOrEqualTo(50));
    final view = tester.getRect(find.byType(PowerDemoView));
    expect(view.width, 375, reason: 'görünüm ekranı yatayda doldurur');
    expect(view.bottom, lessThanOrEqualTo(667 - 34));
    expect(tester.takeException(), isNull);
  });
}
