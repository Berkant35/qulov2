import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/quiz/models/quiz_voice_status.dart';

/// Soru sesi için kompakt oynatıcı: [küçük yeşil düğme] [ince ilerleme çizgisi] [kalan süre].
/// Soru çözülürken dikkat dağıtmasın diye tek ince hap — yükseklik [_height].
class QuizVoicePlayerRow extends StatelessWidget {
  static const double _maxWidth = 260;
  static const double _height = 36;
  static const double _buttonSize = 28;
  static const double _iconSize = 18;
  static const double _trackHeight = 3;

  const QuizVoicePlayerRow({
    super.key,
    required this.status,
    required this.position,
    required this.total,
    required this.onToggle,
  });

  final ValueListenable<QuizVoiceStatus> status;
  final Stream<Duration> position;

  /// Ses süresi; bilinmiyorsa null (kalan süre etiketi yok, çizgi boş).
  final Duration? total;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            color: colors.secondarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: colors.secondary.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.md),
            child: ValueListenableBuilder<QuizVoiceStatus>(
              valueListenable: status,
              builder: (context, value, _) => StreamBuilder<Duration>(
                stream: position,
                initialData: Duration.zero,
                builder: (context, snapshot) {
                  final elapsed =
                      value == QuizVoiceStatus.completed ? total : snapshot.data;
                  return Row(
                    children: [
                      _ToggleButton(status: value, onPressed: onToggle),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _Track(elapsed: elapsed, total: total)),
                      if (total != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _remainingLabel(elapsed ?? Duration.zero),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.secondary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kalan süre `m:ss` (yukarı yuvarlı).
  String _remainingLabel(Duration elapsed) {
    final left = (total! - elapsed).inMilliseconds.clamp(0, total!.inMilliseconds);
    final seconds = (left / Duration.millisecondsPerSecond).ceil();
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '${seconds ~/ 60}:$ss';
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.status, required this.onPressed});

  final QuizVoiceStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final loading = status == QuizVoiceStatus.loading;
    final colors = context.appColors;
    return IconButton.filled(
      onPressed: loading ? null : onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(QuizVoicePlayerRow._buttonSize),
        minimumSize: const Size.square(QuizVoicePlayerRow._buttonSize),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: colors.secondary,
        foregroundColor: colors.background,
        disabledBackgroundColor: colors.secondary.withValues(alpha: 0.4),
      ),
      iconSize: QuizVoicePlayerRow._iconSize,
      tooltip: context.tr(switch (status) {
        QuizVoiceStatus.playing => 'quiz_voice_pause',
        QuizVoiceStatus.completed => 'quiz_voice_replay',
        _ => 'quiz_voice_play',
      }),
      icon: loading
          ? const AppLoadingWidget.small()
          : Icon(switch (status) {
              QuizVoiceStatus.playing => Icons.pause_rounded,
              QuizVoiceStatus.completed => Icons.replay_rounded,
              _ => Icons.play_arrow_rounded,
            }),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.elapsed, required this.total});

  final Duration? elapsed;
  final Duration? total;

  @override
  Widget build(BuildContext context) {
    final totalMs = total?.inMilliseconds ?? 0;
    final progress =
        totalMs <= 0 ? 0.0 : ((elapsed?.inMilliseconds ?? 0) / totalMs).clamp(0.0, 1.0);
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: QuizVoicePlayerRow._trackHeight,
        color: colors.secondary,
        backgroundColor: colors.secondary.withValues(alpha: 0.2),
      ),
    );
  }
}
