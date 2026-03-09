# V1 to V2 Platform Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate all platform configs, Firebase, signing, assets, permissions, fonts, splash, and error manager from V1 to V2 so the app ships as v2.0.0 update.

**Architecture:** Copy platform files (Firebase configs, keystore, icons) from V1. Update bundle IDs, signing, permissions in V2. Add Helvetica font, Error Manager, and flutter_native_splash. Localize iOS permission strings (TR/EN).

**Tech Stack:** Flutter 3.9, Firebase (Crashlytics, Analytics, FCM), Supabase, flutter_native_splash

---

## Phase 1: Android Bundle ID, Signing & Firebase

### Task 1: Android Bundle ID & Signing Config

**Files:**
- Modify: `android/app/build.gradle.kts`
- Create: `android/key.properties`
- Copy: `upload-keystore.jks` from V1

**Step 1: Copy keystore from V1**

```bash
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/android/app/upload-keystore.jks \
   /Users/berkantcalikusu/IdeaProjects/qulov2/android/app/upload-keystore.jks
```

**Step 2: Create key.properties**

Create `android/key.properties`:
```properties
storePassword=a159753789456123
keyPassword=a159753789456123
keyAlias=upload
storeFile=upload-keystore.jks
```

**Step 3: Update build.gradle.kts**

Replace entire content of `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.wordpress.calikusuberkant.qulo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.wordpress.calikusuberkant.qulo"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }
}

flutter {
    source = "../.."
}
```

**Step 4: Add google-services and crashlytics plugins to root build.gradle.kts**

Add to `android/build.gradle.kts` before the closing:
```kotlin
// At the top, inside plugins {} or as classpath dependencies
```

Actually, for Kotlin DSL with Flutter, add to `android/settings.gradle.kts`:
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.3" apply false
}
```

**Step 5: Verify build compiles**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter build apk --debug 2>&1 | head -30
```

**Step 6: Commit**

```bash
git add android/app/build.gradle.kts android/key.properties android/app/upload-keystore.jks android/settings.gradle.kts
git commit -m "feat: configure Android bundle ID, signing & Firebase plugins"
```

---

### Task 2: Copy Firebase Config Files

**Files:**
- Copy: `google-services.json` from V1 to `android/app/`
- Copy: `GoogleService-Info.plist` from V1 to `ios/Runner/`

**Step 1: Copy google-services.json**

```bash
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/android/app/google-services.json \
   /Users/berkantcalikusu/IdeaProjects/qulov2/android/app/google-services.json
```

**Step 2: Copy GoogleService-Info.plist**

```bash
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/ios/Runner/GoogleService-Info.plist \
   /Users/berkantcalikusu/IdeaProjects/qulov2/ios/Runner/GoogleService-Info.plist
```

**Step 3: Generate firebase_options.dart**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart pub global activate flutterfire_cli && flutterfire configure --project=qulo-b2f1a
```

If `flutterfire configure` doesn't work interactively, manually create `lib/firebase_options.dart` from the V1 Firebase config values:
- Android App ID: `1:1036336261876:android:9bc8b6cd47514ca15fcca1`
- iOS App ID: `1:1036336261876:ios:0c644dd38dc1f2575fcca1`
- API Key Android: `AIzaSyDdoTWGarzK9QNO2h9FHGGqOopV9u9E2vk`
- API Key iOS: `AIzaSyBzw6L2aL6uHRobFtvACGUY34bf0LgWoNM`
- Project ID: `qulo-b2f1a`
- Messaging Sender ID: `1036336261876`
- Storage Bucket: `qulo-b2f1a.appspot.com`

Create `lib/firebase_options.dart`:
```dart
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
```

**Step 4: Update main.dart to use firebase_options**

Modify `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/config/supabase_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initSupabase();

  runApp(const ProviderScope(child: QuloApp()));
}
```

**Step 5: Commit**

```bash
git add android/app/google-services.json ios/Runner/GoogleService-Info.plist lib/firebase_options.dart lib/main.dart
git commit -m "feat: add Firebase config files and firebase_options.dart"
```

---

### Task 3: Android Manifest Permissions & Metadata

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Update AndroidManifest.xml**

Replace entire content:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <intent>
            <action android:name="android.media.action.IMAGE_CAPTURE"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.GET_CONTENT"/>
            <data android:mimeType="image/*"/>
        </intent>
    </queries>

    <application
        android:label="Qulo"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher"/>
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@android:color/transparent"/>

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:screenOrientation="portrait"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>
</manifest>
```

