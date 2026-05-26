import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var iosNativePicker: IosNativePicker?
  private var iosShareInboxRegistered = false
  private let appGroupIdentifier = "group.com.aunew.gmpairdrop"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerIosNativePicker()
    registerIosShareInbox()
    return launched
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    registerIosNativePicker()
    registerIosShareInbox()
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

  private func registerIosShareInbox() {
    guard !iosShareInboxRegistered,
          let controller = flutterRootController() else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "gmp_airdrop/ios_share_inbox",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "getSharedInbox":
        result(self.getSharedInbox())
      case "clearSharedInbox":
        let args = call.arguments as? [String: Any]
        let ids = args?["ids"] as? [String] ?? []
        result(self.clearSharedInbox(ids: ids))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    iosShareInboxRegistered = true
  }

  private func getSharedInbox() -> [[String: Any]] {
    let fileManager = FileManager.default
    guard let sharedContainer = fileManager.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier
    ) else {
      return []
    }

    let inboxDirectory = sharedContainer.appendingPathComponent("Inbox", isDirectory: true)
    guard let entries = try? fileManager.contentsOfDirectory(
      at: inboxDirectory,
      includingPropertiesForKeys: [.contentModificationDateKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    var payloads: [[String: Any]] = []
    for url in entries where url.pathExtension.lowercased() == "json" {
      guard let data = try? Data(contentsOf: url),
            var payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
        continue
      }

      let shareId = payload["id"] as? String ?? url.deletingPathExtension().lastPathComponent
      payload["id"] = shareId
      payload["inboxFileName"] = url.lastPathComponent

      if let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
         let modified = values.contentModificationDate {
        payload["metadataModifiedAt"] = ISO8601DateFormatter().string(from: modified)
      }

      if let items = payload["items"] as? [[String: Any]] {
        payload["items"] = items.map { item in
          var enriched = item
          if let path = item["path"] as? String, !path.isEmpty {
            let exists = fileManager.fileExists(atPath: path)
            enriched["exists"] = exists
            if exists,
               let attributes = try? fileManager.attributesOfItem(atPath: path),
               let size = attributes[.size] as? NSNumber {
              enriched["size"] = size.int64Value
            }
          } else {
            enriched["exists"] = false
          }
          return enriched
        }
      }

      payloads.append(payload)
    }

    return payloads.sorted {
      let left = ($0["receivedAt"] as? String) ?? ($0["metadataModifiedAt"] as? String) ?? ""
      let right = ($1["receivedAt"] as? String) ?? ($1["metadataModifiedAt"] as? String) ?? ""
      return left > right
    }
  }

  private func clearSharedInbox(ids: [String]) -> Bool {
    let fileManager = FileManager.default
    guard let sharedContainer = fileManager.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier
    ) else {
      return false
    }

    let inboxDirectory = sharedContainer.appendingPathComponent("Inbox", isDirectory: true)

    let targetIds: [String]
    if ids.isEmpty {
      let entries = (try? fileManager.contentsOfDirectory(
        at: inboxDirectory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )) ?? []
      targetIds = entries
        .filter { $0.pathExtension.lowercased() == "json" }
        .map { $0.deletingPathExtension().lastPathComponent }
    } else {
      targetIds = ids
    }

    var succeeded = true
    for id in targetIds {
      let metadataURL = inboxDirectory.appendingPathComponent("\(id).json")
      if fileManager.fileExists(atPath: metadataURL.path) {
        do {
          try fileManager.removeItem(at: metadataURL)
        } catch {
          succeeded = false
        }
      }
    }

    return succeeded
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
