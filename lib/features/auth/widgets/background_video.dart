import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:qulo_v2/core/services/video_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

/// Tam ekran arka plan video widget'ı.
///
/// VideoManager üzerinden acquire/release yapar.
/// VisibilityDetector ile görünürlük takibi — ekran dışında pause.
class BackgroundVideo extends StatefulWidget {
  final String assetPath;
  final double overlayOpacity;
  final VoidCallback? onInitialized;

  /// Video yuklenemezse cagrilir; ekran icerigini videoya baglayan taraf
  /// (login formu) bunu duyup kendini acar.
  final VoidCallback? onFailed;

  const BackgroundVideo({
    super.key,
    required this.assetPath,
    this.overlayOpacity = 0.5,
    this.onInitialized,
    this.onFailed,
  });

  @override
  State<BackgroundVideo> createState() => _BackgroundVideoState();
}

class _BackgroundVideoState extends State<BackgroundVideo> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  /// acquire tamamlandı ve bu widget bir referans tutuyor; dispose yalnızca
  /// o zaman release eder (acquire beklerken kapanırsa `_initVideo` bırakır —
  /// iki kez bırakmak ortak controller'ı başkasının elinden alır).
  bool _acquired = false;

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
      _acquired = true;
      setState(() {
        _controller = controller;
        _isInitialized = controller.value.isInitialized;
      });
      if (_isInitialized) {
        widget.onInitialized?.call();
      } else {
        widget.onFailed?.call();
      }
    } catch (e) {
      // Video yuklenemezse siyah arka plan kalir; icerik yine de acilmali
      debugPrint('[BackgroundVideo] Failed to load ${widget.assetPath}: $e');
      if (mounted) widget.onFailed?.call();
    }
  }

  @override
  void dispose() {
    if (_acquired) VideoManager.instance.release(widget.assetPath);
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
          // Video veya siyah placeholder. Manager controller'ı düşürdüyse
          // (max 1 kuralı) ölü controller'la VideoPlayer kurulmaz — platform
          // "No active player" ile fırlatır.
          if (_isInitialized &&
              _controller != null &&
              VideoManager.instance.isActive(widget.assetPath))
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            const ColoredBox(color: AppColors.scrimBase),

          // Koyu overlay — form okunurluğu için
          ColoredBox(
            color: AppColors.scrimBase.withValues(alpha: widget.overlayOpacity),
          ),
        ],
      ),
    );
  }
}