**Step 2: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat: add Android permissions and FCM metadata"
```

---

## Phase 2: iOS Configuration

### Task 4: iOS Bundle ID & Info.plist

**Files:**
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (bundle ID change)
- Modify: `ios/Runner/Info.plist`

**Step 1: Update iOS bundle ID in project.pbxproj**

Use sed to replace all occurrences:
```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
sed -i '' 's/com.qulo.quloV2/com.wordpress.calikusuberkant.qulorelease/g' ios/Runner.xcodeproj/project.pbxproj
```

**Step 2: Update Info.plist with permissions and Firebase config**

Replace entire `ios/Runner/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>Qulo</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleLocalizations</key>
	<array>
		<string>tr</string>
		<string>en</string>
	</array>
	<key>CFBundleName</key>
	<string>Qulo</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>app-1-1036336261876-ios-0c644dd38dc1f2575fcca1</string>
			</array>
		</dict>
	</array>
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>FirebaseAppDelegateProxyEnabled</key>
	<true/>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>NSCameraUsageDescription</key>
	<string>$(CAMERA_USAGE_DESCRIPTION)</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>$(LOCATION_WHEN_IN_USE_DESCRIPTION)</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>$(PHOTO_LIBRARY_DESCRIPTION)</string>
	<key>UIBackgroundModes</key>
	<array>
		<string>fetch</string>
		<string>remote-notification</string>
	</array>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UIRequiresFullScreen</key>
	<true/>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
	</array>
</dict>
</plist>
```

Note: Permission descriptions use variables that resolve from InfoPlist.strings (localized).

**Step 3: Commit**

```bash
git add ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist
git commit -m "feat: update iOS bundle ID, permissions, Firebase config"
```

---

### Task 5: iOS Localized Permission Strings

**Files:**
- Create: `ios/Runner/tr.lproj/InfoPlist.strings`
- Create: `ios/Runner/en.lproj/InfoPlist.strings`

**Step 1: Create Turkish localization**

```bash
mkdir -p /Users/berkantcalikusu/IdeaProjects/qulov2/ios/Runner/tr.lproj
```

Create `ios/Runner/tr.lproj/InfoPlist.strings`:
```
"CFBundleDisplayName" = "Qulo";
"CAMERA_USAGE_DESCRIPTION" = "Profil fotoğraflarınızı çekmek için kamera erişimi gereklidir.";
"PHOTO_LIBRARY_DESCRIPTION" = "Profil fotoğraflarınızı seçmek için galeri erişimi gereklidir.";
"LOCATION_WHEN_IN_USE_DESCRIPTION" = "Yakınlarınızdaki kullanıcıları görmek için konum erişimi gereklidir.";
```

**Step 2: Create English localization**

```bash
mkdir -p /Users/berkantcalikusu/IdeaProjects/qulov2/ios/Runner/en.lproj
```

Create `ios/Runner/en.lproj/InfoPlist.strings`:
```
"CFBundleDisplayName" = "Qulo";
"CAMERA_USAGE_DESCRIPTION" = "Camera access is required to take profile photos.";
"PHOTO_LIBRARY_DESCRIPTION" = "Photo library access is required to select profile photos.";
"LOCATION_WHEN_IN_USE_DESCRIPTION" = "Location access is required to show nearby users.";
```

**Step 3: Create push notification entitlements**

Create `ios/Runner/Runner.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
</dict>
</plist>
```

**Step 4: Commit**

```bash
git add ios/Runner/tr.lproj/ ios/Runner/en.lproj/ ios/Runner/Runner.entitlements
git commit -m "feat: add iOS localized permission strings and push entitlements"
```

---

## Phase 3: Assets, Fonts & Icons

### Task 6: Copy V1 Assets to V2

**Files:**
- Create: `assets/` directory structure with V1 assets

**Step 1: Create asset directories and copy from V1**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
mkdir -p assets/logo assets/icons assets/lottie assets/svgShapes assets/fonts

# Copy logo (diamond SVGs)
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/assets/logo/* assets/logo/

# Copy icons
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/assets/icons/* assets/icons/

# Copy lottie animations
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/assets/lottie/* assets/lottie/

# Copy SVG shapes (splash, shapes etc.)
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/assets/svgShapes/* assets/svgShapes/

# Copy custom icon font
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/assets/QuloIcon.ttf assets/fonts/QuloIcon.ttf
```

**Step 2: Download Helvetica font**

Helvetica is a commercial/system font. For Flutter, use Helvetica Neue or the free alternative "Inter" which is very similar. If you have Helvetica files locally on macOS:

```bash
# macOS system Helvetica - copy from system fonts
cp /System/Library/Fonts/Helvetica.ttc assets/fonts/Helvetica.ttc 2>/dev/null || true

# If .ttc doesn't work in Flutter, we'll use HelveticaNeue variants from the system
# Alternative: download Inter font as a free Helvetica substitute
```

