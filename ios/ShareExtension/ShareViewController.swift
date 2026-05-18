import UIKit

final class ShareViewController: UIViewController {
    private let appGroupIdentifier = "group.com.aunew.gmpairdrop"
    private let fileManager = FileManager.default
    private let metadataQueue = DispatchQueue(label: "com.aunew.gmpairdrop.shareextension.metadata")
    private var collectedItems: [[String: Any]] = []

    private let supportedTypeIdentifiers = [
        "com.adobe.pdf",
        "public.image",
        "public.movie",
        "public.text",
        "public.url",
        "public.file-url",
        "public.data",
        "public.item"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        processSharedItems()
    }

    private func configureView() {
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Saving to GMP Airdrop..."
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .headline)

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func processSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem],
              let sharedContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            finish()
            return
        }

        let shareId = UUID().uuidString
        let receivedAt = ISO8601DateFormatter().string(from: Date())
        let shareDirectory = sharedContainer
            .appendingPathComponent("SharedItems", isDirectory: true)
            .appendingPathComponent(shareId, isDirectory: true)

        do {
            try fileManager.createDirectory(at: shareDirectory, withIntermediateDirectories: true)
        } catch {
            finish()
            return
        }

        let group = DispatchGroup()

        for extensionItem in extensionItems {
            for provider in extensionItem.attachments ?? [] {
                if let typeIdentifier = supportedTypeIdentifiers.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, error in
                        defer { group.leave() }
                        guard let self = self, error == nil, let item = item else { return }
                        self.store(item: item, typeIdentifier: typeIdentifier, in: shareDirectory)
                    }
                }
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) { [weak self] in
            self?.writeMetadata(shareId: shareId, receivedAt: receivedAt, sharedContainer: sharedContainer)
            DispatchQueue.main.async {
                self?.finish()
            }
        }
    }

    private func store(item: NSSecureCoding, typeIdentifier: String, in shareDirectory: URL) {
        if let url = item as? URL {
            store(url: url, typeIdentifier: typeIdentifier, in: shareDirectory)
            return
        }

        if let text = item as? String {
            appendMetadata([
                "type": typeIdentifier == "public.url" ? "url" : "text",
                "uti": typeIdentifier,
                "text": text
            ])
            return
        }

        if let image = item as? UIImage, let data = image.pngData() {
            let fileName = uniqueFileName(preferredName: "shared-image.png")
            let destination = shareDirectory.appendingPathComponent(fileName)
            do {
                try data.write(to: destination, options: .atomic)
                appendFileMetadata(type: "image", uti: typeIdentifier, originalName: nil, destination: destination)
            } catch {
                return
            }
            return
        }

        if let data = item as? Data {
            let fileName = uniqueFileName(preferredName: defaultFileName(for: typeIdentifier))
            let destination = shareDirectory.appendingPathComponent(fileName)
            do {
                try data.write(to: destination, options: .atomic)
                appendFileMetadata(type: itemType(for: typeIdentifier), uti: typeIdentifier, originalName: nil, destination: destination)
            } catch {
                return
            }
        }
    }

    private func store(url: URL, typeIdentifier: String, in shareDirectory: URL) {
        if url.isFileURL {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let destination = shareDirectory.appendingPathComponent(uniqueFileName(preferredName: url.lastPathComponent))
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.copyItem(at: url, to: destination)
                appendFileMetadata(type: itemType(for: typeIdentifier, fileURL: url), uti: typeIdentifier, originalName: url.lastPathComponent, destination: destination)
            } catch {
                return
            }
        } else {
            appendMetadata([
                "type": "url",
                "uti": typeIdentifier,
                "url": url.absoluteString
            ])
        }
    }

    private func writeMetadata(shareId: String, receivedAt: String, sharedContainer: URL) {
        let payload: [String: Any] = [
            "id": shareId,
            "receivedAt": receivedAt,
            "items": collectedMetadata()
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]) else {
            return
        }

        let inboxDirectory = sharedContainer.appendingPathComponent("Inbox", isDirectory: true)
        do {
            try fileManager.createDirectory(at: inboxDirectory, withIntermediateDirectories: true)
            try data.write(to: inboxDirectory.appendingPathComponent("\(shareId).json"), options: .atomic)
        } catch {
            return
        }
    }

    private func appendFileMetadata(type: String, uti: String, originalName: String?, destination: URL) {
        var metadata: [String: Any] = [
            "type": type,
            "uti": uti,
            "fileName": destination.lastPathComponent,
            "path": destination.path
        ]

        if let originalName = originalName {
            metadata["originalName"] = originalName
        }

        appendMetadata(metadata)
    }

    private func appendMetadata(_ metadata: [String: Any]) {
        metadataQueue.sync {
            collectedItems.append(metadata)
        }
    }

    private func collectedMetadata() -> [[String: Any]] {
        metadataQueue.sync {
            collectedItems
        }
    }

    private func uniqueFileName(preferredName: String) -> String {
        let safeName = preferredName.isEmpty ? "shared-file" : preferredName
        return "\(UUID().uuidString)-\(safeName)"
    }

    private func defaultFileName(for typeIdentifier: String) -> String {
        switch typeIdentifier {
        case "com.adobe.pdf":
            return "shared-file.pdf"
        case "public.image":
            return "shared-image"
        case "public.movie":
            return "shared-video"
        case "public.text":
            return "shared-text.txt"
        default:
            return "shared-file"
        }
    }

    private func itemType(for typeIdentifier: String, fileURL: URL? = nil) -> String {
        if typeIdentifier == "com.adobe.pdf" || fileURL?.pathExtension.lowercased() == "pdf" {
            return "pdf"
        }
        if typeIdentifier == "public.image" {
            return "image"
        }
        if typeIdentifier == "public.movie" {
            return "video"
        }
        if typeIdentifier == "public.text" {
            return "text"
        }
        if typeIdentifier == "public.url" {
            return "url"
        }
        return "file"
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
