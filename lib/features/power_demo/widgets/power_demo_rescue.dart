import 'package:flutter/material.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_feedback_overlay.dart';
import 'package:qulo_v2/features/quiz/widgets/rescue_cards.dart';

/// Yanlış cevapta gerçek quiz'in kurtarma ekranı (✗ + [RescueCards]); demoda Doğru Say bedava.
class PowerDemoRescue extends StatelessWidget {
  const PowerDemoRescue({super.key, required this.onRescue, required this.onDecline});

  /// Envanterde 1 Doğru Say, mor fiyat yok: kurtarma kartı "hakkın var" diye görünür.
  static const _freeSkip = RescuePowerOption(type: PowerType.skip, inventoryCount: 1, diamondCost: 0);

  final VoidCallback onRescue;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return AnswerFeedbackOverlay(
      isCorrect: false,
      canRescue: true,
      skipOption: _freeSkip,
      onRescue: (_) => onRescue(),
      onDeclineRescue: onDecline,
      onComplete: _waitForChoice,
    );
  }

  /// Kurtarılabilir yanlışta katman kendiliğinden kapanmaz; karar kullanıcının.
  static void _waitForChoice() {}
}
