import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/constants/reward_brands.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// Marka görünen adı: özel isim ya da yerelleştirilmiş "Diğer".
String rewardBrandLabel(BuildContext context, String brandKey) =>
    rewardBrandName(brandKey) ?? context.tr('reward_brand_other');
