import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// [QuestionMediaSection] metin eşlemesi (stateless widget → plain mixin).
mixin QuestionMediaSectionMixin {
  String mediaHint(BuildContext context) => context
      .tr('question_media_hint')
      .replaceAll('{seconds}', '${AppConstants.questionVoiceMaxSeconds}');
}
