class InterestConstants {
  static const List<String> tagPool = [
    'music',
    'movies',
    'sports',
    'career',
    'relationships',
    'travel',
    'food',
    'books',
    'gaming',
    'art',
    'fitness',
    'personality',
  ];

  static String localeKey(String tag) => 'interest_$tag';

  static const int minSelect = 1;
  static const int recommendedSelect = 3;
  static const int maxSelect = 12;
}
