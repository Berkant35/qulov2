import 'package:flutter/widgets.dart';

/// Maps a stable anchorId to a GlobalKey so coach-mark tours can resolve a
/// target widget's screen rect without prop-threading keys through the tree.
abstract final class CoachMarkRegistry {
  static final Map<String, GlobalKey> _keys = {};

  static GlobalKey keyFor(String anchorId) =>
      _keys.putIfAbsent(anchorId, () => GlobalKey());

  static GlobalKey? maybeKey(String anchorId) => _keys[anchorId];
}
