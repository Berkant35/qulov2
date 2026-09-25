import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Google Play "Photo and Video Permissions" politikasi (2026-09-25 reddi):
/// galeri secimi Android Photo Picker ile yapilir; genis medya izinleri
/// manifest'te BILDIRILMEZ. Bu test iznin geri eklenmesini engeller.
void main() {
  test('AndroidManifest genis medya izni bildirmez', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    const banned = [
      'android.permission.READ_MEDIA_IMAGES',
      'android.permission.READ_MEDIA_VIDEO',
      'android.permission.READ_EXTERNAL_STORAGE',
    ];
    final declared = RegExp(
      r'<uses-permission\s+android:name="([^"]+)"\s*/>',
    ).allMatches(manifest).map((m) => m.group(1)).toList();
    for (final perm in banned) {
      expect(declared, isNot(contains(perm)), reason: '$perm bildirilmemeli');
      expect(
        manifest,
        contains('android:name="$perm"\n        tools:node="remove"'),
        reason: '$perm icin tools:node="remove" korumasi olmali',
      );
    }
  });
}
