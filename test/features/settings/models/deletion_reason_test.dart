import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/settings/models/deletion_reason.dart';

void main() {
  group('DeleteReasonResult.fromSelection', () {
    test('other + boş/boşluk metin → other kalır, metin null (skipped\'e çevrilmez)', () {
      final r = DeleteReasonResult.fromSelection(DeletionReason.other, '   ');
      expect(r.reasonCode, 'other');
      expect(r.reasonText, isNull);
    });

    test('other + metin → kırpılmış metin taşınır', () {
      final r = DeleteReasonResult.fromSelection(DeletionReason.other, '  çok pahalı  ');
      expect(r.reasonCode, 'other');
      expect(r.reasonText, 'çok pahalı');
    });

    test('other dışı neden → metin (önceden yazılmış olsa da) gönderilmez', () {
      final r = DeleteReasonResult.fromSelection(DeletionReason.fewMatches, 'eski metin');
      expect(r.reasonCode, 'few_matches');
      expect(r.reasonText, isNull);
    });

    test('skipped sabiti skipped kodunu taşır', () {
      expect(DeleteReasonResult.skipped.reasonCode, kDeletionReasonSkipped);
      expect(DeleteReasonResult.skipped.reasonText, isNull);
    });
  });
}
