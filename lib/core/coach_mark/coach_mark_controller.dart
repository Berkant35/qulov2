import 'package:flutter/foundation.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';

class CoachMarkController extends ChangeNotifier {
  CoachMarkController({required this.steps}) : assert(steps.isNotEmpty);

  final List<CoachMarkStep> steps;

  int _index = 0;
  bool _started = false;
  bool _finished = false;

  /// Tur bitince bir kez çağrılır. [skipped] = "tümünü atla" ([skipAll]); `false` =
  /// son adımda [next]. [stepIndex] bitişteki adımın **1 tabanlı** sırası (analitikte
  /// "adım 3"; tamamlanan turda = adım sayısı).
  void Function({required bool skipped, required int stepIndex})? onFinished;

  int get index => _index;
  int get stepCount => steps.length;
  CoachMarkStep get current => steps[_index];
  bool get isLast => _index >= steps.length - 1;
  bool get finished => _finished;

  void start() {
    if (_started) return;
    _started = true;
    current.onShow?.call();
    notifyListeners();
  }

  void next() {
    if (_finished) return;
    current.onDismiss?.call();
    if (isLast) {
      _finish(skipped: false);
      return;
    }
    _index++;
    current.onShow?.call();
    notifyListeners();
  }

  void skipAll() {
    if (_finished) return;
    current.onDismiss?.call();
    _finish(skipped: true);
  }

  void _finish({required bool skipped}) {
    _finished = true;
    onFinished?.call(skipped: skipped, stepIndex: _index + 1);
    notifyListeners();
  }
}
