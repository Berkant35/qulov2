/// Semantic version comparison.
/// Returns: negative (a < b), 0 (equal), positive (a > b)
int compareVersions(String a, String b) {
  final partsA = a.split('.').map(int.parse).toList();
  final partsB = b.split('.').map(int.parse).toList();

  final length = partsA.length > partsB.length ? partsA.length : partsB.length;

  for (var i = 0; i < length; i++) {
    final partA = i < partsA.length ? partsA[i] : 0;
    final partB = i < partsB.length ? partsB[i] : 0;

    if (partA != partB) return partA - partB;
  }

  return 0;
}

/// Returns true if current < target
bool isVersionLessThan(String current, String target) {
  return compareVersions(current, target) < 0;
}
