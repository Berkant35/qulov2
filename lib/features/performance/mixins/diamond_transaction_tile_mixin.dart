import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// `DiamondTransactionTile` sunum logic'i (stateless widget → plain mixin).
mixin DiamondTransactionTileMixin {
  /// Sunucunun `created_at` ISO metni → yerel tarih; okunamazsa bos.
  String formattedDate(BuildContext context, String createdAt) {
    final dt = DateTime.tryParse(createdAt);
    return dt == null ? '' : context.fmt.date(dt);
  }
}
