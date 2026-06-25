import 'package:flutter/widgets.dart';

enum CoachMarkShape { rect, circle }

/// One step in a coach-mark tour. [anchorId] null => centered modal card.
class CoachMarkStep {
  const CoachMarkStep({
    this.anchorId,
    required this.titleKey,
    required this.bodyKey,
    required this.ctaKey,
    this.shape = CoachMarkShape.rect,
    this.bodyBuilder,
    this.onShow,
    this.onDismiss,
  });

  final String? anchorId;
  final String titleKey;
  final String bodyKey;
  final String ctaKey;
  final CoachMarkShape shape;

  /// Optional custom body (e.g. power icons). Overrides [bodyKey] text.
  final WidgetBuilder? bodyBuilder;

  final VoidCallback? onShow;
  final VoidCallback? onDismiss;
}
