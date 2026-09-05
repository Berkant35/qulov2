/// Guc adi (sunucu enum'u: ORACLE, HALF, ...) -> ceviri anahtari.
/// Tek kaynak; guc dukkani karti ve satin alma sheet'i buradan okur.
const powerNames = [
  'ORACLE', 'HALF', 'SKIP', 'SKIP_ALL',
  'TIME_EXTEND', 'HINT', 'POWER_BLOCK', 'POWER_UNBLOCK',
];

String powerLabelKey(String name) => switch (name) {
      'ORACLE' => 'power_oracle',
      'HALF' => 'power_half',
      'SKIP' => 'power_skip',
      'SKIP_ALL' => 'power_skip_all',
      'TIME_EXTEND' => 'power_time',
      'HINT' => 'power_hint',
      'POWER_BLOCK' => 'power_block',
      'POWER_UNBLOCK' => 'power_unblock',
      _ => 'power_${name.toLowerCase()}',
    };

String powerDescKey(String name) => switch (name) {
      'TIME_EXTEND' => 'power_time_extend_desc',
      _ => '${powerLabelKey(name)}_desc',
    };
