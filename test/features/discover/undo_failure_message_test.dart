import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/features/discover/utils/undo_failure_message.dart';

/// Geri alma hata mesaji. Sunucu hak bitince `DAILY_LIMIT_EXCEEDED`
/// (`resource: 'undo'`) doner — `UNDO_LIMIT_REACHED` diye bir kod YOK.
void main() {
  test('hak bitti (sunucu kodu) → "gunluk geri alma hakkin doldu"', () {
    const f = ServerFailure(
      code: 'DAILY_LIMIT_EXCEEDED',
      statusCode: 403,
      params: {'resource': 'undo'},
    );

    expect(undoFailureMessageKey(f), 'undo_limit_reached');
  });

  test('internet yok → baglanti mesaji, "hakkin doldu" DEGIL', () {
    expect(undoFailureMessageKey(const NetworkFailure()), 'error_no_connection');
  });

  test('zaman asimi → zaman asimi mesaji', () {
    expect(undoFailureMessageKey(const TimeoutFailure()), 'error_timeout');
  });

  test('baska sunucu hatasi → genel hata', () {
    expect(
      undoFailureMessageKey(const ServerFailure(code: 'SERVER_ERROR', statusCode: 500)),
      'error_general',
    );
  });
}
