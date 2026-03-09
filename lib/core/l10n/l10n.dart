export 'app_localizations.dart';

import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key) => AppLocalizations.of(this).get(key);
}
