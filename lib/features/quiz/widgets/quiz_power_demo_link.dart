import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// İlk quiz öncesi güç kartındaki "Güçleri dene" bağlantısı.
///
/// Demo turun ÜSTÜNE açılır, tur KAPATILMAZ: kapatılırsa `runTour` biter ve `startSession`
/// demo sürerken oturum açar — sunucunun oturum süresi (`expires_at`) akar, quiz FAILED olur.
/// Tur kartı demodan dönünce hâlâ açıktır; oturum kullanıcı kartın düğmesine basınca açılır.
/// Kapatma anahtarı sunucudan `false` gelirse görünmez.
class QuizPowerDemoLink extends ConsumerWidget {
  const QuizPowerDemoLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(powerDemoEnabledProvider)) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () => ref
            .read(navigationServiceProvider)
            .push<void>(RouteNames.powerDemo, extra: PowerDemoEntryPoint.quizIntro),
        icon: const Icon(Icons.play_circle_outline),
        label: Text(context.tr('power_demo_try')),
      ),
    );
  }
}
