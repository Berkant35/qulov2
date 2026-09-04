import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_units.dart';

/// Düzenleme alanları cihaz biriminde, kayıt her zaman cm/kg.
void main() {
  test('imperial: ft/in ve lbs alanları cm/kg\'a çevrilir', () async {
    await FormatManager.instance.configure(const Locale('en', 'US'));
    addTearDown(() => FormatManager.instance.configure(const Locale('en')));

    final u = EditProfileUnits(FormatManager.instance);
    u.load(heightCm: 178, weightKg: 72);
    expect(u.heightFeet.text, '5');
    expect(u.heightInches.text, '10');
    expect(u.weight.text, '159');
    expect(u.heightCm(), 178);
    expect(u.weightKg(), 72);
  });

  test('metrik: tek alan cm ve kg', () async {
    await FormatManager.instance.configure(const Locale('tr', 'TR'));
    addTearDown(() => FormatManager.instance.configure(const Locale('en')));

    final u = EditProfileUnits(FormatManager.instance);
    u.load(heightCm: 178, weightKg: 72);
    expect(u.heightCmField.text, '178');
    expect(u.weight.text, '72');
    expect(u.heightCm(), 178);
    expect(u.weightKg(), 72);
  });

  test('boş alanlar null döner', () async {
    await FormatManager.instance.configure(const Locale('en', 'US'));
    addTearDown(() => FormatManager.instance.configure(const Locale('en')));

    final u = EditProfileUnits(FormatManager.instance);
    u.load(heightCm: null, weightKg: null);
    expect(u.heightCm(), isNull);
    expect(u.weightKg(), isNull);
  });

  test('imperial: dokunulmamış boy kaydedilirken kaymaz (177 cm sabit nokta değil)', () async {
    await FormatManager.instance.configure(const Locale('en', 'US'));
    addTearDown(() => FormatManager.instance.configure(const Locale('en')));

    final u = EditProfileUnits(FormatManager.instance);
    u.load(heightCm: 177, weightKg: 72);
    // round(177/2.54)=70in -> 5'10" (eski kod bunu geri 178'e çevirirdi)
    expect(u.heightFeet.text, '5');
    expect(u.heightInches.text, '10');
    expect(u.heightCm(), 177);
  });

  test('imperial: kullanıcı ft/in alanını değiştirince yeni değer cm\'e çevrilir', () async {
    await FormatManager.instance.configure(const Locale('en', 'US'));
    addTearDown(() => FormatManager.instance.configure(const Locale('en')));

    final u = EditProfileUnits(FormatManager.instance);
    u.load(heightCm: 177, weightKg: 72);
    u.heightInches.text = '11'; // kullanıcı 5'10" -> 5'11" yaptı
    expect(u.heightCm(), FormatManager.instance.heightToCm(feet: 5, inches: 11));
    expect(u.heightCm(), 180);
  });

  test('metrik yol etkilenmez: dokunulmamış boy aynen kalır', () async {
    await FormatManager.instance.configure(const Locale('tr', 'TR'));
    addTearDown(() => FormatManager.instance.configure(const Locale('en')));

    final u = EditProfileUnits(FormatManager.instance);
    u.load(heightCm: 177, weightKg: 72);
    expect(u.heightCmField.text, '177');
    expect(u.heightCm(), 177);
  });
}
