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
    this.overlayOpacity = 0.5,
    this.onInitialized,
  });

  @override
  State<BackgroundVideo> createState() => _BackgroundVideoState();
}

class _BackgroundVideoState extends State<BackgroundVideo> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller =
          await VideoManager.instance.acquire(widget.assetPath);
      if (!mounted) {
        VideoManager.instance.release(widget.assetPath);
        return;
      }
      setState(() {
        _controller = controller;
        _isInitialized = controller.value.isInitialized;
      });
      if (_isInitialized) {
        widget.onInitialized?.call();
      }
    } catch (e) {
      // Video yüklenemezse siyah arka plan kalır
      debugPrint('[BackgroundVideo] Failed to load ${widget.assetPath}: $e');
    }
  }

  @override
  void dispose() {
    VideoManager.instance.release(widget.assetPath);
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_isInitialized) return;
    if (info.visibleFraction == 0) {
      VideoManager.instance.pause(widget.assetPath);
    } else {
      VideoManager.instance.resume(widget.assetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('bg_video_${widget.assetPath}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video veya siyah placeholder
          if (_isInitialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            const ColoredBox(color: Colors.black),

          // Koyu overlay — form okunurluğu için
          ColoredBox(
            color: Colors.black.withValues(alpha: widget.overlayOpacity),
          ),
        ],
      ),
    );
  }
}
