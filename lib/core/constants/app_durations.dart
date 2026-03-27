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
  static const snackBar = Duration(seconds: 3);
  static const debounce = Duration(milliseconds: 300);
  static const navigationThrottle = Duration(milliseconds: 500);
}
