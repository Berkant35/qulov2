import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/quiz/quiz_power_rules.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';

/// `PowerBar`'in sunum disi logic'i — widget sadece UI orchestration yapar.
mixin PowerBarMixin {
  static const List<PowerType> _allPowers = [
    PowerType.oracle,
    PowerType.half,
    PowerType.skip,
    PowerType.hint,
    PowerType.timeExtend,
    PowerType.skipAll,
  ];

  /// Gosterilecek gucler.
  ///
  /// HINT: sorunun ipucu yoksa guc gercekten yok — gizlenir.
  /// SKIP_ALL: sadece avantajliysa gosterilir (bkz. `shouldOfferSkipAll`).
  List<PowerType> visiblePowers(QuizState quiz, {required bool hasHint}) {
    final skipAllWorthIt = shouldOfferSkipAll(quiz);

    return _allPowers.where((type) {
      if (type == PowerType.hint) return hasHint;
      if (type == PowerType.skipAll) return skipAllWorthIt;
      return true;
    }).toList();
  }

  String powerLabel(BuildContext context, PowerType type) => switch (type) {
        PowerType.oracle => context.tr('power_bar_oracle'),
        PowerType.half => context.tr('power_bar_half'),
        PowerType.skip => context.tr('power_bar_skip'),
        PowerType.hint => context.tr('power_bar_hint'),
        PowerType.timeExtend => context.tr('power_bar_time'),
        PowerType.skipAll => context.tr('power_bar_skip_all'),
        PowerType.powerBlock => context.tr('power_bar_block'),
        PowerType.powerUnblock => context.tr('power_bar_unlock'),
      };
}
