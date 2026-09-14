import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/data/models/message_model.dart';

/// [ChatMessageItem] turetmeleri: gun ayiricisi.
mixin ChatMessageItemMixin {
  /// Ters sirali listede (en yeni altta) mesajin ustune gun ayiricisi
  /// gerekiyorsa o gun, gerekmiyorsa null.
  ///
  /// Sonraki (daha eski) mesaj baska bir gundeyse ayirici konur; en eski
  /// mesajin ([isLast]) ustunde her zaman vardir. Zaman okunamazsa konmaz.
  DateTime? separatorDay({
    required DateTime? msgTime,
    required MessageModel? next,
    required bool isLast,
  }) {
    if (msgTime == null) return null;
    final msgDay = FormatManager.dayOf(msgTime.toLocal());
    if (next == null) return isLast ? msgDay : null;
    final nextTime = DateTime.tryParse(next.createdAt ?? '');
    if (nextTime == null) return null;
    return msgDay == FormatManager.dayOf(nextTime.toLocal()) ? null : msgDay;
  }
}
