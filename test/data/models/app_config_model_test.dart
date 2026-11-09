import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/app_config_model.dart';

/// `GET /app/config` — surum/bakim kapisi + guc demosu kapatma anahtari.
///
/// `powerDemoEnabled` sunucuda `app_config` kolonundan gelir; kolon yoksa ya da
/// eski sunucu yanitinda alan hic yoksa demo ACIK kalir (fail-open): alan eksik
/// diye onboarding demosu sessizce kapanmamali.
Map<String, dynamic> _serverJson({Object? powerDemoEnabled, bool withPowerDemo = true}) => {
      'minVersion': '2.0.9',
      'latestVersion': '2.0.10',
      'storeUrl': 'https://apps.apple.com/app/qulo',
      'isMaintenance': false,
      'maintenanceMessage': null,
      'isForceUpdateEnabled': true,
      if (withPowerDemo) 'powerDemoEnabled': powerDemoEnabled,
    };

void main() {
  test('AppConfigModel powerDemoEnabled yoksa true — eski sunucu yaniti demoyu kapatmaz', () {
    final config = AppConfigModel.fromJson(_serverJson(withPowerDemo: false));

    expect(config.powerDemoEnabled, isTrue);
  });

  test('powerDemoEnabled null gelirse de true', () {
    final config = AppConfigModel.fromJson(_serverJson(powerDemoEnabled: null));

    expect(config.powerDemoEnabled, isTrue);
  });

  test('powerDemoEnabled false sunucudan okunur — kapatma anahtari calisir', () {
    final config = AppConfigModel.fromJson(_serverJson(powerDemoEnabled: false));

    expect(config.powerDemoEnabled, isFalse);
  });

  test('powerDemoEnabled true okunur', () {
    final config = AppConfigModel.fromJson(_serverJson(powerDemoEnabled: true));

    expect(config.powerDemoEnabled, isTrue);
  });

  test('mevcut alanlar powerDemoEnabled eklenince bozulmaz', () {
    final config = AppConfigModel.fromJson(_serverJson(powerDemoEnabled: false));

    expect(config.minVersion, '2.0.9');
    expect(config.latestVersion, '2.0.10');
    expect(config.storeUrl, 'https://apps.apple.com/app/qulo');
    expect(config.isMaintenance, isFalse);
    expect(config.maintenanceMessage, isNull);
    expect(config.isForceUpdateEnabled, isTrue);
  });

  test('toJson→fromJson powerDemoEnabled false korunur', () {
    final config = AppConfigModel.fromJson(_serverJson(powerDemoEnabled: false));

    final restored = AppConfigModel.fromJson(config.toJson());

    expect(restored.powerDemoEnabled, isFalse);
    expect(restored, config);
  });

  test('powerDemoEnabled esitlige girer', () {
    final on = AppConfigModel.fromJson(_serverJson(powerDemoEnabled: true));
    final off = AppConfigModel.fromJson(_serverJson(powerDemoEnabled: false));

    expect(on, isNot(off));
  });
}
