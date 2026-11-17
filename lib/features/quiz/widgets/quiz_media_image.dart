import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/quiz/models/quiz_media_image_status.dart';

/// Quiz soru görseli: yüklenirken yer tutucu, yüklenince görsel, hata olursa hiçbir şey
/// (kart metinle çözülür).
class QuizMediaImage extends StatelessWidget {
  /// Soru görselleri CropScreen'den 3:4 dikey gelir; kırpılmadan bu oranda gösterilir.
  static const double _aspectRatio = 3 / 4;

  /// Şıklar görünür kalsın: görsel ekran yüksekliğinin en çok bu kadarını kaplar.
  static const double _maxHeightFraction = 0.4;

  const QuizMediaImage({super.key, required this.image, required this.status});

  final ImageProvider image;
  final QuizMediaImageStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == QuizMediaImageStatus.failed) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFraction,
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: status == QuizMediaImageStatus.loaded
                ? Image(
                    image: image,
                    fit: BoxFit.contain,
                    semanticLabel: context.tr('quiz_question_image'),
                  )
                : ColoredBox(
                    color: context.appColors.surfaceElevated,
                    child: const Center(child: AppLoadingWidget.small()),
                  ),
          ),
        ),
      ),
    );
  }
}
