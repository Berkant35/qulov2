import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_machine.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_scenario.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';

/// Güç demosu durumu, giriş noktası ([PowerDemoEntryPoint]) başına ve ekran açık kaldığı sürece.
final powerDemoProvider =
    NotifierProvider.autoDispose
        .family<PowerDemoNotifier, PowerDemoProgress, PowerDemoEntryPoint>(
          PowerDemoNotifier.new,
        );

/// Saf durum makinesini ([PowerDemoMachine]) saran ince kabuk: metot = makineyi çağır → `state`
/// ata. Makine uygun olmayan eylemde durumu AYNEN döndürür, Riverpod aynı örneği bildirmez;
/// ikinci dokunuş sessizce yok sayılır. Analitik, haptik ve navigasyon burada DEĞİL (view mixin).
///
/// Demo sunucusuzdur: yalnız ekonomi fiyatlarını okur (senaryo boyutu için); quiz, takas,
/// kullanıcı ve elmas katmanına dokunmaz.
class PowerDemoNotifier
    extends AutoDisposeFamilyNotifier<PowerDemoProgress, PowerDemoEntryPoint> {
  late PowerDemoScenario _scenario;
  late PowerDemoMachine _machine;

  /// Demonun soru sırası. Senaryo ilk okunuşta kilitlenir: demo sürerken fiyat güncellemesi
  /// (arka plan yeniden denemesi) adım sayısını değiştirip kullanıcıyı başa sarmaz.
  PowerDemoScenario get scenario => _scenario;

  @override
  PowerDemoProgress build(PowerDemoEntryPoint arg) {
    final costs = ref.read(economyConfigProvider).powerCosts;
    _scenario = PowerDemoScenario.build(
      skipPurple: costs.skip.purpleCost,
      skipAllPurple: costs.skipAll.purpleCost,
    );
    _machine = PowerDemoMachine(_scenario);
    return _machine.initial();
  }

  void start() => state = _machine.start(state);

  void usePower(DemoPower power) => state = _machine.usePower(state, power);

  void selectAnswer(int index) => state = _machine.selectAnswer(state, index);

  /// Seçimi onaylar; **doğruysa** `true`. Yok sayılan onay (yanlış faz, şık seçilmemiş) yanlış
  /// cevap DEĞİLDİR: `false` döner ve durum değişmez. Yanlış cevap sayacı makinededir.
  bool submit() {
    final result = _machine.submit(state);
    if (identical(result.next, state)) return false;
    state = result.next;
    return result.correct;
  }

  void rescue() => state = _machine.rescue(state);

  void skip() => state = _machine.skip(state);

  void finishSkipAll() => state = _machine.finishSkipAll(state);
}
