import 'dart:typed_data';

/// Ses/fotoğraf bölümünün çizim durumu — `QuestionMediaMixin.mediaView` üretir.
class QuestionMediaView {
  /// Yerel kayıt için `file://` URI, kayıtlı soru için imzalı URL; yoksa null.
  final String? voiceSource;
  final int voiceSeconds;
  final bool isRecording;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool imageInReview;
  final bool imageRejected;

  const QuestionMediaView({
    required this.voiceSource,
    required this.voiceSeconds,
    required this.isRecording,
    required this.imageBytes,
    required this.imageUrl,
    required this.imageInReview,
    required this.imageRejected,
  });

  bool get hasImage => imageBytes != null || imageUrl != null;
}
