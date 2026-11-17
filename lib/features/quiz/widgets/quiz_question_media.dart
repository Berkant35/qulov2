import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_question_media_mixin.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_media_image.dart';
import 'package:qulo_v2/features/quiz/models/quiz_voice_status.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_voice_player_row.dart';

/// Quiz kartında sorunun sesi ve/veya görseli (2.0.19). Ses bir kez kendiliğinden çalar;
/// oynat/duraklat/tekrar düğmesiyle yönetilir; şıklar bu sırada tıklanabilir (medya engellemez).
/// [onReady] sayacın medya tutmasını bitirir (`QuizTimerState.release`).
class QuizQuestionMedia extends ConsumerStatefulWidget {
  const QuizQuestionMedia({
    super.key,
    required this.voiceUrl,
    required this.voiceDurationMs,
    required this.imageUrl,
    required this.onReady,
  });

  final String? voiceUrl;
  final int? voiceDurationMs;
  final String? imageUrl;
  final VoidCallback onReady;

  @override
  ConsumerState<QuizQuestionMedia> createState() => _QuizQuestionMediaState();
}

class _QuizQuestionMediaState extends ConsumerState<QuizQuestionMedia>
    with QuizQuestionMediaMixin {
  @override
  void initState() {
    super.initState();
    initMedia();
  }

  @override
  void dispose() {
    disposeMedia();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = imageProvider;
    final hasVoice = widget.voiceUrl != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (image != null) QuizMediaImage(image: image, status: imageStatus),
          if (image != null && hasVoice) const SizedBox(height: AppSpacing.sm),
          if (hasVoice)
            ValueListenableBuilder<QuizVoiceStatus>(
              valueListenable: voiceStatus,
              builder: (context, status, _) => status == QuizVoiceStatus.failed
                  ? const SizedBox.shrink()
                  : QuizVoicePlayerRow(
                      status: voiceStatus,
                      position: voicePosition,
                      total: voiceTotal,
                      onToggle: toggleVoice,
                    ),
            ),
        ],
      ),
    );
  }
}
