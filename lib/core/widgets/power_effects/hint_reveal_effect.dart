import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_player.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

/// HINT: sorunun altında ipucu kartı açılır (yükseklik + opaklık birlikte).
///
/// [text] `null → metin` olunca açılır, `metin → null` olunca kapanır (kapanırken metin
/// kaybolmaz, bitince ağaçtan çıkar). Açıkken metin değişirse yeniden oynamaz. İlk build
/// metinliyse animasyonsuz açık gelir. Kart kullanılabilir genişliği doldurur.
class HintRevealEffect extends StatefulWidget {
  const HintRevealEffect({super.key, required this.text});

  final String? text;

  @override
  State<HintRevealEffect> createState() => _HintRevealEffectState();
}

class _HintRevealEffectState extends State<HintRevealEffect>
    with SingleTickerProviderStateMixin, PowerEffectPlayer<HintRevealEffect> {
  /// Kapanış sırasında `widget.text` null olur; kartın içeriği boşalmasın diye son metin tutulur.
  String? _shown;

  late final Animation<double> _reveal = phase(0, 1);

  @override
  void initState() {
    super.initState();
    _shown = widget.text;
    settleAt(widget.text == null ? 0 : 1);
  }

  @override
  void didUpdateWidget(HintRevealEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.text;
    if (text != null) _shown = text;
    if (text != null && oldWidget.text == null) playIn();
    if (text == null && oldWidget.text != null) playOut();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown == null) return const SizedBox.shrink();
    return whenActive(
      () => SizeTransition(
        sizeFactor: _reveal,
        axisAlignment: -1,
        child: FadeTransition(opacity: _reveal, child: _HintCard(text: shown)),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});

  static const _tintAlpha = 0.12;
  static const _borderAlpha = 0.5;

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: _tintAlpha),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.warning.withValues(alpha: _borderAlpha)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QIcon(QIcons.icLightbulb, size: AppSpacing.xl, color: colors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
