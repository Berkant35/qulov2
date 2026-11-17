import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/features/chat/widgets/voice_recorder_overlay.dart';
import 'package:qulo_v2/features/questions/mixins/question_media_section_mixin.dart';
import 'package:qulo_v2/features/questions/models/question_media_view.dart';
import 'package:qulo_v2/features/questions/widgets/question_image_preview.dart';
import 'package:qulo_v2/features/questions/widgets/question_image_rejected_note.dart';
import 'package:qulo_v2/features/questions/widgets/question_voice_preview.dart';

/// Soru adımındaki isteğe bağlı ses (≤15 sn) ve fotoğraf bölümü. Durum ve
/// eylemler `QuestionMediaMixin`'den gelir; burada yalnız dizilim var.
class QuestionMediaSection extends StatelessWidget
    with QuestionMediaSectionMixin {
  final QuestionMediaView view;
  final VoidCallback onRecordTap;
  final void Function(String filePath, int durationSeconds) onRecordComplete;
  final VoidCallback onRecordCancel;
  final VoidCallback onRemoveVoice;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const QuestionMediaSection({
    super.key,
    required this.view,
    required this.onRecordTap,
    required this.onRecordComplete,
    required this.onRecordCancel,
    required this.onRemoveVoice,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceSource = view.voiceSource;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('question_media_title'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          mediaHint(context),
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (view.isRecording)
          VoiceRecorderOverlay(
            maxDurationSeconds: AppConstants.questionVoiceMaxSeconds,
            onRecordComplete: onRecordComplete,
            onCancel: onRecordCancel,
          )
        else if (voiceSource != null)
          QuestionVoicePreview(
            source: voiceSource,
            durationSeconds: view.voiceSeconds,
            onRemove: onRemoveVoice,
          )
        else
          AppButton(
            label: context.tr('question_media_add_voice'),
            variant: AppButtonVariant.secondary,
            icon: Icons.mic_none,
            fullWidth: false,
            onPressed: onRecordTap,
          ),
        const SizedBox(height: AppSpacing.md),
        if (view.hasImage)
          QuestionImagePreview(
            bytes: view.imageBytes,
            url: view.imageUrl,
            inReview: view.imageInReview,
            onRemove: onRemoveImage,
          )
        else ...[
          if (view.imageRejected) ...[
            QuestionImageRejectedNote(onDismiss: onRemoveImage),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppButton(
            label: context.tr('question_media_add_image'),
            variant: AppButtonVariant.secondary,
            icon: Icons.add_photo_alternate_outlined,
            fullWidth: false,
            onPressed: onPickImage,
          ),
        ],
      ],
    );
  }
}
