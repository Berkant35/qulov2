import 'package:flutter/material.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/quiz/mixins/power_help_preview_mixin.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_scene.dart';

/// "?" baloncuğunun minyatürü: gerçek quiz'in ortak efekti küçük bir sahnede döngüyle oynar.
///
/// Sahne [canvas] boyutunda çizilip [size]'a küçültülür; efektler gerçek oranlarıyla görünür.
class PowerHelpPreview extends StatefulWidget {
  const PowerHelpPreview({
    super.key,
    required this.type,
    required this.oraclePercent,
    required this.hintText,
    required this.timeExtendSeconds,
  });

  static const Size size = Size(88, 52);
  static const Size canvas = Size(176, 104);

  final PowerType type;
  final String oraclePercent;
  final String hintText;
  final int timeExtendSeconds;

  @override
  State<PowerHelpPreview> createState() => _PowerHelpPreviewState();
}

class _PowerHelpPreviewState extends State<PowerHelpPreview> with PowerHelpPreviewMixin {
  @override
  void initState() {
    super.initState();
    initPreview();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncPreviewMotion();
  }

  @override
  void dispose() {
    disposePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: PowerHelpPreview.size,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: PowerHelpPreview.canvas,
          child: PowerHelpScene(
            type: widget.type,
            shown: shown,
            round: round,
            oraclePercent: widget.oraclePercent,
            hintText: widget.hintText,
            timeExtendSeconds: widget.timeExtendSeconds,
          ),
        ),
      ),
    );
  }
}