If Helvetica is not available as TTF, download Inter font:
```bash
curl -L -o /tmp/inter.zip "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip"
cd /tmp && unzip -o inter.zip -d inter_font
cp /tmp/inter_font/Inter-4.1/InterVariable.ttf /Users/berkantcalikusu/IdeaProjects/qulov2/assets/fonts/Inter.ttf
cp /tmp/inter_font/Inter-4.1/InterVariable-Italic.ttf /Users/berkantcalikusu/IdeaProjects/qulov2/assets/fonts/Inter-Italic.ttf
```

User prefers Helvetica. If macOS .ttc works, use it. Otherwise fallback to Inter.

**Step 3: Commit**

```bash
git add assets/
git commit -m "feat: copy V1 assets (logo, icons, lottie, SVGs, fonts)"
```

---

### Task 7: Update pubspec.yaml with Assets & Font

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Update pubspec.yaml**

Change version to `2.0.0+28` and add assets + fonts section:

```yaml
version: 2.0.0+28

# ... (keep all dependencies as-is, add flutter_native_splash) ...

flutter:
  uses-material-design: true

  assets:
    - assets/logo/
    - assets/icons/
    - assets/lottie/
    - assets/svgShapes/

  fonts:
    - family: Helvetica
      fonts:
        - asset: assets/fonts/Helvetica.ttc
    - family: QuloIcon
      fonts:
        - asset: assets/fonts/QuloIcon.ttf
```

If using Inter instead of Helvetica:
```yaml
  fonts:
    - family: Helvetica
      fonts:
        - asset: assets/fonts/Inter.ttf
        - asset: assets/fonts/Inter-Italic.ttf
          style: italic
    - family: QuloIcon
      fonts:
        - asset: assets/fonts/QuloIcon.ttf
```

**Step 2: Add flutter_native_splash dependency**

Add to `dependencies:` section in pubspec.yaml:
```yaml
  flutter_native_splash: ^2.4.3
```

**Step 3: Run flutter pub get**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter pub get
```

**Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: declare assets, fonts and version 2.0.0 in pubspec"
```

---

### Task 8: Copy App Icons from V1

**Files:**
- Copy: Android mipmap icons from V1
- Copy: iOS AppIcon.appiconset from V1

**Step 1: Copy Android icons**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2

