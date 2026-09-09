import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/discover/mixins/discover_scope_chip_mixin.dart';

class _Host with DiscoverScopeChipMixin {}

void main() {
  final host = _Host();

  group('DiscoverScopeChipMixin.isExpanded', () {
    test('tier 0 genisletilmis degil', () {
      expect(host.isExpanded(0), isFalse);
    });

    test('tier 1, 2 ve 3 genisletilmis', () {
      expect(host.isExpanded(1), isTrue);
      expect(host.isExpanded(2), isTrue);
      expect(host.isExpanded(3), isTrue);
    });
  });
}
