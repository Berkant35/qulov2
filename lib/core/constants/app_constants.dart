abstract final class AppConstants {
  static const int maxPhotos = 6;
  static const int minQuestions = 2;
  static const int maxQuestions = 6;

  static const List<String> questionCategories = [
    'personality', 'music', 'film', 'sports', 'travel',
    'food', 'technology', 'general', 'fun', 'entertainment',
    'lifestyle', 'humor', 'hobby', 'science', 'history',
    'art', 'nature', 'other',
  ];

  static const supportedQuestionLocales = [
    'tr', 'en', 'de', 'fr', 'es', 'ar', 'ru',
    'pt', 'it', 'ja', 'ko', 'zh', 'nl', 'pl', 'sv',
  ];

  static const localeFlagEmojis = <String, String>{
    'tr': '\u{1F1F9}\u{1F1F7}',
    'en': '\u{1F1EC}\u{1F1E7}',
    'de': '\u{1F1E9}\u{1F1EA}',
    'fr': '\u{1F1EB}\u{1F1F7}',
    'es': '\u{1F1EA}\u{1F1F8}',
    'ar': '\u{1F1F8}\u{1F1E6}',
    'ru': '\u{1F1F7}\u{1F1FA}',
    'pt': '\u{1F1E7}\u{1F1F7}',
    'it': '\u{1F1EE}\u{1F1F9}',
    'ja': '\u{1F1EF}\u{1F1F5}',
    'ko': '\u{1F1F0}\u{1F1F7}',
    'zh': '\u{1F1E8}\u{1F1F3}',
    'nl': '\u{1F1F3}\u{1F1F1}',
    'pl': '\u{1F1F5}\u{1F1F1}',
    'sv': '\u{1F1F8}\u{1F1EA}',
  };
}

abstract final class NotificationTypes {
  static const newMessage = 'new_message';
  static const newMessageImage = 'new_message_image';
  static const newMatch = 'new_match';
  static const newMatchSolver = 'new_match_solver';
  static const passportExpired = 'passport_expired';
  static const campaign = 'campaign';
  static const chatQuestionAnswered = 'chat_question_answered';
}
