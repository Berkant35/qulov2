import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:qulo_v2/core/services/video_manager.dart';

/// Tam ekran arka plan video widget'ı.
///
/// VideoManager üzerinden acquire/release yapar.
/// VisibilityDetector ile görünürlük takibi — ekran dışında pause.
class BackgroundVideo extends StatefulWidget {
  final String assetPath;
  final double overlayOpacity;
  final VoidCallback? onInitialized;

  const BackgroundVideo({
    super.key,
    required this.assetPath,
    this.overlayOpacity = 0.3,
    this.onInitialized,
  });

  @override
  State<BackgroundVideo> createState() => _BackgroundVideoState();
}

class _BackgroundVideoState extends State<BackgroundVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = await VideoManager.instance.acquire(widget.assetPath);
    if (!mounted) {
      VideoManager.instance.release(widget.assetPath);
      return;
    }
    setState(() {
      _controller = controller;
    });
    if (_controller != null) {
      widget.onInitialized?.call();
    }
  }

  @override
  void dispose() {
    VideoManager.instance.release(widget.assetPath);
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 0) {
      VideoManager.instance.pause(widget.assetPath);
    } else {
      VideoManager.instance.resume(widget.assetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlay = ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: widget.overlayOpacity),
    );

    if (_controller == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Theme.of(context).colorScheme.surface),
          overlay,
        ],
      );
    }

    return VisibilityDetector(
      key: Key('bg_video_${widget.assetPath}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
          overlay,
        ],
      ),
    );
  }
}
