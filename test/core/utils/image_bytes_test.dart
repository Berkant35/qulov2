import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qulo_v2/core/utils/image_bytes.dart';

/// Kirpma akisinin bayt kapisi. Crashlytics iOS 2.0.17: 0 bayt →
/// `InputBuffer.[]` RangeError (PngDecoder.isValidFile) isolate'te fatal.
void main() {
  final png = Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 2)));
  final jpg = Uint8List.fromList(img.encodeJpg(img.Image(width: 4, height: 2)));

  group('looksLikeImage', () {
    test('0 bayt istisna ATMADAN false — image paketi burada RangeError atiyordu', () {
      expect(() => img.findDecoderForData(Uint8List(0)), throwsRangeError,
          reason: 'paket davranisi degisirse bu koruma gereksizlesir');
      expect(ImageBytes.looksLikeImage(Uint8List(0)), isFalse);
    });

    test('rastgele bayt false, png/jpg true', () {
      expect(ImageBytes.looksLikeImage(Uint8List.fromList([1, 2, 3, 4, 5])), isFalse);
      expect(ImageBytes.looksLikeImage(png), isTrue);
      expect(ImageBytes.looksLikeImage(jpg), isTrue);
    });
  });

  group('canDecode', () {
    test('gecerli png ve jpg cozulur', () {
      expect(ImageBytes.canDecode(png), isTrue);
      expect(ImageBytes.canDecode(jpg), isTrue);
    });

    test('basligi dogru ama kesik dosya false (istisna yok)', () {
      final truncated = Uint8List.sublistView(png, 0, 20);
      expect(ImageBytes.canDecode(truncated), isFalse);
    });

    test('bos ve bozuk girdi false', () {
      expect(ImageBytes.canDecode(Uint8List(0)), isFalse);
      expect(ImageBytes.canDecode(Uint8List.fromList(List.filled(64, 7))), isFalse);
    });
  });

  test('validate bos baytta isolate acmadan false', () async {
    expect(await ImageBytes.validate(Uint8List(0)), isFalse);
  });

  group('rotate90', () {
    test('en/boy yer degistirir, jpg doner', () {
      final rotated = ImageBytes.rotate90(png)!;
      final decoded = img.decodeImage(rotated)!;
      expect((decoded.width, decoded.height), (2, 4));
    });

    test('bos/bozuk girdide null — compute isolate\'inde istisna yok', () {
      expect(ImageBytes.rotate90(Uint8List(0)), isNull);
      expect(ImageBytes.rotate90(Uint8List.sublistView(png, 0, 20)), isNull);
    });
  });
}
