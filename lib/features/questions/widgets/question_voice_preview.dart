import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/features/chat/widgets/voice_message_widget.dart';
import 'package:qulo_v2/features/questions/mixins/question_voice_preview_mixin.dart';

/// Soru sesinin dinlenebilir önizlemesi + kaldırma. Oynatıcı sohbet sesli
/// mesajıyla aynı (`VoiceMessageWidget`, tekil `AudioPlayerManager`).
class QuestionVoicePreview extends ConsumerStatefulWidget {
  /// Yerel kayıt için `file://` URI, kayıtlı soru için imzalı URL.
  final String source;
  final int durationSeconds;
  final VoidCallback onRemove;

  const QuestionVoicePreview({
    super.key,
    required this.source,
    required this.durationSeconds,
    required this.onRemove,
  });

  @override
  ConsumerState<QuestionVoicePreview> createState() =>
      _QuestionVoicePreviewState();
}

class _QuestionVoicePreviewState extends ConsumerState<QuestionVoicePreview>
    with QuestionVoicePreviewMixin {
  @override
  void initState() {
    super.initState();
    initPreview();
  }

  @override
  void didUpdateWidget(covariant QuestionVoicePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    onSourceChanged(oldWidget.source);
  }

  @override
  void dispose() {
    disposePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: VoiceMessageWidget(
            audioUrl: widget.source,
            durationSeconds: widget.durationSeconds,
            isMine: false,
          ),
        ),
        IconButton(
          onPressed: widget.onRemove,
          tooltip: context.tr('question_media_remove'),
          icon: Icon(Icons.delete_outline, color: context.appColors.error),
        ),
      ],
    );
  }
}
