import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDdoTWGarzK9QNO2h9FHGGqOopV9u9E2vk',
    appId: '1:1036336261876:android:9bc8b6cd47514ca15fcca1',
    messagingSenderId: '1036336261876',
    projectId: 'qulo-b2f1a',
    storageBucket: 'qulo-b2f1a.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzw6L2aL6uHRobFtvACGUY34bf0LgWoNM',
    appId: '1:1036336261876:ios:0c644dd38dc1f2575fcca1',
    messagingSenderId: '1036336261876',
    projectId: 'qulo-b2f1a',
    storageBucket: 'qulo-b2f1a.appspot.com',
    iosBundleId: 'com.wordpress.calikusuberkant.qulorelease',
  );
}
