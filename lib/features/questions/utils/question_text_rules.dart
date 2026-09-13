import 'package:qulo_v2/core/constants/app_constants.dart';

/// Soru metni sunucunun alt sinirini (`min(5)`) karsiliyor mu — bosluklar sayilmaz.
bool isQuestionTextLongEnough(String text) =>
    text.trim().length >= AppConstants.minQuestionTextLength;

/// Yazmaya baslanmis ama henuz kisa: alanin altinda uyari gosterilir.
/// Bos alan uyari degil — kullanici henuz yazmadi.
bool isQuestionTextTooShort(String text) =>
    text.trim().isNotEmpty && !isQuestionTextLongEnough(text);
