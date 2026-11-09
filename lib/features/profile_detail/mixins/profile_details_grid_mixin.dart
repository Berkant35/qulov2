import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_detail_chip.dart';

/// `ProfileDetailsGrid` widget'ının sunum-dışı logic'i: dolu detay alanlarından
/// chip listesi kurma ve evet/hayır/bazen etiket eşlemesi.
///
/// Widget stateless olduğundan `on` kısıtı olmadan mixlenir; `context`
/// parametre olarak geçer (bkz. `DetailChipsWidgetMixin`).
mixin ProfileDetailsGridWidgetMixin {
  /// Yalnız dolu alanlar, sabit sırayla; hiçbiri dolu değilse boş liste.
  List<ProfileDetailChipData> detailChips(
    BuildContext context,
    UserDetailsModel details,
  ) {
    final height = details.height;
    final entries = <(String, String?)>[
      (QIcons.icHeight, height == null ? null : context.fmt.height(height)),
      (QIcons.icZodiac, details.zodiac),
      (QIcons.icJob, details.job),
      (QIcons.icSchool, details.school),
      (QIcons.icSmoke, frequencyLabel(context, details.smoking)),
      (QIcons.icUseAlcohol, frequencyLabel(context, details.alcohol)),
      (QIcons.icPets, details.pets),
      (QIcons.icMusic, details.musicType),
      (QIcons.icPersonality, details.personality),
    ];
    return [
      for (final (icon, label) in entries)
        if (label != null && label.isNotEmpty)
          ProfileDetailChipData(iconAsset: icon, label: label),
    ];
  }

  /// `YES`/`NO`/`SOMETIMES` (harf duyarsız) → yerel etiket; bilinmeyen değer
  /// olduğu gibi kalır, boş/null değer `null` (chip çizilmez).
  String? frequencyLabel(BuildContext context, String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value.toUpperCase()) {
      'YES' => context.tr('yes'),
      'NO' => context.tr('no'),
      'SOMETIMES' => context.tr('freq_sometimes'),
      _ => value,
    };
  }
}
