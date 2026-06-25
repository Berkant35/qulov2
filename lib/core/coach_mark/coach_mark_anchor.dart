import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_registry.dart';

/// Wrap any widget that a coach-mark step targets. Registers a stable
/// GlobalKey under [anchorId] so the overlay can read its global rect.
class CoachMarkAnchor extends StatelessWidget {
  const CoachMarkAnchor({super.key, required this.anchorId, required this.child});

  final String anchorId;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: CoachMarkRegistry.keyFor(anchorId), child: child);
}
