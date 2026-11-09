abstract final class AppDurations {
  // Splash — Glitch Reveal
  static const splashGlitch = Duration(milliseconds: 1000);
  static const splashGlowSettle = Duration(milliseconds: 500);
  static const splashMinDisplay = Duration(milliseconds: 3000);
  static const splashFadeOut = Duration(milliseconds: 300);

  // Transitions
  static const fadeTransition = Duration(milliseconds: 500);
  static const pageTransition = Duration(milliseconds: 300);

  // General
  /// Kaydırma alanında bir öğeyi görünür alana getirme (ör. seçilen şık).
  static const scrollReveal = Duration(milliseconds: 250);
  static const snackBar = Duration(seconds: 3);
  static const debounce = Duration(milliseconds: 300);
  static const navigationThrottle = Duration(milliseconds: 500);

  // Sohbet Realtime (chat-flow-guard: typing 3 sn, medya 500 ms)
  /// Karşı tarafın "yazıyor" göstergesi son olaydan bu kadar sonra söner.
  static const typingIndicator = Duration(seconds: 3);
  /// Hızlı ardışık medya isteği değişikliklerinde tek API çağrısı.
  static const mediaRequestDebounce = Duration(milliseconds: 500);
}
