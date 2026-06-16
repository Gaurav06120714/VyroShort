//
//  CaptureStorage.swift
//  VyroShort
//
//  On-disk storage for capture PNGs and thumbnails plus the SwiftData container.
//

import AppKit
import SwiftData

@MainActor
enum CaptureStorage {
    /// ~/Library/Application Support/VyroShort
    static let baseURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("VyroShort", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let capturesURL: URL = {
        let dir = baseURL.appendingPathComponent("Captures", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let thumbnailsURL: URL = {
        let dir = baseURL.appendingPathComponent("Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func fileURL(for name: String) -> URL { capturesURL.appendingPathComponent(name) }
    static func thumbnailURL(for name: String) -> URL { thumbnailsURL.appendingPathComponent(name) }

    /// Writes a full-resolution PNG and a thumbnail, returning their file names.
    @discardableResult
    static func persist(image: NSImage) -> (fileName: String, thumbName: String, size: CGSize)? {
        let uuid = UUID().uuidString
        let fileName = "\(uuid).png"
        let thumbName = "\(uuid)_thumb.png"

        guard let png = image.pngData() else { return nil }
        do {
            try png.write(to: fileURL(for: fileName))
            if let thumb = ThumbnailManager.makeThumbnail(from: image, maxDimension: 320),
               let thumbPNG = thumb.pngData() {
                try thumbPNG.write(to: thumbnailURL(for: thumbName))
            }
        } catch {
            return nil
        }
        return (fileName, thumbName, image.pixelSize)
    }

    static func delete(fileName: String, thumbnailName: String?) {
        try? FileManager.default.removeItem(at: fileURL(for: fileName))
        if let t = thumbnailName {
            try? FileManager.default.removeItem(at: thumbnailURL(for: t))
        }
    }

    // MARK: - SwiftData container

    static let container: ModelContainer = {
        let schema = Schema([ScreenshotItem.self, Tag.self])
        let config = ModelConfiguration(
            schema: schema,
            url: baseURL.appendingPathComponent("VyroShort.store")
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fall back to an in-memory store so the app still runs.
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [mem])
        }
    }()
}

extension NSImage {
    var pixelSize: CGSize {
        guard let rep = representations.first as? NSBitmapImageRep else { return size }
        return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }

    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
