import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_guide_overlay.dart';

/// Talimat katmanı demoyu tek yola sokar: delikteki güce dokunuş geçer, geri kalan her şey
/// (şıklar, diğer güçler) yutulur. Bu bozulursa ya demo kilitlenir ya da talimat delinir.
void main() {
  Future<({int Function() target, int Function() other})> pumpOverlay(
    WidgetTester tester,
  ) async {
    final targetKey = GlobalKey();
    var targetTaps = 0;
    var otherTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  TextButton(
                    onPressed: () => otherTaps++,
                    child: const Text('other'),
                  ),
                  const Spacer(),
                  KeyedSubtree(
                    key: targetKey,
                    child: TextButton(
                      onPressed: () => targetTaps++,
                      child: const Text('target'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
              Positioned.fill(
                child: PowerDemoGuideOverlay(
                  targetKey: targetKey,
                  text: 'tap the target',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(); // delik ilk kareden sonra ölçülür
    await tester.pump(const Duration(milliseconds: 500));
    return (target: () => targetTaps, other: () => otherTaps);
  }

  testWidgets('delikteki dokunuş hedefe geçer, dışarıdaki yutulur', (
    tester,
  ) async {
    final taps = await pumpOverlay(tester);

    await tester.tap(find.text('target'));
    await tester.tap(find.text('other'), warnIfMissed: false);

    expect(taps.target(), 1);
    expect(taps.other(), 0);
  });

  // Carousel'de alt çubuk / üst alan yumuşakça boyut değiştirir (AnimatedSize): sahne her karede
  // yeniden yerleşir ama katman yeniden kurulmaz. Delik son yerleşime göre ölçülmezse güce dokunuş
  // yutulur ve demo o adımda kilitlenir.
  testWidgets(
    'sahne animasyonla yeniden boyutlanınca delik yeni konuma taşınır',
    (tester) async {
      final targetKey = GlobalKey();
      var targetTaps = 0;
      late StateSetter setHostState;
      var height = 600.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return Align(
                  alignment: Alignment.topCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: height,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            const Spacer(),
                            KeyedSubtree(
                              key: targetKey,
                              child: TextButton(
                                onPressed: () => targetTaps++,
                                child: const Text('target'),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                        Positioned.fill(
                          child: PowerDemoGuideOverlay(
                            targetKey: targetKey,
                            text: 'tap the target',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      setHostState(() => height = 450);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.text('target'));
      expect(targetTaps, 1, reason: 'delik hedefin son konumunda');
    },
  );

  testWidgets('talimat cümlesi hedefin üstünde durur', (tester) async {
    await pumpOverlay(tester);

    final sentence = tester.getRect(find.text('tap the target'));
    final target = tester.getRect(find.text('target'));
    expect(sentence.bottom, lessThan(target.top));
  });
}
