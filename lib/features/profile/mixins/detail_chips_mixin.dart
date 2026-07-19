import 'package:flutter/material.dart';

import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';
import 'package:qulo_v2/features/profile/widgets/detail_chip_item.dart';

/// [DetailChips] widget'ının sunum-dışı logic'i: frekans etiketi eşleme ve
/// kullanıcı detaylarından chip listesi kurma.
///
/// Widget class'ları (page/widget) yalnızca UI orchestration içerir; çalıştırılan
/// fonksiyonlar bu mixin'de toplanır. DetailChips stateless ([ConsumerWidget])
/// olduğundan `on` kısıtı olmadan mixlenir; `context` parametre olarak geçer.
mixin DetailChipsWidgetMixin {
  String frequencyLabel(BuildContext context, String? value) {
    switch (value) {
      case 'YES':
        return context.tr('freq_yes');
      case 'NO':
        return context.tr('freq_no');
      case 'SOMETIMES':
        return context.tr('freq_sometimes');
      default:
        return '';
    }
  }

  List<ChipData> buildChips(
    BuildContext context, {
    required UserDetailsModel? details,
    required String? locationLabel,
  }) {
    return [
      if (locationLabel != null && locationLabel.isNotEmpty)
        ChipData(
          icon: QIcons.icLocation,
          filled: true,
          label: locationLabel,
        ),
      ChipData(
        icon: QIcons.icHeight,
        filled: details?.height != null,
        label: details?.height != null
            ? '${details!.height} cm'
            : context.tr('height'),
      ),
      ChipData(
        icon: QIcons.icJob,
        filled: details?.job != null,
        label: details?.job ?? context.tr('job'),
      ),
      ChipData(
        icon: QIcons.icSchool,
        filled: details?.school != null,
        label: details?.school ?? context.tr('school'),
      ),
      ChipData(
        icon: QIcons.icZodiac,
        filled: details?.zodiac != null,
        label: details?.zodiac ?? context.tr('zodiac'),
      ),
      ChipData(
        icon: QIcons.icSmoke,
        filled: details?.smoking != null,
        label: details?.smoking != null
            ? frequencyLabel(context, details!.smoking)
            : context.tr('smoking'),
      ),
      ChipData(
        icon: QIcons.icUseAlcohol,
        filled: details?.alcohol != null,
        label: details?.alcohol != null
            ? frequencyLabel(context, details!.alcohol)
            : context.tr('alcohol'),
      ),
      ChipData(
        icon: QIcons.icPets,
        filled: details?.pets != null,
        label: details?.pets ?? context.tr('pets'),
      ),
      ChipData(
        icon: QIcons.icMusic,
        filled: details?.musicType != null,
        label: details?.musicType ?? context.tr('music'),
      ),
      ChipData(
        icon: QIcons.icPersonality,
        filled: details?.personality != null,
        label: details?.personality ?? context.tr('personality'),
      ),
    ];
  }
}
