import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/auth/widgets/background_video.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Test ortamında video eklentisi yok: yükleme başarısız olur. Widget bunu
/// bildirmeli ki login formu videoya takılı kalmasın.
void main() {
  // VisibilityDetector'un 500 ms zamanlayicisi test sonunda askida kalmasin.
  setUp(() => VisibilityDetectorController.instance.updateInterval = Duration.zero);

  testWidgets('video yüklenemeyince onFailed çağrılır', (tester) async {
    var failed = false;
    await tester.pumpWidget(MaterialApp(
      home: BackgroundVideo(
        assetPath: 'assets/videos/login_bg.mp4',
        onFailed: () => failed = true,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(failed, isTrue);
  });
}
