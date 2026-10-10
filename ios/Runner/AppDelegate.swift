import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps
    GMSServices.provideAPIKey("AIzaSyBWDZYMXb8qBFMeCGuqDE2m_D2L6uBjtBQ")

    // Firebase MUST be configured before notification registration
    FirebaseApp.configure()

    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self
    // Bildirim izni burada ISTENMEZ (ilk acilista soguk istem). Izin, ilk
    // eslesme / ilk mesaj aninda aciklama ekranindan sonra Dart tarafinda
    // (NotificationManager.requestPermission) istenir. APNs kaydi izinden
    // bagimsizdir; token izin verilince bildirim gostermeye baslar.
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
