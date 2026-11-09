import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/power_labels.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/power_effects/half_strike_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/oracle_highlight.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/skip_slide_effect.dart';
import 'package:qulo_v2/core/widgets/power_effects/time_extend_effect.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/features/quiz/mixins/power_help_preview_mixin.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_bubble.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_button.dart';

/// "?" baloncuğu (spec §4.4, §13.2/6): o güce özel minyatür efekt döngüsü + tek cümle
/// (+ Kâhin'de yüzde); modal değil, tek dokunuşla kapanır. "?" güç butonundan ayrı dokunma
/// alanıdır: gücü kullanmaz, yalnız `quiz_power_help_open {power}` atar.
final _en = AppLocalizations(const Locale('en'));

const _quizPowers = [
  PowerType.oracle,
  PowerType.half,
  PowerType.skip,
  PowerType.hint,
  PowerType.timeExtend,
  PowerType.skipAll,
];

String _oracleLabel(int percent) => _en
    .get('power_oracle_accuracy')
    .replaceAll('{percent}', FormatManager.instance.percent(percent));

Widget _host(Widget child, {bool reduceMotion = false}) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: app!,
    ),
    home: Scaffold(body: child),
  ),
);

/// Çeviriler yüklenene kadar ilk kare boştur.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(_host(child, reduceMotion: reduceMotion));
  await tester.pump();
}

PowerHelpBubble _bubble(
  PowerType type, {
  VoidCallback? onClose,
  double accuracy = 0.7,
}) => PowerHelpBubble(
  type: type,
  title: 'Title',
  oracleAccuracy: accuracy,
  timeExtendSeconds: 15,
  onClose: onClose ?? () {},
);

Finder _helpButton(PowerType type) =>
    find.byWidgetPredicate((w) => w is PowerHelpButton && w.type == type);

Finder _powerButton(PowerType type) =>
    find.byWidgetPredicate((w) => w is PowerBarButton && w.type == type);

