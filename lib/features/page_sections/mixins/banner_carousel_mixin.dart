import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/page_sections/widgets/banner_carousel_section.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Carousel davranışı (spec §7.3): `autoplaySeconds` ile kayar; dokunma, ekran dışı (< %50 görünür)
/// ya da uygulama arka plandayken durur. Görünür sayfa değişince / bölüm görünür olunca `onShown`.
mixin BannerCarouselMixin on State<BannerCarouselSection> {
  final pageController = PageController();
  int currentPage = 0;
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _visible = false;
  bool _touching = false;
  bool _foreground = true;

  void initMixin() {
    _lifecycle = AppLifecycleListener(
      onShow: () => _setForeground(true),
      onHide: () => _setForeground(false),
    );
  }

  void disposeMixin() {
    _timer?.cancel();
    _lifecycle?.dispose();
    pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() => currentPage = page);
    if (_visible) widget.onShown(widget.section.items[page]);
  }

  void onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final visible = info.visibleFraction >= 0.5;
    if (visible == _visible) return;
    _visible = visible;
    if (visible) widget.onShown(widget.section.items[currentPage]);
    _sync();
  }

  /// Sunucudan bölüm yeniden geldiğinde çağrılır (aynı `section.id` → State korunur,
  /// `PageSectionList`'in `ValueKey(section.id)`'i sayesinde). Öğe sayısı azaldıysa
  /// `currentPage` aralık dışına düşebilir — animasyonsuz kırpılır, aksi halde bir
  /// sonraki görünürlük değişiminde (uygulama öne gelince / kaydırarak geri gelince)
  /// `items[currentPage]` aralık dışı erişim fırlatır. `autoplaySeconds` ya da öğe
  /// sayısı değiştiyse zamanlayıcı iptal edilip yeni değerle yeniden kurulur (eski
  /// aralık kalıcı olmaz; öğe sayısı 1'e düşerse otomatik kayma durur).
  void onSectionUpdated(BannerCarouselSectionView oldSection) {
    final items = widget.section.items;
    if (items.isEmpty) return;
    if (currentPage >= items.length) {
      final clamped = items.length - 1;
      setState(() => currentPage = clamped);
      if (pageController.hasClients) pageController.jumpToPage(clamped);
    }
    final countChanged = oldSection.items.length != items.length;
    final autoplayChanged = oldSection.autoplaySeconds != widget.section.autoplaySeconds;
    if (countChanged || autoplayChanged) {
      _timer?.cancel();
      _timer = null;
      _sync();
    }
  }

  void onPointerDown(PointerDownEvent _) {
    _touching = true;
    _sync();
  }

  void onPointerUp(PointerEvent _) {
    _touching = false;
    _sync();
  }

  void _setForeground(bool value) {
    _foreground = value;
    _sync();
  }

  bool get _canAutoplay =>
      widget.section.autoplaySeconds > 0 && widget.section.items.length > 1 && _visible && !_touching && _foreground;

  void _sync() {
    if (_canAutoplay) {
      _timer ??= Timer.periodic(Duration(seconds: widget.section.autoplaySeconds), (_) => _next());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _next() {
    if (!mounted || !pageController.hasClients) return;
    final next = (currentPage + 1) % widget.section.items.length;
    pageController.animateToPage(next, duration: AppDurations.pageTransition, curve: Curves.easeOut);
  }
}
