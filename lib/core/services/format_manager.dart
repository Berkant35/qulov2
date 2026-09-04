import 'dart:ui' show Locale;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';

/// Olcu sistemi — SADECE sunumda. Sunucu sozlesmesi her zaman metrik (km, cm, kg).
enum UnitSystem {
  metric,
  imperial;

  static const _imperialCountries = {'US', 'LR', 'MM', 'GB'};

  /// Ulke kodundan cozer; bilinmiyorsa metrik.
  static UnitSystem resolve(String? countryCode) =>
      _imperialCountries.contains(countryCode?.toUpperCase())
          ? UnitSystem.imperial
          : UnitSystem.metric;
}

/// Yaricap slider'i: slider degeri cihaz biriminde, saklama her zaman km.
/// Imperial surekli (`divisions` null): deger oynatilmadan kaydedilirse km sapmaz.
class RadiusScale {
  const RadiusScale._({
    required this.min,
    required this.max,
    required this.divisions,
    required String unitLabel,
    required double perKm,
  })  : _unitLabel = unitLabel,
        _perKm = perKm;

  factory RadiusScale.metric(String unitLabel) => RadiusScale._(
      min: 5, max: 500, divisions: 99, unitLabel: unitLabel, perKm: 1);

  factory RadiusScale.imperial(String unitLabel) => RadiusScale._(
      min: 3, max: 311, divisions: null, unitLabel: unitLabel, perKm: FormatManager._milesPerKm);

  final double min;
  final double max;
  final int? divisions;
  final String _unitLabel;
  final double _perKm;

  double fromKm(double km) => (km * _perKm).clamp(min, max);
  double toKm(double value) => value / _perKm;
  String label(double value) => '${value.round()} $_unitLabel';
}

/// Tek noktadan birim / tarih / sayi bicimlendirme (HapticManager kalibi).
///
/// `configure` locale (bolge dahil) veya profil ulkesi degisince app kokunden
/// cagrilir. Widget'lar `context.fmt`, mixin'ler `formatManagerProvider` ile ulasir;
/// ikisi de bu instance. Metotlar saf: ayni girdi, ayni cikti.
class FormatManager {
  FormatManager._();
  static final FormatManager instance = FormatManager._();

  static const double _milesPerKm = 0.621371;
  static const double _cmPerInch = 2.54;
  static const double _lbsPerKg = 2.20462;

  Locale _locale = const Locale('en');
  UnitSystem _units = UnitSystem.metric;
  AppLocalizations _l10n = AppLocalizations(const Locale('en'));

  Locale get locale => _locale;
  UnitSystem get units => _units;
  String get _tag => _locale.toString();

  Future<void> configure(Locale locale, {String? profileCountry}) async {
    _locale = locale;
    _units = UnitSystem.resolve(locale.countryCode ?? profileCountry);
    _l10n = AppLocalizations(locale);
    Intl.defaultLocale = _tag;
    await _initDateSymbols();
  }

  /// intl tarih sembolleri: once tam locale, olmazsa dil, o da olmazsa en.
  Future<void> _initDateSymbols() async {
    for (final candidate in [_tag, _locale.languageCode, 'en']) {
      try {
        await initializeDateFormatting(candidate);
        return;
      } catch (_) {
        // sonraki adaya dus
      }
    }
  }

  // ── Sayi ──────────────────────────────────────────────────────────
  String integer(int n) => NumberFormat.decimalPattern(_tag).format(n);

  String percent(int p) => NumberFormat.percentPattern(_tag).format(p / 100);

  String _oneDecimal(double v) => NumberFormat('0.0', _tag).format(v);

  String _withN(String key, int n) => _l10n.get(key).replaceAll('{n}', integer(n));

  /// `30s` / `30sn` — sure soneki (mevcut `analytics_seconds` anahtari).
  String seconds(int n) => _withN('analytics_seconds', n);

