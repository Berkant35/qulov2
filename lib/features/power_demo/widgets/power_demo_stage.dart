import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_result_line.dart';

/// Soru alanının üstünde aynı anda duran tek katman.
enum PowerDemoLayer {
  none,

  /// Karartma + delik + tek talimat (güç bekleniyor).
  guide,

  /// Yanlış cevap: kurtarma kartı.
  rescue,

  /// Doğru cevap: kısa "Doğru!".
  correct,
}

/// Soru ekranının yerleşimi: kayan soru kartı, varsa sonuç satırı, varsa Cevapla ([confirm]),
/// altta güç çubuğu ve üstte tek katman ([overlay]).
///
/// Küçük ekranda ve büyük yazıda yalnız kart kayar; Cevapla ve çubuk kaydırma alanının DIŞINDA,
/// hep görünür — gerçek quiz'deki `QuizQuestionContent` düzeninin aynısı.
class PowerDemoStage extends StatelessWidget {
  const PowerDemoStage({
    super.key,
    required this.card,
    required this.powerBar,
    required this.resultText,
    required this.confirm,
    required this.overlay,
  });

  final Widget card;
  final Widget powerBar;
  final String? resultText;

  /// Şık seçiliyken Cevapla; yoksa `null`.
  final Widget? confirm;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final resultText = this.resultText;
    final confirm = this.confirm;
    final overlay = this.overlay;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: card,
              ),
            ),
            if (resultText != null) PowerDemoResultLine(text: resultText),
            if (confirm != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: confirm,
              ),
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: AppSpacing.lg,
              ),
              child: powerBar,
            ),
          ],
        ),
        if (overlay != null) Positioned.fill(child: overlay),
      ],
    );
  }
}
