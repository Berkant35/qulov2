import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/discover/widgets/question_media_badge.dart';

/// Profil kartında "sesli / görselli soru var" rozetleri (2.0.19). Sunucu bayrakları yalnız
/// kapı açıkken yollar; ikisi de false ise hiçbir şey çizilmez.
class QuestionMediaBadges extends StatelessWidget {
  final bool hasVoice;
  final bool hasImage;

  const QuestionMediaBadges({super.key, required this.hasVoice, required this.hasImage});

  static const _voiceEmoji = '🎤';
  static const _imageEmoji = '📷';

  @override
  Widget build(BuildContext context) {
    if (!hasVoice && !hasImage) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        children: [
          if (hasVoice)
            QuestionMediaBadge(emoji: _voiceEmoji, label: context.tr('badge_voice_question')),
          if (hasImage)
            QuestionMediaBadge(emoji: _imageEmoji, label: context.tr('badge_image_question')),
        ],
      ),
    );
  }
}