  // ── Mesafe ────────────────────────────────────────────────────────
  /// 1 km alti her iki sistemde "yakinda"; ustu 1 ondalik + birim.
  String distance(double km) {
    if (km < 1.0) return _l10n.get('nearby');
    return _units == UnitSystem.imperial
        ? '${_oneDecimal(km * _milesPerKm)} ${_l10n.get('mi')}'
        : '${_oneDecimal(km)} ${_l10n.get('km')}';
  }

  /// "Sehir • 3,2 km"; sehir yokken mesafe, mesafe (null = bilinmiyor) yokken
  /// sehir; ikisi de yoksa null (satir hic cizilmez).
  String? locationLine({required String? city, required double? distanceKm}) {
    final parts = [
      if (city != null && city.isNotEmpty) city,
      if (distanceKm != null) distance(distanceKm),
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  RadiusScale get radiusScale => _units == UnitSystem.imperial
      ? RadiusScale.imperial(_l10n.get('mi'))
      : RadiusScale.metric(_l10n.get('km'));

  /// Saklanan km yaricapinin etiketi: `50 km` / `31 mi`.
  String radius(double km) => radiusScale.label(radiusScale.fromKm(km));

  // ── Boy / kilo ────────────────────────────────────────────────────
  String height(int cm) {
    if (_units == UnitSystem.metric) return '$cm ${_l10n.get('cm')}';
    final imperial = heightToImperial(cm);
    return "${imperial.feet}'${imperial.inches}\"";
  }

  ({int feet, int inches}) heightToImperial(int cm) {
    final totalInches = (cm / _cmPerInch).round();
    return (feet: totalInches ~/ 12, inches: totalInches % 12);
  }

  int heightToCm({required int feet, required int inches}) =>
      ((feet * 12 + inches) * _cmPerInch).round();

  String weight(int kg) => _units == UnitSystem.metric
      ? '$kg ${_l10n.get('kg')}'
      : '${weightToLbs(kg)} ${_l10n.get('lbs')}';

  int weightToLbs(int kg) => (kg * _lbsPerKg).round();

  int weightToKg(int lbs) => (lbs / _lbsPerKg).round();

  // ── Tarih / saat ──────────────────────────────────────────────────
  /// `Sep 4, 2026` / `4 Eyl 2026` — bolgeler arasi belirsizlik yok.
  String date(DateTime dt) => DateFormat.yMMMd(_tag).format(dt.toLocal());

  /// `Sep 4` / `4 Eyl` — yil olmadan (7+ gun eski rozetler).
  String dateShort(DateTime dt) => DateFormat.MMMd(_tag).format(dt.toLocal());

  /// `11:45 PM` / `23:45` — 12/24 saat locale'den.
  String time(DateTime dt) => DateFormat.jm(_tag).format(dt.toLocal());

  /// Bugun / Dun / tarih — yerel takvim gunune gore.
  String dayLabel(DateTime dt, {DateTime? now}) {
    final local = dt.toLocal();
    final today = _dayOf(now ?? DateTime.now());
    final diff = today.difference(_dayOf(local)).inDays;
    if (diff == 0) return _l10n.get('today');
    if (diff == 1) return _l10n.get('yesterday');
    return date(dt);
  }

  /// `Just now` / `5 minutes ago` / `3 hours ago` / `4 days ago` / `Aug 25`.
  String relative(DateTime dt, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(dt);
    if (diff.inSeconds < 60) return _l10n.get('just_now');
    if (diff.inMinutes < 60) return _l10n.plural('time_minutes_ago', diff.inMinutes);
    if (diff.inHours < 24) return _l10n.plural('time_hours_ago', diff.inHours);
    if (diff.inDays < 7) return _l10n.plural('time_days_ago', diff.inDays);
    return dateShort(dt);
  }

  /// Rozet bicimi: `Now` / `5m` / `3h` / `4d` / `Aug 25`.
  String relativeShort(DateTime dt, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(dt);
    if (diff.inSeconds < 60) return _l10n.get('now');
    if (diff.inMinutes < 60) return _withN('time_minutes_short', diff.inMinutes);
    if (diff.inHours < 24) return _withN('time_hours_short', diff.inHours);
    if (diff.inDays < 7) return _withN('time_days_short', diff.inDays);
    return dateShort(dt);
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
}
