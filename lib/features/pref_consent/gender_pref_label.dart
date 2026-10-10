/// Eşleşme tercihinin çeviri anahtarı — profil ve düzenleme ekranı ortak.
/// Tercih yoksa (rıza reddedildi) "Herkes" değil "saklanmıyor".
String genderPrefLabelKey(String? pref) => switch (pref) {
      'MAN' => 'men',
      'WOMAN' => 'women',
      'BOTH' => 'both',
      _ => 'gender_pref_not_stored',
    };
