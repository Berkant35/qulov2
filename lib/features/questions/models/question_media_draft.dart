import 'dart:io';
import 'dart:typed_data';

/// Soru oluşturma/düzenleme ekranında kaydedilmeyi bekleyen medya değişikliği.
///
/// Yeni dosya varsa kayıttan sonra yüklenir (sunucuda öncekinin yerine geçer);
/// yoksa `remove*` bayrağı sunucudaki mevcut medyayı siler. Taslak yalnız
/// bellekte durur — kayıt yapılmadan ekrandan çıkılırsa hiçbir şey gönderilmez.
class QuestionMediaDraft {
  final File? voiceFile;
  final int? voiceDurationMs;
  final Uint8List? imageBytes;
  final String? imageMime;
  final bool removeVoice;
  final bool removeImage;

  const QuestionMediaDraft({
    this.voiceFile,
    this.voiceDurationMs,
    this.imageBytes,
    this.imageMime,
    this.removeVoice = false,
    this.removeImage = false,
  });

  bool get hasVoiceUpload => voiceFile != null && voiceDurationMs != null;
  bool get hasImageUpload => imageBytes != null && imageMime != null;

  bool get isEmpty =>
      !hasVoiceUpload && !hasImageUpload && !removeVoice && !removeImage;

  QuestionMediaDraft withVoice(File file, int durationMs) => QuestionMediaDraft(
        voiceFile: file,
        voiceDurationMs: durationMs,
        imageBytes: imageBytes,
        imageMime: imageMime,
        removeImage: removeImage,
      );

  /// Taslaktaki sesi atar; [removeExisting] sunucudaki sesi de sildirir.
  QuestionMediaDraft withoutVoice({required bool removeExisting}) =>
      QuestionMediaDraft(
        imageBytes: imageBytes,
        imageMime: imageMime,
        removeVoice: removeExisting,
        removeImage: removeImage,
      );

  QuestionMediaDraft withImage(Uint8List bytes, String mimeType) =>
      QuestionMediaDraft(
        voiceFile: voiceFile,
        voiceDurationMs: voiceDurationMs,
        imageBytes: bytes,
        imageMime: mimeType,
        removeVoice: removeVoice,
      );

  /// Taslaktaki görseli atar; [removeExisting] sunucudaki görseli de sildirir.
  QuestionMediaDraft withoutImage({required bool removeExisting}) =>
      QuestionMediaDraft(
        voiceFile: voiceFile,
        voiceDurationMs: voiceDurationMs,
        removeVoice: removeVoice,
        removeImage: removeExisting,
      );
}
