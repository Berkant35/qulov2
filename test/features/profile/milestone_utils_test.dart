import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/profile/utils/milestone_utils.dart';

/// Profil duzenleme ilerleme cubugundaki odul mesaji ("%50 tamamla, 20 elmas
/// kazan") bir sonraki esigi buradan alir. Esik anahtarlari sunucu economy
/// config'inden gelir ve sirali olmayabilir.
void main() {
  const milestones = {25: 5, 50: 20, 75: 30, 100: 50};

  test('ilk esigin altindayken ilk esik', () {
    expect(nextMilestoneFor(10, milestones.keys), 25);
  });

  test('iki esik arasinda bir sonraki', () {
    expect(nextMilestoneFor(60, milestones.keys), 75);
  });

  test('tam esikte bir sonrakine gecer (esik zaten kazanildi)', () {
    expect(nextMilestoneFor(50, milestones.keys), 75);
  });

  test('tum esikler gecildiyse null — mesaj gosterilmez', () {
    expect(nextMilestoneFor(100, milestones.keys), isNull);
  });

  test('sirasiz anahtarlar da dogru siralanir', () {
    expect(nextMilestoneFor(30, [100, 25, 75, 50]), 50);
  });

  test('esik yoksa null', () {
    expect(nextMilestoneFor(0, const <int>[]), isNull);
  });
}