void main() {
  group('PowerHelpBubble', () {
    for (final type in _quizPowers) {
      testWidgets('${type.apiName}: kendi açıklaması; yüzde yalnız Kâhin\'de', (
        tester,
      ) async {
        await _pump(tester, Center(child: _bubble(type)));

        expect(find.text(_en.get(powerDescKey(type.apiName))), findsOneWidget);
        expect(
          find.text(_oracleLabel(70)),
          type == PowerType.oracle ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('Kâhin yüzdesi config oranından (%65)', (tester) async {
      await _pump(
        tester,
        Center(child: _bubble(PowerType.oracle, accuracy: 0.65)),
      );

      expect(find.text(_oracleLabel(65)), findsOneWidget);
    });

    testWidgets('baloncuğa dokunmak kapatır', (tester) async {
      var closes = 0;
      await _pump(
        tester,
        Center(child: _bubble(PowerType.half, onClose: () => closes++)),
      );

      await tester.tap(find.byType(PowerHelpBubble));
      expect(closes, 1);
    });

    testWidgets('dışarı dokunmak kapatır ve dokunuş yutulmaz (modal değil)', (
      tester,
    ) async {
      var closes = 0;
      var outsideTaps = 0;
      await _pump(
        tester,
        Column(
          children: [
            TextButton(
              onPressed: () => outsideTaps++,
              child: const Text('outside'),
            ),
            _bubble(PowerType.half, onClose: () => closes++),
          ],
        ),
      );

      await tester.tap(find.text('outside'));
      expect(closes, 1);
      expect(outsideTaps, 1);
    });

    testWidgets('minyatür döngüsü: Yarıla iki şıkkı eler, sonra geri açar', (
      tester,
    ) async {
      await _pump(tester, Center(child: _bubble(PowerType.half)));
      Iterable<HalfStrikeEffect> removed() => tester
          .widgetList<HalfStrikeEffect>(find.byType(HalfStrikeEffect))
          .where((h) => h.removed);

      await tester.pump(PowerEffectTiming.enter);
      expect(removed(), hasLength(2));

      await tester.pump(PowerHelpPreviewMixin.halfCycle);
      expect(removed(), isEmpty, reason: 'döngü kapanır');

      await tester.pump(PowerHelpPreviewMixin.halfCycle);
      expect(removed(), hasLength(2), reason: 've tekrar oynar');
    });

    testWidgets(
      'minyatür ortak efektleri kullanır: Kâhin vurgusu, Ek Süre çipi, Doğru Say kaydırması',
      (tester) async {
        await _pump(
          tester,
          Column(
            children: [
              _bubble(PowerType.oracle),
              _bubble(PowerType.timeExtend),
              _bubble(PowerType.skipAll),
            ],
          ),
        );
        await tester.pump(PowerEffectTiming.enter);

        expect(
          tester.widget<OracleHighlight>(find.byType(OracleHighlight)).active,
          isTrue,
        );
        expect(find.byKey(TimeExtendEffect.chipKey), findsOneWidget);
        expect(find.byKey(SkipSlideEffect.badgeKey), findsOneWidget);
      },
    );

    testWidgets('hareketi azalt: döngü yok, efekt son hâlinde sabit kalır', (
      tester,
    ) async {
      await _pump(
        tester,
        Center(child: _bubble(PowerType.half)),
        reduceMotion: true,
      );
      Iterable<HalfStrikeEffect> removed() => tester
          .widgetList<HalfStrikeEffect>(find.byType(HalfStrikeEffect))
          .where((h) => h.removed);

      // İlk kare efekt öncesi; bir sonraki karede animasyonsuz son hâl (efektler ilk build'de oynamaz).
      await tester.pump();
      expect(removed(), hasLength(2));
      await tester.pump(PowerHelpPreviewMixin.halfCycle * 3);
      expect(removed(), hasLength(2));
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'döngü zamanlayıcısı kurulmadı',
      );
    });

    testWidgets('hareketi azalt döngü sürerken açılırsa son hâlde durur', (
      tester,
    ) async {
      await _pump(tester, Center(child: _bubble(PowerType.half)));
      Iterable<HalfStrikeEffect> removed() => tester
          .widgetList<HalfStrikeEffect>(find.byType(HalfStrikeEffect))
          .where((h) => h.removed);
      await tester.pump(PowerEffectTiming.enter);
      await tester.pump(PowerHelpPreviewMixin.halfCycle);
      expect(removed(), isEmpty, reason: 'döngünün kapalı yarısı');

      await _pump(
        tester,
        Center(child: _bubble(PowerType.half)),
        reduceMotion: true,
      );
      expect(removed(), hasLength(2));
      await tester.pump(PowerHelpPreviewMixin.halfCycle * 3);
      expect(removed(), hasLength(2));
    });
  });

  group('PowerBar "?" butonları', () {
    late List<({String name, Map<String, Object>? params})> events;
    late List<String> powersUsed;

    setUp(() {
      events = [];
      powersUsed = [];
      AnalyticsManager.debugEventSink = (name, params) =>
          events.add((name: name, params: params));
    });

    tearDown(() => AnalyticsManager.debugEventSink = null);

    Future<void> pumpBar(WidgetTester tester, {bool hasHint = true}) => _pump(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: PowerBar(
          sessionId: 's1',
          hasHint: hasHint,
          onPowerUsed: powersUsed.add,
        ),
      ),
    );

    testWidgets(
      'her quiz gücünün "?"si var; ipucusuz soruda İpucu\'nunki yok',
      (tester) async {
        await pumpBar(tester);
        for (final type in [
          PowerType.oracle,
          PowerType.half,
          PowerType.skip,
          PowerType.hint,
          PowerType.timeExtend,
        ]) {
          expect(_helpButton(type), findsOneWidget, reason: type.apiName);
        }

        await pumpBar(tester, hasHint: false);
        expect(_helpButton(PowerType.hint), findsNothing);
      },
    );

    testWidgets(
      '"?" baloncuğu açar, quiz_power_help_open {power} atar, gücü kullanmaz',
      (tester) async {
        await pumpBar(tester);

        await tester.tap(_helpButton(PowerType.oracle));
        await tester.pump();

        expect(find.byType(PowerHelpBubble), findsOneWidget);
        expect(find.text(_en.get('power_oracle_desc')), findsOneWidget);
        expect(find.text(_oracleLabel(70)), findsOneWidget);
        expect(events.map((e) => e.name), [AnalyticsEvents.quizPowerHelpOpen]);
        expect(events.single.params, {AnalyticsEvents.paramPower: 'ORACLE'});
        expect(powersUsed, isEmpty);
      },
    );

    testWidgets(
      'aynı "?" kapatır (yeni olay yok); başka "?" o güce geçer (yeni olay)',
      (tester) async {
        await pumpBar(tester);

        await tester.tap(_helpButton(PowerType.half));
        await tester.pump();
        await tester.tap(_helpButton(PowerType.half));
        await tester.pump();
        expect(find.byType(PowerHelpBubble), findsNothing);
        expect(events, hasLength(1));

        await tester.tap(_helpButton(PowerType.half));
        await tester.pump();
        await tester.tap(_helpButton(PowerType.skip));
        await tester.pump();
        expect(find.byType(PowerHelpBubble), findsOneWidget);
        expect(find.text(_en.get('power_skip_desc')), findsOneWidget);
        expect(events.map((e) => e.params![AnalyticsEvents.paramPower]), [
          'HALF',
          'HALF',
          'SKIP',
        ]);
        expect(powersUsed, isEmpty);
      },
    );

    testWidgets(
      'güç butonu "?"den bağımsız: dokunuş gücü kullanır, yardım olayı atmaz',
      (tester) async {
        await pumpBar(tester);

        await tester.tap(_powerButton(PowerType.half));
        await tester.pump();

        expect(powersUsed, ['HALF']);
        expect(events, isEmpty);
        expect(find.byType(PowerHelpBubble), findsNothing);
      },
    );

    // "?"ye hafif aşağıdan dokunmak paralı güce düşmesin (onaysız mor harcama, spec §13.2/6):
    // arada ≥ 8 px boşluk; "?" alanı ≥ 40 px yüksek ve yukarı doğru büyür (ikon güce yakın kalır).
    testWidgets(
      '"?" dokunma alanı güç butonuyla çakışmaz: ≥ sm boşluk, ≥ 40 px yükseklik',
      (tester) async {
        await pumpBar(tester);

        for (final type in [
          PowerType.oracle,
          PowerType.half,
          PowerType.skip,
          PowerType.hint,
          PowerType.timeExtend,
        ]) {
          final help = tester.getRect(_helpButton(type));
          final power = tester.getRect(_powerButton(type));
          expect(
            power.top - help.bottom,
            greaterThanOrEqualTo(AppSpacing.sm),
            reason: type.apiName,
          );
          expect(
            help.height,
            greaterThanOrEqualTo(40),
            reason: '${type.apiName}: "?" dokunma alanı yüksekliği',
          );
          expect(
            help.center.dx,
            moreOrLessEquals(power.center.dx),
            reason: '"?" kendi gücünün üstünde',
          );
          // İkon alanın altında: görsel "?" güç butonuna yakın, büyüyen alan yukarıda.
          final icon = tester.getRect(
            find.descendant(
              of: _helpButton(type),
              matching: find.byType(QIcon),
            ),
          );
          expect(
            icon.bottom,
            moreOrLessEquals(help.bottom),
            reason: '${type.apiName}: ikon alanın altında',
          );
        }
      },
    );

    testWidgets(
      '"?" alanının en alt noktasına dokunmak gücü kullanmaz, baloncuk açar',
      (tester) async {
        await pumpBar(tester);

        final help = tester.getRect(_helpButton(PowerType.half));
        await tester.tapAt(Offset(help.center.dx, help.bottom - 1));
        await tester.pump();

        expect(powersUsed, isEmpty);
        expect(find.byType(PowerHelpBubble), findsOneWidget);
      },
    );
  });
}
