/// El yazımı `fromJson`'lar için güvenli okuyucular: eksik/bozuk alan istisna değil varsayılan döner.
int jsonInt(Object? value, [int fallback = 0]) => value is num ? value.toInt() : fallback;

int? jsonIntOrNull(Object? value) => value is num ? value.toInt() : null;

num jsonNum(Object? value) => value is num ? value : num.tryParse('$value') ?? 0;

/// Boş ya da yalnız boşluk metin null sayılır.
String? jsonText(Object? value) => value is String && value.trim().isNotEmpty ? value : null;

DateTime? jsonDate(Object? value) => value is String ? DateTime.tryParse(value) : null;

List<Map<String, dynamic>> jsonMaps(Object? value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

Map<String, dynamic>? jsonMap(Object? value) => value is Map ? Map<String, dynamic>.from(value) : null;
