import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/share_manager.dart';

/// [ShareManager] çıkış alanını eklentiye iletmeli; iletilmezse iOS paylaşım
/// sayfası `sharePositionOrigin: argument must be set` ile crash veriyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('share çıkış alanını eklentiye iletir', () async {
    await ShareManager.instance.share(
      'davet',
      origin: const Rect.fromLTWH(20, 100, 120, 40),
    );

    final args = calls.single.arguments as Map;
    expect(calls.single.method, 'share');
    expect(args['text'], 'davet');
    expect(
      [args['originX'], args['originY'], args['originWidth'], args['originHeight']],
      [20, 100, 120, 40],
    );
  });
}
