import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/exchange/widgets/convert_section.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

/// [ConvertSection] icin sunum-disi logic: yesil->mor donusum orani,
/// ust sinir hesabi ve donusum akisi.
mixin ConvertSectionMixin on ConsumerState<ConvertSection> {
  double sliderValue = 3;
  bool converting = false;

  int get greenAmount => sliderValue.toInt();
  int get convertRatio =>
      ref.read(exchangeProvider).rates?.convertRatio ??
      ref.read(economyConfigProvider).core.greenToPurpleRatio;
  int get purpleResult => greenAmount ~/ convertRatio;

  int get maxGreen {
    final balance = ref.read(diamondProvider).valueOrNull;
    if (balance == null) return 3;
    final raw = balance.green;
    // Round down to nearest multiple of convertRatio
    final ratio = convertRatio;
    final max = (raw ~/ ratio) * ratio;
    return max < ratio ? ratio : max;
  }

  Future<void> onConvert() async {
    if (converting || greenAmount < convertRatio) return;
    setState(() => converting = true);

    final success = await ref.read(exchangeProvider.notifier).convert(greenAmount);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? context.tr('purchase_success')
                : context.tr('purchase_failed'),
          ),
        ),
      );
      if (success) {
        setState(() => sliderValue = convertRatio.toDouble());
      }
      setState(() => converting = false);
    }
  }
}
