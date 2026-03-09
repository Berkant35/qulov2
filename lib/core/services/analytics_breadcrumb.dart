import 'dart:collection';

class BreadcrumbEntry {
  final String event;
  final Map<String, Object>? params;
  final DateTime timestamp;

  BreadcrumbEntry(this.event, this.params, this.timestamp);

  @override
  String toString() {
    final paramStr = params != null && params!.isNotEmpty ? ' $params' : '';
    return '${timestamp.toIso8601String()} $event$paramStr';
  }

  String toShortString() => event;
}

class BreadcrumbQueue {
  final int maxSize;
  final Queue<BreadcrumbEntry> _queue = Queue<BreadcrumbEntry>();

  BreadcrumbQueue({this.maxSize = 30});

  void add(BreadcrumbEntry entry) {
    _queue.add(entry);
    if (_queue.length > maxSize) {
      _queue.removeFirst();
    }
  }

  List<BreadcrumbEntry> get entries => _queue.toList();

  String getTrailSummary({int count = 5}) {
    final recent = _queue.toList().reversed.take(count);
    return recent.map((e) => e.toShortString()).join(' → ');
  }

  void clear() => _queue.clear();
}
