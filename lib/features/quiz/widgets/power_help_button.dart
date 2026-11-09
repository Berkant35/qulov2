import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/features/quiz/mixins/power_effect_labels_mixin.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_bubble.dart';

/// Quiz güç butonunun üstündeki küçük "?": o gücün açıklama baloncuğunu açar/kapatır.
///
/// Dokunma alanı güç butonundan AYRI bir şerit (sütun genişliği × [height]); güç butonuyla
/// arasındaki [gap] boşluğunu çağıran koyar. Yanlış dokunuş onaysız mor harcatmasın diye "?"
/// şeridinin hiçbir noktası gücü tetiklemez (spec §13.2/6). İkon küçük kalır ve şeridin
/// altında durur; dokunma alanı YUKARI doğru büyür (güç butonuna doğru değil). Yalnız gerçek
/// quiz `PowerBar`'da; sohbetin güç çubuğunda yok.
class PowerHelpButton extends StatelessWidget with PowerEffectLabelsMixin {
  const PowerHelpButton({
    super.key,
    required this.type,
    required this.isOpen,
    required this.onTap,
  });

  /// `PowerBarButton` sütun genişliği (56) ile aynı.
  static const double width = AppSpacing.xxxl + AppSpacing.sm;

  /// Rahat dokunma yüksekliği (40); ikon bunun altında.
  static const double height = AppSpacing.xxl + AppSpacing.sm;

  /// Güç butonuyla arasındaki boşluk: "?"ye hafif aşağıdan dokunmak güce düşmesin.
  static const double gap = AppSpacing.sm;
  static const double _iconSize = AppSpacing.md + AppSpacing.xxs;

  final PowerType type;

  /// Bu gücün baloncuğu açık: ikon dolu ve güç renginde.
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = isOpen ? QIcons.helpCircle.filled : QIcons.helpCircle.outlined;
    // Baloncukla aynı grup: "?"ye dokunmak baloncuğun "dışına" dokunmak sayılmaz.
    return TapRegion(
      groupId: PowerHelpBubble.tapGroup,
      child: Semantics(
        button: true,
        label: powerDescription(context, type),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: height,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: QIcon(
                icon,
                size: _iconSize,
                color: isOpen ? type.color : context.appColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
