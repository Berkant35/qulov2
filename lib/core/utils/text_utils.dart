/// Strip unresolved {placeholder} tokens from notification body.
String sanitizeNotificationBody(String body) {
  final cleaned = body
      .replaceAll(RegExp(r'\{\w+\}'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return cleaned.isEmpty ? 'Yeni bildirim' : cleaned;
}
