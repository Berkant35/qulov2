/// Cozulmemis {placeholder} token'larini siler; bos kalirsa cevrilmis [fallback].
String sanitizeNotificationBody(String body, {required String fallback}) {
  final cleaned = body
      .replaceAll(RegExp(r'\{\w+\}'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return cleaned.isEmpty ? fallback : cleaned;
}
