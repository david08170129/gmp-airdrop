import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var iosNativePicker: IosNativePicker?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerIosNativePicker()
    return launched
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    registerIosNativePicker()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerIosNativePicker() {
    guard iosNativePicker == nil,
          let controller = flutterRootController() else {
      return
    }

    let picker = IosNativePicker(presenter: controller)
    iosNativePicker = picker

    let channel = FlutterMethodChannel(
      name: "gmp_airdrop/ios_picker",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak picker] call, result in
      picker?.handle(call, result: result)
    }
  }

  private func flutterRootController() -> FlutterViewController? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller
    }

    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for sceneWindow in windowScene.windows {
        if let controller = sceneWindow.rootViewController as? FlutterViewController {
          return controller
        }
      }
    }

    return nil
  }
}
