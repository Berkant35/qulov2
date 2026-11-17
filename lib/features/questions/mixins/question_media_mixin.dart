import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/widgets/image_picker_permission_dialog.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/repositories/question_repository.dart';
import 'package:qulo_v2/features/questions/models/question_media_draft.dart';
import 'package:qulo_v2/features/questions/models/question_media_view.dart';
import 'package:qulo_v2/features/questions/screens/question_create_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';

/// Kaydedilen soruya taslak medyayı uygular (bkz. [QuestionMediaMixin.prepareMediaSync]).
typedef QuestionMediaSync = Future<void> Function(QuestionModel saved);

typedef _MediaStep = ({
  QuestionMediaKind kind,
  Future<Result<Object?>> Function(int orderNum) run,

  /// Adım BAŞARILI olunca yollanan analitik olay.
  String event,
  Map<String, Object> eventParams,
});

/// Soru oluşturma/düzenlemede ses ve fotoğraf taslağı: kayıt, seçim, kaldırma
/// ve metin kaydından SONRA sırayla yükleme.
///
/// Medya hatası metin sorusunu silmez — soru metinle kalır, tek mesaj gösterilir.
mixin QuestionMediaMixin on ConsumerState<QuestionCreateScreen> {
  static const _conflictCode = 'QUESTION_MEDIA_CONFLICT';
  static const _featureDisabledCode = 'FEATURE_DISABLED';
  static const _msPerSecond = Duration.millisecondsPerSecond;

  QuestionMediaDraft mediaDraft = const QuestionMediaDraft();
  bool isRecordingVoice = false;
  bool isUploadingMedia = false;

  /// Sunucu `FEATURE_DISABLED` dedi (bayrak config çekildikten sonra kapandı).
  bool mediaFeatureDisabled = false;

  QuestionModel? get _editing => widget.editQuestion;

  bool showMediaSection(bool flagEnabled) =>
      flagEnabled && !mediaFeatureDisabled;

  // ─── Önizleme ───

  QuestionMediaView get mediaView => QuestionMediaView(
        voiceSource: voicePreviewSource,
        voiceSeconds: voicePreviewSeconds,
        isRecording: isRecordingVoice,
        imageBytes: imagePreviewBytes,
        imageUrl: imagePreviewUrl,
        imageInReview: imageInReview,
        imageRejected: imageRejected,
      );

  String? get voicePreviewSource {
    final file = mediaDraft.voiceFile;
    if (file != null) return Uri.file(file.path).toString();
    return mediaDraft.removeVoice ? null : _editing?.voiceUrl;
  }

  int get voicePreviewSeconds {
    final ms = mediaDraft.hasVoiceUpload
        ? mediaDraft.voiceDurationMs
        : _editing?.voiceDurationMs;
    return ((ms ?? 0) / _msPerSecond).ceil();
  }

  Uint8List? get imagePreviewBytes => mediaDraft.imageBytes;

  bool get _imageDraftChanged =>
      mediaDraft.hasImageUpload || mediaDraft.removeImage;

  String? get imagePreviewUrl => _imageDraftChanged ? null : _editing?.imageUrl;

  QuestionImageStatus? get _savedImageStatus =>
      _imageDraftChanged ? null : _editing?.imageStatus;

  bool get imageInReview => _savedImageStatus == QuestionImageStatus.pending;

  /// Sunucu görseli reddetti ve sildi; soru metinle duruyor.
  bool get imageRejected =>
      _savedImageStatus == QuestionImageStatus.rejected && imagePreviewUrl == null;

  // ─── Ses ───

  void startVoiceRecording() => setState(() => isRecordingVoice = true);

  /// Overlay kapanır (dispose'ta mikrofonu kendisi bırakır).
  void cancelVoiceRecording() {
    if (mounted) setState(() => isRecordingVoice = false);
  }

  void onVoiceRecorded(String path, int seconds) {
    // Sunucu 1..15000 ms doğrular; 1 sn'den kısa kayıt 0 saniye sayılıyor.
    final durationMs = (seconds * _msPerSecond).clamp(
      _msPerSecond,
      AppConstants.questionVoiceMaxSeconds * _msPerSecond,
    );
    setState(() {
      isRecordingVoice = false;
      mediaDraft = mediaDraft.withVoice(File(path), durationMs);
    });
  }

  void removeVoice() {
    final hasSaved = _editing?.voiceUrl != null || _editing?.voiceDurationMs != null;
    setState(() => mediaDraft = mediaDraft.withoutVoice(removeExisting: hasSaved));
  }

  // ─── Fotoğraf ───

  Future<void> pickQuestionImage() async {
    final source = await ref
        .read(navigationServiceProvider)
        .showAppBottomSheet<ImageSource>(
          ListBottomSheet<ImageSource>(
            name: 'question_image_source',
            options: [
              SheetOption(
                label: context.tr('from_gallery'),
                icon: Icons.photo_library_outlined,
                value: ImageSource.gallery,
              ),
              SheetOption(
                label: context.tr('from_camera'),
                icon: Icons.camera_alt_outlined,
                value: ImageSource.camera,
              ),
            ],
          ),
        );
    if (source == null || !mounted) return;

    final picker = ref.read(imagePickerManagerProvider);
    final picked = await pickWithPermissionPrompt(
      ref,
      context,
      () => picker.pickAndCrop(context, source),
    );
    if (picked == null || !mounted) return;
    setImageDraft(picked.bytes, picked.mimeType);
  }

  void setImageDraft(Uint8List bytes, String mimeType) =>
      setState(() => mediaDraft = mediaDraft.withImage(bytes, mimeType));

  /// Kayıtlı görseli (ya da yalnız kalan ret notunu) kaldırır. Reddedilen
  /// görselde yol sunucuda zaten boş; `removeMedia(image)` ret durumunu da
  /// temizler — yoksa not her açılışta yeniden görünür.
  void removeImage() {
    final hasSaved = _editing?.imageUrl != null || _editing?.imageStatus != null;
    setState(() => mediaDraft = mediaDraft.withoutImage(removeExisting: hasSaved));
  }

  // ─── Kayıt sonrası yükleme ───

  /// Kayıt başında, await'lerden ÖNCE çağrılır: depo, liste ve taslak burada
  /// alınır — kayıt sürerken ekran kapanırsa medya yine yüklenir, yalnız mesaj
  /// gösterilmez. Taslak boşsa no-op.
  QuestionMediaSync prepareMediaSync() {
    final draft = mediaDraft;
    if (draft.isEmpty) return (_) async {};
    final repo = ref.read(questionRepositoryProvider);
    final questions = ref.read(questionProvider.notifier);
    return (saved) => _syncMedia(saved, draft, repo, questions);
  }

  Future<void> _syncMedia(
    QuestionModel saved,
    QuestionMediaDraft draft,
    QuestionRepository repo,
    QuestionNotifier questions,
  ) async {
    if (mounted) setState(() => isUploadingMedia = true);

    var orderNum = saved.orderNum;
    var failed = false;
    var featureDisabled = false;
    QuestionImageStatus? imageStatus;

    for (final step in _mediaSteps(draft, repo)) {
      var result = await step.run(orderNum);
      if (_hasCode(result, _conflictCode)) {
        // Eşzamanlı değişiklik: listeyi bir kez tazele, bir kez tekrar dene.
        orderNum = await _currentOrderNum(repo, saved, orderNum);
        result = await step.run(orderNum);
      }
      if (_hasCode(result, _featureDisabledCode)) {
        featureDisabled = true;
        break;
      }
      switch (result) {
        case Success(:final data):
          AnalyticsManager.instance.logEvent(step.event, params: step.eventParams);
          if (step.kind == QuestionMediaKind.image && data is QuestionModel) {
            imageStatus = data.imageStatus;
          }
        case Failure():
          failed = true;
      }
    }

    // Sahip imzalı URL'leri ve görsel durumunu sunucudan görsün.
    unawaited(questions.fetchQuestions());
    if (!mounted) return;
    setState(() {
      isUploadingMedia = false;
      if (featureDisabled) mediaFeatureDisabled = true;
    });
    final messageKey = _outcomeMessageKey(
      featureDisabled: featureDisabled,
      failed: failed,
      imageStatus: imageStatus,
    );
    if (messageKey != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(messageKey))));
    }
  }

  /// Ses önce, görsel sonra. Yeni dosya varsa yüklenir (eskinin yerine geçer);
  /// yoksa kaldırma bayrağı sunucudakini siler.
  List<_MediaStep> _mediaSteps(QuestionMediaDraft d, QuestionRepository repo) => [
        if (d.hasVoiceUpload)
          (
            kind: QuestionMediaKind.voice,
            run: (o) => repo.uploadVoice(o, d.voiceFile!, d.voiceDurationMs!),
            event: AnalyticsEvents.questionVoiceAdded,
            eventParams: {AnalyticsEvents.paramDurationMs: d.voiceDurationMs!},
          )
        else if (d.removeVoice)
          (
            kind: QuestionMediaKind.voice,
            run: (o) => repo.removeMedia(o, QuestionMediaKind.voice),
            event: AnalyticsEvents.questionMediaRemoved,
            eventParams: {AnalyticsEvents.paramType: AnalyticsEvents.mediaTypeVoice},
          ),
        if (d.hasImageUpload)
          (
            kind: QuestionMediaKind.image,
            run: (o) => repo.uploadImage(o, d.imageBytes!, d.imageMime!),
            event: AnalyticsEvents.questionImageAdded,
            eventParams: const {},
          )
        else if (d.removeImage)
          (
            kind: QuestionMediaKind.image,
            run: (o) => repo.removeMedia(o, QuestionMediaKind.image),
            event: AnalyticsEvents.questionMediaRemoved,
            eventParams: {AnalyticsEvents.paramType: AnalyticsEvents.mediaTypeImage},
          ),
      ];

  Future<int> _currentOrderNum(
    QuestionRepository repo,
    QuestionModel saved,
    int fallback,
  ) async {
    final fresh = switch (await repo.getMyQuestions()) {
      Success(:final data) => data.where((q) => q.id == saved.id).firstOrNull,
      Failure() => null,
    };
    return fresh?.orderNum ?? fallback;
  }

  static bool _hasCode(Result<Object?> result, String code) => switch (result) {
        Failure(failure: ServerFailure(code: final c)) => c == code,
        _ => false,
      };

  /// Tek mesaj: kapı kapandı > yükleme hatası > görsel reddi > inceleme.
  static String? _outcomeMessageKey({
    required bool featureDisabled,
    required bool failed,
    required QuestionImageStatus? imageStatus,
  }) {
    if (featureDisabled) return 'question_media_unavailable';
    if (failed) return 'question_media_upload_failed';
    return switch (imageStatus) {
      QuestionImageStatus.rejected => 'question_image_rejected',
      QuestionImageStatus.pending => 'question_image_in_review_notice',
      _ => null,
    };
  }
}
