import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let settingsChannel = FlutterMethodChannel(
      name: "com.liangzhi.app/system_settings",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    settingsChannel.setMethodCallHandler { call, result in
      guard call.method == "openAppSettings" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let url = URL(string: UIApplication.openSettingsURLString) else {
        result(
          FlutterError(
            code: "SETTINGS_UNAVAILABLE",
            message: "System settings URL is unavailable.",
            details: nil
          )
        )
        return
      }
      UIApplication.shared.open(url)
      result(nil)
    }
    let notificationPermissionChannel = FlutterMethodChannel(
      name: "com.liangzhi.app/notification_permission",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    notificationPermissionChannel.setMethodCallHandler { call, result in
      guard call.method == "getPermissionStatus" else {
        result(FlutterMethodNotImplemented)
        return
      }
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        let status: String
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
          status = "granted"
        case .denied:
          status = "permanentlyDenied"
        case .notDetermined:
          status = "notDetermined"
        @unknown default:
          status = "notDetermined"
        }
        DispatchQueue.main.async {
          result(status)
        }
      }
    }
  }
}