# Copy all mipmap directories from V1
for density in hdpi mdpi xhdpi xxhdpi xxxhdpi; do
  cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/android/app/src/main/res/mipmap-${density}/* \
     android/app/src/main/res/mipmap-${density}/
done

# Copy adaptive icon configs if they exist
mkdir -p android/app/src/main/res/mipmap-anydpi-v26
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/android/app/src/main/res/mipmap-anydpi-v26/* \
   android/app/src/main/res/mipmap-anydpi-v26/ 2>/dev/null || true

# Copy colors.xml for adaptive icon background
cp /Users/berkantcalikusu/IdeaProjects/qulo_yedek/android/app/src/main/res/values/colors.xml \
   android/app/src/main/res/values/colors.xml 2>/dev/null || true
```

**Step 2: Copy iOS icons**

```bash
# Replace entire AppIcon.appiconset
rm -rf ios/Runner/Assets.xcassets/AppIcon.appiconset
cp -r /Users/berkantcalikusu/IdeaProjects/qulo_yedek/ios/Runner/Assets.xcassets/AppIcon.appiconset \
      ios/Runner/Assets.xcassets/AppIcon.appiconset
```

**Step 3: Commit**

```bash
git add android/app/src/main/res/ ios/Runner/Assets.xcassets/AppIcon.appiconset/
git commit -m "feat: copy V1 app icons (Android adaptive + iOS)"
```

---

## Phase 4: Splash Screen

### Task 9: Configure Native Splash Screen

**Files:**
- Create: `flutter_native_splash.yaml`

**Step 1: Create flutter_native_splash.yaml**

Create `flutter_native_splash.yaml` in project root:
```yaml
flutter_native_splash:
  color: "#502989"
  color_dark: "#2A132E"
  image: assets/logo/purpleDiamondR.svg
  android: true
  ios: true
  android_12:
    color: "#502989"
    color_dark: "#2A132E"
```

Note: If SVG doesn't work for splash (flutter_native_splash needs PNG), convert the logo SVG to PNG first or use the V1 background approach. If needed, create a simple splash config with just the gradient color:

```yaml
flutter_native_splash:
  color: "#502989"
  android: true
  ios: true
  android_12:
    color: "#502989"
```

**Step 2: Generate splash**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart run flutter_native_splash:create
```

**Step 3: Commit**

```bash
git add flutter_native_splash.yaml android/ ios/
git commit -m "feat: configure purple gradient native splash screen"
```

---

## Phase 5: Error Manager & Crashlytics Integration

### Task 10: Create Error Manager

**Files:**
- Create: `lib/core/error/error_manager.dart`

**Step 1: Create error_manager.dart**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ErrorManager {
  static final _crashlytics = FirebaseCrashlytics.instance;

  static Future<void> init() async {
    // Pass Flutter errors to Crashlytics
    FlutterError.onError = (details) {
      if (kReleaseMode) {
        _crashlytics.recordFlutterFatalError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    // Pass async errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kReleaseMode) {
        _crashlytics.recordError(error, stack, fatal: true);
      } else {
        debugPrint('Async error: $error\n$stack');
      }
      return true;
    };

    // Disable collection in debug mode
    await _crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);
  }

  /// Log non-fatal error
  static void logError(Object error, [StackTrace? stack, String? reason]) {
    if (kReleaseMode) {
      _crashlytics.recordError(error, stack, reason: reason);
    } else {
      debugPrint('Error: $error${reason != null ? ' ($reason)' : ''}');
    }
  }

  /// Set user identifier for crash reports
  static void setUser(String userId) {
    _crashlytics.setUserIdentifier(userId);
  }

  /// Log custom key-value for crash context
  static void setCustomKey(String key, Object value) {
    _crashlytics.setCustomKey(key, value);
  }
}
```

**Step 2: Integrate into main.dart**

Update `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/config/supabase_config.dart';
import 'core/error/error_manager.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ErrorManager.init();
  await initSupabase();

  runApp(const ProviderScope(child: QuloApp()));
}
```

**Step 3: Add error logging to Dio interceptor**

Modify the existing Dio interceptor in `lib/providers/api_provider.dart`. Add to the error interceptor:

```dart
// Inside onError callback of TokenInterceptor or a new ErrorInterceptor:
import '../core/error/error_manager.dart';

// In error handler:
ErrorManager.logError(
  err,
  err.stackTrace,
  'API ${err.requestOptions.method} ${err.requestOptions.path}',
);
```

**Step 4: Set user on login**

In `lib/providers/auth_provider.dart`, after successful login:
```dart
ErrorManager.setUser(userId);
```

**Step 5: Commit**

```bash
git add lib/core/error/error_manager.dart lib/main.dart lib/providers/api_provider.dart lib/providers/auth_provider.dart
git commit -m "feat: add ErrorManager with Crashlytics integration"
```

---

### Task 11: Update AppDelegate for Firebase & Push

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`

**Step 1: Update AppDelegate.swift**

```swift
import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Request notification permissions
    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
```

**Step 2: Update Podfile to set minimum iOS version**

Modify `ios/Podfile` to uncomment/set platform:
```ruby
platform :ios, '13.0'
```

**Step 3: Commit**

```bash
git add ios/Runner/AppDelegate.swift ios/Podfile
git commit -m "feat: configure iOS AppDelegate for Firebase and push notifications"
```

---

## Phase 6: Version & Final Verification

### Task 12: Update pubspec version & verify build

**Files:**
- Verify: `pubspec.yaml` has version `2.0.0+28`

**Step 1: Verify version**

Ensure `pubspec.yaml` line 19 reads: `version: 2.0.0+28`

**Step 2: Add .gitignore entries**

Ensure these are in `.gitignore`:
```
# Keystore (keep key.properties but ignore actual keystore for security)
# Actually, keystore needs to be in repo for CI or stored securely
# For now, keep both tracked

# Firebase generated
lib/firebase_options.dart
```

Actually, do NOT gitignore firebase_options.dart if it's committed. Leave .gitignore as-is.

**Step 3: Run flutter analyze**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze
```

Fix any analysis errors.

**Step 4: Test Android build**

```bash
flutter build apk --debug
```

**Step 5: Test iOS build**

```bash
flutter build ios --debug --no-codesign
```

**Step 6: Final commit**

```bash
git add -A
git commit -m "feat: complete V1 to V2 platform migration (v2.0.0)"
```

---

## Summary

| Task | Description | Phase |
|------|-------------|-------|
| 1 | Android bundle ID, signing config, keystore | Phase 1 |
| 2 | Firebase config files + firebase_options.dart | Phase 1 |
| 3 | Android manifest permissions & FCM metadata | Phase 1 |
| 4 | iOS bundle ID & Info.plist | Phase 2 |
| 5 | iOS localized permission strings + entitlements | Phase 2 |
| 6 | Copy V1 assets (logo, icons, lottie, SVGs, fonts) | Phase 3 |
| 7 | Update pubspec.yaml (assets, fonts, version, splash dep) | Phase 3 |
| 8 | Copy app icons from V1 (Android + iOS) | Phase 3 |
| 9 | Configure native splash screen | Phase 4 |
| 10 | Error Manager with Crashlytics | Phase 5 |
| 11 | iOS AppDelegate for Firebase & push | Phase 5 |
| 12 | Version update & build verification | Phase 6 |
