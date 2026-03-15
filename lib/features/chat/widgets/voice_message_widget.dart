import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/audio_player_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class VoiceMessageWidget extends ConsumerStatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final bool isMine;

  const VoiceMessageWidget({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    required this.isMine,
  });

  @override
  ConsumerState<VoiceMessageWidget> createState() =>
      _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends ConsumerState<VoiceMessageWidget> {
  @override
  Widget build(BuildContext context) {
    final manager = ref.read(audioPlayerManagerProvider);

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: widget.isMine ? AppColors.purpleGradient : null,
        color: widget.isMine ? null : AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: StreamBuilder<PlayerState>(
        stream: manager.playerStateStream,
        builder: (context, playerSnapshot) {
          final isThisPlaying = manager.currentUrl == widget.audioUrl &&
              (playerSnapshot.data?.playing ?? false);
          final isCompleted =
              playerSnapshot.data?.processingState == ProcessingState.completed;

          // Reset when completed
          if (isCompleted && manager.currentUrl == widget.audioUrl) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              manager.seek(Duration.zero);
              manager.pause();
            });
          }

          return StreamBuilder<Duration>(
            stream: manager.positionStream,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration?>(
                stream: manager.durationStream,
                builder: (context, durationSnapshot) {
                  final position =
                      manager.currentUrl == widget.audioUrl
                          ? (positionSnapshot.data ?? Duration.zero)
                          : Duration.zero;
                  final totalDuration =
                      manager.currentUrl == widget.audioUrl &&
                              durationSnapshot.data != null
                          ? durationSnapshot.data!
                          : Duration(seconds: widget.durationSeconds);
                  final totalMs = totalDuration.inMilliseconds;
                  final progress =
                      totalMs > 0 ? position.inMilliseconds / totalMs : 0.0;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play / Pause button
                      _PlayPauseButton(
                        isPlaying: isThisPlaying,
                        isMine: widget.isMine,
                        onTap: () => _togglePlayback(manager, isThisPlaying),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Slider
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: widget.isMine
                                ? Colors.white
                                : AppColors.primary,
                            inactiveTrackColor: widget.isMine
                                ? Colors.white38
                                : AppColors.textHint,
                            thumbColor: widget.isMine
                                ? Colors.white
                                : AppColors.primary,
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final seekPos = Duration(
                                milliseconds:
                                    (value * totalMs).round(),
                              );
                              manager.seek(seekPos);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Duration text
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(totalDuration)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isMine
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _togglePlayback(AudioPlayerManager manager, bool isPlaying) {
    if (isPlaying) {
      manager.pause();
    } else {
      manager.play(widget.audioUrl);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isMine;
  final VoidCallback onTap;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMine ? Colors.white24 : AppColors.primarySurface,
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          size: 20,
          color: isMine ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}
