import Flutter
import PhotosUI
import UIKit
import UniformTypeIdentifiers

final class IosNativePicker: NSObject, UIDocumentPickerDelegate {
  private weak var presenter: UIViewController?
  private var pendingResult: FlutterResult?
  private var photoPickerDelegate: AnyObject?
  private var pickerKind = "files"
  private let fileManager = FileManager.default

  init(presenter: UIViewController) {
    self.presenter = presenter
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pickFiles" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard pendingResult == nil else {
      result(FlutterError(
        code: "picker_busy",
        message: "A picker is already open.",
        details: nil
      ))
      return
    }

    let args = call.arguments as? [String: Any]
    pickerKind = args?["kind"] as? String ?? "files"
    pendingResult = result

    switch pickerKind {
    case "photos":
      presentPhotoPicker(kind: "photos")
    case "videos":
      presentPhotoPicker(kind: "videos")
    default:
      presentDocumentPicker()
    }
  }

  @available(iOS 14, *)
  func handlePhotoPickerResults(_ picker: PHPickerViewController, results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard !results.isEmpty else {
      photoPickerDelegate = nil
      finish([])
      return
    }

    let group = DispatchGroup()
    let queue = DispatchQueue(label: "com.aunew.gmpairdrop.iospicker.results")
    var files: [[String: Any]] = []

    for selected in results {
      let provider = selected.itemProvider
      let typeIdentifier = preferredTypeIdentifier(for: provider)

      group.enter()
      provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
        defer { group.leave() }
        guard let self = self, let url = url, error == nil else { return }

        if let copied = self.copyPickedFile(
          from: url,
          suggestedName: provider.suggestedName,
          typeIdentifier: typeIdentifier
        ) {
          queue.sync {
            files.append(copied)
          }
        }
      }
    }

    group.notify(queue: .main) { [weak self] in
      self?.photoPickerDelegate = nil
      self?.finish(files)
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish([])
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    let files = urls.compactMap { url -> [String: Any]? in
      let didAccess = url.startAccessingSecurityScopedResource()
      defer {
        if didAccess {
          url.stopAccessingSecurityScopedResource()
        }
      }

      return copyPickedFile(
        from: url,
        suggestedName: url.lastPathComponent,
        typeIdentifier: nil
      )
    }
    finish(files)
  }

  private func presentPhotoPicker(kind: String) {
    guard #available(iOS 14, *) else {
      finish(FlutterError(
        code: "unsupported_ios",
        message: "Photo library picking requires iOS 14 or later.",
        details: nil
      ))
      return
    }

    var configuration = PHPickerConfiguration(photoLibrary: .shared())
    configuration.filter = kind == "videos" ? .videos : .images
    configuration.selectionLimit = 0
    configuration.preferredAssetRepresentationMode = .current

    let picker = PHPickerViewController(configuration: configuration)
    let delegate = IosPhotoPickerDelegate(owner: self)
    photoPickerDelegate = delegate
    picker.delegate = delegate
    presenter?.present(picker, animated: true)
  }

  private func presentDocumentPicker() {
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [.item],
      asCopy: true
    )
    picker.allowsMultipleSelection = true
    picker.delegate = self
    presenter?.present(picker, animated: true)
  }

  private func preferredTypeIdentifier(for provider: NSItemProvider) -> String {
    if pickerKind == "videos" {
      if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
        return UTType.movie.identifier
      }
      if provider.hasItemConformingToTypeIdentifier(UTType.video.identifier) {
        return UTType.video.identifier
      }
    }

    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      return UTType.image.identifier
    }
    if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
      return UTType.movie.identifier
    }
    if provider.hasItemConformingToTypeIdentifier(UTType.item.identifier) {
      return UTType.item.identifier
    }
    return provider.registeredTypeIdentifiers.first ?? UTType.item.identifier
  }

  private func copyPickedFile(
    from source: URL,
    suggestedName: String?,
    typeIdentifier: String?
  ) -> [String: Any]? {
    do {
      let directory = try pickerDirectory()
      let displayName = displayFileName(
        source: source,
        suggestedName: suggestedName,
        typeIdentifier: typeIdentifier
      )
      let fileName = "\(UUID().uuidString)-\(displayName)"
      let destination = directory.appendingPathComponent(fileName)

      if fileManager.fileExists(atPath: destination.path) {
        try fileManager.removeItem(at: destination)
      }

      try fileManager.copyItem(at: source, to: destination)
      let attributes = try fileManager.attributesOfItem(atPath: destination.path)
      let size = attributes[.size] as? NSNumber

      return [
        "path": destination.path,
        "name": displayName,
        "size": size?.int64Value ?? 0,
        "type": typeIdentifier ?? ""
      ]
    } catch {
      return nil
    }
  }

  private func pickerDirectory() throws -> URL {
    let directory = fileManager.temporaryDirectory
      .appendingPathComponent("GMPAirdropPicker", isDirectory: true)
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private func displayFileName(
    source: URL,
    suggestedName: String?,
    typeIdentifier: String?
  ) -> String {
    let rawName = suggestedName?.isEmpty == false
      ? suggestedName!
      : source.lastPathComponent

    var name = rawName.isEmpty ? "selected-file" : rawName
    if URL(fileURLWithPath: name).pathExtension.isEmpty {
      if let typeIdentifier = typeIdentifier,
         let type = UTType(typeIdentifier),
         let ext = type.preferredFilenameExtension {
        name += ".\(ext)"
      }
    }

    let safeName = name.replacingOccurrences(of: "/", with: "-")
    return safeName
  }

  private func finish(_ value: Any) {
    let result = pendingResult
    pendingResult = nil
    DispatchQueue.main.async {
      result?(value)
    }
  }
}

@available(iOS 14, *)
private final class IosPhotoPickerDelegate: NSObject, PHPickerViewControllerDelegate {
  private weak var owner: IosNativePicker?

  init(owner: IosNativePicker) {
    self.owner = owner
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    owner?.handlePhotoPickerResults(picker, results: results)
  }
}
