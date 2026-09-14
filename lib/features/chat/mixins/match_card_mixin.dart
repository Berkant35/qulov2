import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/data/models/message_model.dart';

/// [MatchCard] metin turetmeleri: son mesaj onizlemesi ve goreli zaman.
mixin MatchCardMixin {
  /// Mesaj yoksa sehir; soru mesajiysa yerellestirilmis "soru gonderildi".
  String lastMessagePreview(BuildContext context, MatchModel match) {
    final msg = match.lastMessage;
    if (msg == null || msg.isEmpty) return match.user?.city ?? '';
    if (msg.startsWith(MessageModel.questionPrefix)) {
      return '🎯 ${context.tr('chat_question_sent')}';
    }
    return msg;
  }

  String relativeTime(BuildContext context, String isoTime) {
    final dt = DateTime.tryParse(isoTime);
    return dt == null ? '' : context.fmt.relativeShort(dt);
  }
}
