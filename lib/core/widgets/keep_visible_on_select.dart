import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';

/// Seçilince ([selected] false → true) çocuğunu en yakın kaydırma alanında tam görünür tutar.
///
/// Şık seçilince soru alanının altında Cevapla belirir ve alan daralır: alt kenardaki seçili
/// şık kırpılmasın diye bir sonraki karede (daralmış alan ölçüldükten sonra) yalnız gerektiği
/// kadar aşağı kaydırılır; şık zaten görünürse hiç kaydırılmaz. Gerçek quiz ve güç demosu ortak.
class KeepVisibleOnSelect extends StatefulWidget {
  const KeepVisibleOnSelect({
    super.key,
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  State<KeepVisibleOnSelect> createState() => _KeepVisibleOnSelectState();
}

class _KeepVisibleOnSelectState extends State<KeepVisibleOnSelect> {
  @override
  void didUpdateWidget(KeepVisibleOnSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  void _reveal() {
    if (!mounted || Scrollable.maybeOf(context) == null) return;
    Scrollable.ensureVisible(
      context,
      duration: reduceMotionOf(context)
          ? Duration.zero
          : AppDurations.scrollReveal,
      curve: Curves.easeOut,
      // Yalnız alt kenar alanın dışındaysa kaydırır; görünür şıkta yerinden oynatmaz.
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
