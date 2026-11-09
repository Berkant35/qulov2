/// Güç demosunda öğretilen 6 quiz gücü. Domain'e özeldir (Flutter/`PowerType` yok); UI,
/// [apiName] ile `PowerType.fromApiName`'e eşler.
enum DemoPower {
  timeExtend('TIME_EXTEND'),
  oracle('ORACLE'),
  half('HALF'),
  hint('HINT'),
  skip('SKIP'),
  skipAll('SKIP_ALL');

  const DemoPower(this.apiName);

  /// Sunucudaki güç adı (`PowerType.apiName` ile aynı).
  final String apiName;
}
