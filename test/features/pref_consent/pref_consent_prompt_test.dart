import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/pref_consent/mixins/pref_consent_prompt_mixin.dart';

void main() {
  final set = DateTime.utc(2026, 9, 1);

  test('rızasız eski tercih → sorulur', () {
    expect(PrefConsentPrompt.shouldPrompt(UserModel(id: 'u', email: 'e', genderPrefSetAt: set)), isTrue);
  });
  test('rıza verilmiş / reddedilmiş / tercihsiz / kullanıcı yok → sorulmaz', () {
    expect(PrefConsentPrompt.shouldPrompt(UserModel(id: 'u', email: 'e', genderPrefSetAt: set, prefConsentStatus: PrefConsent.granted)), isFalse);
    expect(PrefConsentPrompt.shouldPrompt(UserModel(id: 'u', email: 'e', prefConsentStatus: PrefConsent.declined)), isFalse);
    expect(PrefConsentPrompt.shouldPrompt(UserModel(id: 'u', email: 'e')), isFalse);
    expect(PrefConsentPrompt.shouldPrompt(null), isFalse);
  });
  test('kuyrukta anketten ve turdan önce (yasal adım)', () {
    expect(PrefConsentPrompt.priority, greaterThan(OverlayPriority.survey));
  });
}
