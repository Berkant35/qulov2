import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_view.dart';

/// `power-demo` route'u: auth sonrası girişler (güç marketi ▶, ilk quiz öncesi güç kartı).
///
/// Gömülü [PowerDemoView]'u SafeArea içinde açar; bitişte ya da "Atla"da yalnız sayfayı kapatır
/// (çağıran ekrana döner: market ya da quiz tanıtım kartı). Hiçbir route'a gitmez. Geri tuşuyla
/// çıkış, görünümün dispose'unda "atladı" olarak kaydedilir.
class PowerDemoScreen extends ConsumerWidget {
  const PowerDemoScreen({super.key, this.entryPoint = PowerDemoEntryPoint.market});

  final PowerDemoEntryPoint entryPoint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      // Tam ekran animasyonlu sahne: kendi arka planını boyar, sayfa dolgusu yok.
      showBackground: false,
      padding: null,
      body: PowerDemoView(
        entryPoint: entryPoint,
        onExit: () => ref.read(navigationServiceProvider).pop(),
      ),
    );
  }
}
