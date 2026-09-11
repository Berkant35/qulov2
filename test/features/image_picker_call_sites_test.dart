import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kaynak tarama korumasi: fotograf secici her yerde `pickWithPermissionPrompt`
/// uzerinden cagrilmali. 2026-09-11'de dort cagiridan ikisi izin reddini
/// yakalamiyordu (onboarding profil kurulumu → yaniltici "yukleme hatasi";
/// soru gorseli → yakalanmayan istisna). Yeni bir secici cagrisi yardimci
/// olmadan eklenirse bu test kirmizi olur.
void main() {
  final pickCall = RegExp(r'\.(pickFromGallery|pickFromCamera|pickAndCrop\w*)\b');
  final directAwait =
      RegExp(r'await\s+[\w.()\s]*\.(pickFromGallery|pickFromCamera|pickAndCrop\w*)\(');

  List<(String, String)> featureSources() => [
        for (final f in Directory('lib/features').listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart')) (f.path, f.readAsStringSync()),
      ];

  test('senaryo: secici en az bir yerde kullaniliyor (tarama bos donmuyor)', () {
    expect(featureSources().where((s) => pickCall.hasMatch(s.$2)), isNotEmpty);
  });

  test('secici DOGRUDAN await edilmez — izin reddi yardimcidan gecmeli', () {
    final offenders = [
      for (final (path, src) in featureSources())
        if (directAwait.hasMatch(src)) path,
    ];

    expect(offenders, isEmpty);
  });

  test('secici kullanan her dosya pickWithPermissionPrompt kullanir', () {
    final offenders = [
      for (final (path, src) in featureSources())
        if (pickCall.hasMatch(src) && !src.contains('pickWithPermissionPrompt(')) path,
    ];

    expect(offenders, isEmpty);
  });
}
