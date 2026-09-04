import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/services/format_manager.dart';

/// Boy/kilo duzenleme alanlari: kullanici cihaz biriminde yazar, kayit cm/kg.
/// Imperial'da boy iki alan (ft, in), metrikte tek alan (cm); kilo tek alan.
class EditProfileUnits {
  EditProfileUnits(this._fmt);

  final FormatManager _fmt;
  final heightCmField = TextEditingController();
  final heightFeet = TextEditingController();
  final heightInches = TextEditingController();
  final weight = TextEditingController();

  bool get isImperial => _fmt.units == UnitSystem.imperial;

  void load({required int? heightCm, required int? weightKg}) {
    if (heightCm != null) {
      if (isImperial) {
        final h = _fmt.heightToImperial(heightCm);
        heightFeet.text = '${h.feet}';
        heightInches.text = '${h.inches}';
      } else {
        heightCmField.text = '$heightCm';
      }
    }
    if (weightKg != null) {
      weight.text = isImperial ? '${_fmt.weightToLbs(weightKg)}' : '$weightKg';
    }
  }

  int? heightCm() {
    if (!isImperial) return int.tryParse(heightCmField.text);
    final feet = int.tryParse(heightFeet.text);
    final inches = int.tryParse(heightInches.text) ?? 0;
    return feet == null ? null : _fmt.heightToCm(feet: feet, inches: inches);
  }

  int? weightKg() {
    final value = int.tryParse(weight.text);
    if (value == null) return null;
    return isImperial ? _fmt.weightToKg(value) : value;
  }

  void dispose() {
    heightCmField.dispose();
    heightFeet.dispose();
    heightInches.dispose();
    weight.dispose();
  }
}
