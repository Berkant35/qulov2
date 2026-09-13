/// Sohbet sorusu olusturma formunun kurallari — qulo-server
/// `chat-question.validator.ts` `createChatQuestionSchema` ile ayni:
/// soru 3..200, sik 1..100, 2 ya da 4 sik, 4 sikta C ve D zorunlu, 2 sikta
/// dogru cevap yalnizca A/B, ipucu en fazla 200. Uzunluk sinirlarini form
/// alanlari (`maxLength`) zorluyor; burada gonderilebilirlik ve payload var.
bool isChatQuestionStep1Valid({
  required String questionText,
  required int optionCount,
  required String optionA,
  required String optionB,
  required String optionC,
  required String optionD,
  required String correctOption,
}) {
  if (questionText.trim().length < 3) return false;
  if (optionA.trim().isEmpty || optionB.trim().isEmpty) return false;
  if (optionCount == 4) {
    return optionC.trim().isNotEmpty && optionD.trim().isNotEmpty;
  }
  // Sunucu refine'i: 2 sikli soruda C/D dogru cevap 400 alir.
  return correctOption == 'A' || correctOption == 'B';
}

/// Sunucuya giden govde. Alan adlari sozlesmeyle birebir — ozellikle
/// `use_power_block` (istek adi; yanit `has_power_block` doner).
Map<String, dynamic> buildChatQuestionPayload({
  required String questionText,
  required int optionCount,
  required String optionA,
  required String optionB,
  required String optionC,
  required String optionD,
  required String correctOption,
  required int timeLimitSeconds,
  required String hintText,
  required String? rewardMediaUrl,
  required String? rewardMediaType,
  required bool hasUnmatchRisk,
  required bool hasChatLock,
  required bool hasPowerBlock,
}) {
  final data = <String, dynamic>{
    'question_text': questionText.trim(),
    'option_count': optionCount,
    'option_a': optionA.trim(),
    'option_b': optionB.trim(),
    'correct_option': correctOption,
    'time_limit_seconds': timeLimitSeconds,
    'has_unmatch_risk': hasUnmatchRisk,
    'has_chat_lock': hasChatLock,
    'use_power_block': hasPowerBlock,
  };
  if (optionCount == 4) {
    data['option_c'] = optionC.trim();
    data['option_d'] = optionD.trim();
  }
  if (hintText.trim().isNotEmpty) {
    data['hint_text'] = hintText.trim();
  }
  if (rewardMediaUrl != null) {
    data['reward_media_url'] = rewardMediaUrl;
    data['reward_media_type'] = rewardMediaType;
  }
  return data;
}
