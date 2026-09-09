import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// Profil kartinin sunum-disi logic'i (etiket eslemesi).
///
/// Proje kurali: widget yalnizca UI orchestration icerir, label/veri eslemesi
/// mixin'e tasinir.
mixin ProfileCardMixin {
  /// `relationship_goal` sunucu enum'unu yerellestirilmis etikete cevirir.
  /// Bilinmeyen/eksik deger "emin degil" tarafina duser.
  String relationshipGoalLabel(BuildContext context, String? goal) {
    return switch (goal) {
      'SERIOUS' => context.tr('serious_relationship'),
      'FRIENDSHIP' => context.tr('friendship'),
      _ => context.tr('not_sure'),
    };
  }
}
